-- auto_pip_corner.lua
-- Enforces fullscreen on load. Snaps window to bottom-left corner when losing focus 
-- or exiting fullscreen, and restores geometry when focused without enforcing fullscreen.

local mp = require 'mp'

local TARGET_MAX_W = 1280
local TARGET_MAX_H = 720

local saved_geometry = nil
local is_snapped = false
local updating = false
local is_loading = false

mp.register_event("start-file", function()
    is_loading = true
end)

mp.register_event("file-loaded", function()
    -- Force fullscreen strictly on file load
    mp.set_property_bool("fullscreen", true)
    
    mp.add_timeout(1.0, function()
        is_loading = false
    end)
end)

local function calculate_bottom_left_geometry()
    local dwidth = mp.get_property_number("dwidth")
    local dheight = mp.get_property_number("dheight")

    if not dwidth or not dheight or dwidth == 0 or dheight == 0 then
        return string.format("%dx%d+0-0", TARGET_MAX_W, TARGET_MAX_H)
    end

    local aspect = dwidth / dheight
    local target_aspect = TARGET_MAX_W / TARGET_MAX_H

    local w, h
    if aspect >= target_aspect then
        w = TARGET_MAX_W
        h = math.max(100, math.floor(TARGET_MAX_W / aspect))
    else
        h = TARGET_MAX_H
        w = math.max(100, math.floor(TARGET_MAX_H * aspect))
    end

    return string.format("%dx%d+0-0", w, h)
end

local function snap_to_bottom_left()
    if updating or is_loading then return end
    updating = true

    local is_fs = mp.get_property_bool("fullscreen", false)

    -- Save current windowed geometry if not yet snapped
    if not is_snapped and not is_fs then
        local curr_geom = mp.get_property("geometry")
        if curr_geom and curr_geom ~= "" then
            saved_geometry = curr_geom
        end
    end

    local geom = calculate_bottom_left_geometry()
    
    if is_fs then
        mp.set_property_bool("fullscreen", false)
        mp.set_property_bool("window-maximized", false)
        
        -- Delay geometry application to allow macOS Spaces transition to finish.
        -- Bypasses Cocoa's window bounds lock during the animation.
        mp.add_timeout(0.6, function()
            mp.set_property_bool("window-maximized", false)
            mp.set_property("geometry", geom)
            is_snapped = true
            updating = false
        end)
    else
        mp.set_property_bool("window-maximized", false)
        mp.set_property("geometry", geom)
        is_snapped = true
        updating = false
    end
end

local function restore_geometry()
    if updating or not is_snapped then return end
    updating = true

    if saved_geometry and saved_geometry ~= "" then
        mp.set_property("geometry", saved_geometry)
    else
        -- Fallback to centered if no valid previous geometry exists
        mp.set_property("geometry", "50%:50%")
    end
    
    is_snapped = false
    updating = false
end

local has_gained_focus = false

local function on_focus_change(name, focused)
    if focused == nil or is_loading then return end
    if focused == true then
        has_gained_focus = true
        restore_geometry()
    elseif focused == false then
        if not has_gained_focus then return end
        snap_to_bottom_left()
    end
end

local function on_fullscreen_change(name, is_fullscreen)
    if is_fullscreen == nil or updating or is_loading then return end
    if not is_fullscreen then
        snap_to_bottom_left()
    else
        is_snapped = false
    end
end

mp.observe_property("focused", "bool", on_focus_change)
mp.observe_property("fullscreen", "bool", on_fullscreen_change)
