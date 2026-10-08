--[[
mpv-gallery-view | https://github.com/occivink/mpv-gallery-view

This mpv script implements a worker for generating gallery thumbnails.
It is meant to be used by other scripts.
Multiple copies of this script can be loaded by mpv.

File placement: inside scripts directory
Settings: script-opts/gallery_worker.conf
Supported options in gallery_worker.conf:
  ytdl_path: path to yt-dlp executable (default: auto-detected)
  timeout: network connection & request timeout in seconds (default: 15)
  retries: max retries for metadata extraction and image downloads (default: 3)
  request_delay: pacing delay in seconds between network requests per worker (default: 0.5)
  user_agent: HTTP User-Agent string for requests
  ytdl_exclude: pipe-separated pattern list of URLs to ignore
]]

local utils = require 'mp.utils'
local msg = require 'mp.msg'

local jobs_queue = {} -- queue of thumbnail jobs
local failed = {} -- list of failed output paths, to avoid redoing them
local script_id = mp.get_script_name() .. utils.getpid()

-- Seed RNG with pid and time so each worker has distinct retry jitter
math.randomseed(os.time() + (utils.getpid() or 0))

local opts = {
    ytdl_exclude = "",
    ytdl_path = "",
    timeout = 15,
    retries = 3,
    request_delay = 0.5,
    user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
}
(require 'mp.options').read_options(opts, "gallery_worker")

local function file_exists(path)
    if not path or path == "" then return false end
    local info = utils.file_info(path)
    return info ~= nil and info.is_file
end

-- Resolve binary paths with fallback candidates (especially for macOS paths)
local function find_binary(name, preferred_path)
    if preferred_path and preferred_path ~= "" then
        if file_exists(preferred_path) then return preferred_path end
    end
    local home = os.getenv("HOME") or ""
    local candidates = {
        "/opt/local/bin/" .. name,
        "/opt/homebrew/bin/" .. name,
        "/usr/local/bin/" .. name,
        "/usr/bin/" .. name,
        home .. "/.local/bin/" .. name,
        name
    }
    for _, candidate in ipairs(candidates) do
        if candidate:find("^/") then
            if file_exists(candidate) then return candidate end
        else
            local check = utils.subprocess({ args = { "which", candidate }, cancellable = true })
            if check.status == 0 and check.stdout and check.stdout ~= "" then
                local path = check.stdout:gsub("%s+$", "")
                if file_exists(path) then return path end
            end
        end
    end
    return name
end

local function find_ytdl_binary()
    if opts.ytdl_path and opts.ytdl_path ~= "" then
        if file_exists(opts.ytdl_path) then return opts.ytdl_path end
    end
    local names = { "yt-dlp", "youtube-dl" }
    for _, name in ipairs(names) do
        local cfg = mp.find_config_file(name)
        if cfg and file_exists(cfg) then return cfg end
    end
    for _, name in ipairs(names) do
        local found = find_binary(name)
        if found:find("^/") and file_exists(found) then
            return found
        end
    end
    if file_exists("/opt/local/bin/yt-dlp") then return "/opt/local/bin/yt-dlp" end
    if file_exists("/usr/local/bin/yt-dlp") then return "/usr/local/bin/yt-dlp" end
    if file_exists("/opt/homebrew/bin/yt-dlp") then return "/opt/homebrew/bin/yt-dlp" end
    return "yt-dlp"
end

local binaries = {
    ffmpeg = find_binary("ffmpeg"),
    ffprobe = find_binary("ffprobe"),
    curl = find_binary("curl", "/usr/bin/curl"),
    mpv = find_binary("mpv"),
    ytdl = find_ytdl_binary()
}

local ytdl = {
    blacklisted = {}
}

function append_table(lhs, rhs)
    for i = 1, #rhs do
        lhs[#lhs+1] = rhs[i]
    end
    return lhs
end

local video_extensions = {
    mkv = true, webm = true, mp4 = true, avi = true, wmv = true,
    mov = true, flv = true, m4v = true, ts = true, m2ts = true,
    vob = true, ogv = true, ["3gp"] = true
}

function is_video(input_path)
    local clean_path = input_path:match("^([^?#]+)") or input_path
    local extension = string.match(clean_path, "%.([^.]+)$")
    if extension then
        return video_extensions[string.lower(extension)] == true
    end
    return false
end

local image_extensions = {
    jpg = true, jpeg = true, png = true, webp = true,
    gif = true, avif = true, bmp = true, tiff = true, svg = true
}

local function is_image_url(url)
    local clean_path = url:match("^([^?#]+)") or url
    local extension = string.match(clean_path, "%.([^.]+)$")
    if extension then
        return image_extensions[string.lower(extension)] == true
    end
    return false
end

function is_blacklisted(url)
    if not opts.ytdl_exclude or opts.ytdl_exclude == "" then return false end
    if #ytdl.blacklisted == 0 then
        local joined = opts.ytdl_exclude
        while joined:match('%|?[^|]+') do
            local _, e, substring = joined:find('%|?([^|]+)')
            table.insert(ytdl.blacklisted, substring)
            joined = joined:sub(e+1)
        end
    end
    if #ytdl.blacklisted > 0 then
        local stripped_url = url:match('https?://(.+)') or url
        for _, exclude in ipairs(ytdl.blacklisted) do
            if stripped_url:match(exclude) then
                msg.verbose('URL matches excluded substring. Skipping: ' .. url)
                return true
            end
        end
    end
    return false
end

-- Forward declaration of handle_events for cooperative waiting
local handle_events

local function wait_seconds(seconds)
    if seconds <= 0 then return true end
    local deadline = mp.get_time() + seconds
    while true do
        local remaining = deadline - mp.get_time()
        if remaining <= 0 then break end
        if not handle_events(remaining) then
            return false -- mpv shutdown
        end
    end
    return true
end

local last_request_time = 0

local function pace_request()
    if opts.request_delay <= 0 then return true end
    local now = mp.get_time()
    local elapsed = now - last_request_time
    if elapsed < opts.request_delay then
        local to_wait = opts.request_delay - elapsed
        if not wait_seconds(to_wait) then
            return false
        end
    end
    last_request_time = mp.get_time()
    return true
end

local function sleep_backoff(attempt)
    local base = opts.request_delay > 0 and opts.request_delay or 0.5
    local factor = 2 ^ (attempt - 1)
    local jitter = math.random() * 0.5
    local backoff = (base * factor) + jitter
    return wait_seconds(backoff)
end

local function extract_youtube_id(url)
    return string.match(url, "https?://youtu%.be/([%a%d%-_]+)")
        or string.match(url, "https?://w?w?w?%.?youtube%.com/v/([%a%d%-_]+)")
        or string.match(url, "https?://w?w?w?%.?youtube%.com/watch%?.-v=([%a%d%-_]+)")
        or string.match(url, "https?://w?w?w?%.?youtube%.com/embed/([%a%d%-_]+)")
        or string.match(url, "https?://w?w?w?%.?youtube%.com/shorts/([%a%d%-_]+)")
        or string.match(url, "https?://w?w?w?%.?youtube%.com/live/([%a%d%-_]+)")
end

local function select_best_thumbnail(json)
    if not json then return nil end
    local best_url = nil
    if type(json.thumbnails) == "table" and #json.thumbnails > 0 then
        local best_score = -1
        for _, t in ipairs(json.thumbnails) do
            if type(t) == "table" and t.url and t.url ~= "" then
                local pref = t.preference or 0
                local w = t.width or 0
                local h = t.height or 0
                local score = pref * 10000000 + (w * h)
                if score > best_score then
                    best_score = score
                    best_url = t.url
                end
            end
        end
    end
    if (not best_url or best_url == "") and type(json.thumbnail) == "string" and json.thumbnail ~= "" then
        best_url = json.thumbnail
    end
    if best_url and best_url:find("^//") then
        best_url = "https:" .. best_url
    end
    return best_url
end

local function ytdl_thumbnail_url(input_path)
    if not pace_request() then return nil end

    for attempt = 1, opts.retries do
        if attempt > 1 then
            msg.verbose(string.format("Retrying yt-dlp metadata (%d/%d): %s", attempt, opts.retries, input_path))
            if not sleep_backoff(attempt - 1) then
                return nil
            end
            if not pace_request() then return nil end
        end

        local command = {
            binaries.ytdl,
            "--no-warnings",
            "--no-playlist",
            "--dump-json",
            "--socket-timeout", tostring(opts.timeout),
            "--retries", tostring(opts.retries),
            "--extractor-retries", tostring(opts.retries),
            "--user-agent", opts.user_agent,
            input_path
        }

        local res = utils.subprocess({ args = command, cancellable = true })
        if res.status < 0 then
            msg.verbose("yt-dlp subprocess killed or failed to start (status " .. tostring(res.status) .. "). Aborting.")
            return nil
        end
        if res.status == 0 and res.stdout and res.stdout ~= "" then
            local json, err = utils.parse_json(res.stdout)
            if json then
                local thumb_url = select_best_thumbnail(json)
                if thumb_url and thumb_url ~= "" then
                    return thumb_url
                else
                    msg.warn("No thumbnail URL found in yt-dlp metadata for " .. input_path)
                end
            else
                msg.warn("Failed to parse yt-dlp JSON: " .. tostring(err))
            end
        else
            msg.warn(string.format("yt-dlp metadata failed (attempt %d/%d) for %s: %s",
                attempt, opts.retries, input_path, res.stderr or ("status " .. tostring(res.status))))
        end
    end

    return nil
end

local function download_image(url, dest_path)
    if not pace_request() then return false end

    for attempt = 1, opts.retries do
        if attempt > 1 then
            msg.verbose(string.format("Retrying image download (%d/%d): %s", attempt, opts.retries, url))
            if not sleep_backoff(attempt - 1) then
                return false
            end
            if not pace_request() then return false end
        end

        os.remove(dest_path)

        local args = {
            binaries.curl,
            "-s", "-S",
            "-L",
            "--fail",
            "--connect-timeout", tostring(opts.timeout),
            "--max-time", tostring(opts.timeout * 2),
            "-A", opts.user_agent,
            "-o", dest_path,
            url
        }

        local res = utils.subprocess({ args = args, cancellable = true })
        if res.status < 0 then
            msg.verbose("Image download subprocess killed or failed to start (status " .. tostring(res.status) .. "). Aborting.")
            os.remove(dest_path)
            return false
        end
        if res.status == 0 then
            local info = utils.file_info(dest_path)
            if info and info.is_file and info.size > 0 then
                return true
            end
        else
            msg.warn(string.format("Image download failed (attempt %d/%d) for %s: %s",
                attempt, opts.retries, url, res.stderr or ("status " .. tostring(res.status))))
        end
    end

    os.remove(dest_path)
    return false
end

function thumbnail_command(input_path, width, height, take_thumbnail_at, output_path, accurate, with_mpv)
    local vf = string.format("%s,%s",
        string.format("scale=iw*min(1\\,min(%d/iw\\,%d/ih)):-2", width, height),
        string.format("pad=%d:%d:(%d-iw)/2:(%d-ih)/2:color=0x00000000", width, height, width, height)
    )
    local out = {}
    local add = function(tbl) out = append_table(out, tbl) end

    if input_path:find("^archive://") or input_path:find("^edl://") then
        with_mpv = true
    end

    if not with_mpv then
        out = { binaries.ffmpeg }
        if is_video(input_path) then
            if string.sub(take_thumbnail_at, -1) == "%" then
                local res = utils.subprocess({ args = {
                    binaries.ffprobe, "-v", "error",
                    "-show_entries", "format=duration", "-of",
                    "default=noprint_wrappers=1:nokey=1", input_path
                }, cancellable = true })
                if res.status == 0 then
                    local duration = tonumber(string.match(res.stdout, "^%s*(.-)%s*$"))
                    if duration then
                        local percent = tonumber(string.sub(take_thumbnail_at, 1, -2))
                        local start = tostring(duration * percent / 100)
                        add({ "-ss", start })
                    end
                end
            else
                add({ "-ss", take_thumbnail_at })
            end
        end
        if not accurate then
            add({ "-noaccurate_seek" })
        end
        if input_path:find("^https?://") then
            add({
                "-headers", "User-Agent: " .. opts.user_agent .. "\r\n",
                "-rw_timeout", tostring(opts.timeout * 1000000)
            })
        end
        add({
            "-i", input_path,
            "-vf", vf,
            "-map", "v:0",
            "-f", "rawvideo",
            "-pix_fmt", "bgra",
            "-c:v", "rawvideo",
            "-frames:v", "1",
            "-y", "-loglevel", "quiet",
            output_path
        })
    else
        out = { binaries.mpv, input_path }
        if take_thumbnail_at ~= "0" and is_video(input_path) then
            if not accurate then
                add({ "--hr-seek=no" })
            end
            add({ "--start=" .. take_thumbnail_at })
        end
        add({
            "--no-config", "--msg-level=all=no",
            "--vf=lavfi=[" .. vf .. ",format=bgra]",
            "--audio=no",
            "--sub=no",
            "--frames=1",
            "--image-display-duration=0",
            "--of=rawvideo", "--ovc=rawvideo",
            "--o=" .. output_path
        })
    end
    return out
end

function generate_thumbnail(thumbnail_job)
    if file_exists(thumbnail_job.output_path) then return true end

    local dir, _ = utils.split_path(thumbnail_job.output_path)
    local tmp_output_path = utils.join_path(dir, script_id)
    local input_path = thumbnail_job.input_path
    local is_network = input_path:find("^https?://") ~= nil
    local downloaded_tmp_file = nil

    if is_network then
        if is_blacklisted(input_path) then
            return false
        end

        local thumb_img_url = nil

        -- 1. Direct image link
        if is_image_url(input_path) then
            thumb_img_url = input_path
        else
            -- 2. YouTube heuristic check
            local ytid = extract_youtube_id(input_path)
            if ytid then
                local candidate = "https://i.ytimg.com/vi/" .. ytid .. "/hqdefault.jpg"
                local candidate_tmp = tmp_output_path .. ".img"
                if download_image(candidate, candidate_tmp) then
                    downloaded_tmp_file = candidate_tmp
                end
            end

            -- 3. If not YouTube or direct YouTube download failed, extract with yt-dlp
            if not downloaded_tmp_file then
                thumb_img_url = ytdl_thumbnail_url(input_path)
            end
        end

        -- Download image from extracted URL
        if thumb_img_url and not downloaded_tmp_file then
            local candidate_tmp = tmp_output_path .. ".img"
            if download_image(thumb_img_url, candidate_tmp) then
                downloaded_tmp_file = candidate_tmp
            end
        end

        if downloaded_tmp_file then
            input_path = downloaded_tmp_file
        else
            -- Direct image URL failed to download, abort
            if is_image_url(input_path) then
                return false
            end
            -- If video URL and no thumbnail could be downloaded, let ffmpeg attempt direct stream seek as fallback
        end
    end

    local command = thumbnail_command(
        input_path,
        thumbnail_job.width,
        thumbnail_job.height,
        thumbnail_job.take_thumbnail_at,
        tmp_output_path,
        thumbnail_job.accurate,
        thumbnail_job.with_mpv
    )

    local res = utils.subprocess({ args = command, cancellable = true })
    if res.status < 0 then
        msg.verbose("Thumbnail generation subprocess killed or failed to start (status " .. tostring(res.status) .. "). Aborting.")
        if downloaded_tmp_file then os.remove(downloaded_tmp_file) end
        if file_exists(tmp_output_path) then os.remove(tmp_output_path) end
        return false
    end

    if downloaded_tmp_file then
        os.remove(downloaded_tmp_file)
    end

    --"atomically" generate the output to avoid loading half-generated thumbnails (results in crashes)
    if res.status == 0 then
        local info = utils.file_info(tmp_output_path)
        if not info or not info.is_file or info.size == 0 then
            if file_exists(tmp_output_path) then os.remove(tmp_output_path) end
            return false
        end
        if os.rename(tmp_output_path, thumbnail_job.output_path) then
            return true
        end
    end

    if file_exists(tmp_output_path) then
        os.remove(tmp_output_path)
    end
    return false
end

handle_events = function(wait)
    local e = mp.wait_event(wait)
    while e.event ~= "none" do
        if e.event == "shutdown" then
            return false
        elseif e.event == "client-message" then
            if e.args[1] == "push-thumbnail-front" or e.args[1] == "push-thumbnail-back" then
                local thumbnail_job = {
                    requester = e.args[2],
                    input_path = e.args[3],
                    width = tonumber(e.args[4]),
                    height = tonumber(e.args[5]),
                    take_thumbnail_at = e.args[6],
                    output_path = e.args[7],
                    accurate = (e.args[8] == "true"),
                    with_mpv = (e.args[9] == "true"),
                }
                if e.args[1] == "push-thumbnail-front" then
                    jobs_queue[#jobs_queue + 1] = thumbnail_job
                else
                    table.insert(jobs_queue, 1, thumbnail_job)
                end
            end
        end
        e = mp.wait_event(0)
    end
    return true
end

local registration_timeout = 5 -- seconds
local registration_period = 1

function mp_event_loop()
    local start_time = mp.get_time()
    local sleep_time = registration_period
    local last_broadcast_time = -registration_period
    local broadcast_func
    broadcast_func = function()
        local now = mp.get_time()
        if now >= start_time + registration_timeout then
            mp.commandv("script-message", "thumbnails-generator-broadcast", mp.get_script_name())
            sleep_time = 1e20
            broadcast_func = function() end
        elseif now >= last_broadcast_time + registration_period then
            mp.commandv("script-message", "thumbnails-generator-broadcast", mp.get_script_name())
            last_broadcast_time = now
        end
    end

    while true do
        if not handle_events(sleep_time) then return end
        broadcast_func()
        while #jobs_queue > 0 do
            local thumbnail_job = jobs_queue[#jobs_queue]
            if not failed[thumbnail_job.output_path] then
                local success = generate_thumbnail(thumbnail_job)
                -- Process pending events (specifically 'shutdown') before sending IPC messages
                if not handle_events(0) then return end
                if success then
                    mp.commandv("script-message-to", thumbnail_job.requester, "thumbnail-generated", thumbnail_job.output_path)
                else
                    failed[thumbnail_job.output_path] = true
                end
            end
            jobs_queue[#jobs_queue] = nil
            if not handle_events(0) then return end
            broadcast_func()
        end
    end
end
