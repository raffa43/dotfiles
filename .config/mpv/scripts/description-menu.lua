local mp = require "mp"
local utils = require "mp.utils"

local function show_description()
    local metadata = mp.get_property_native("metadata")
    local description

    if type(metadata) == "table" then
        for key, value in pairs(metadata) do
            if type(key) == "string"
                and key:lower() == "description"
                and type(value) == "string" then
                description = value
                break
            end
        end
    end

    local menu = {
        title = "Video description",
        type = "video-description",
        items = {
            {
                title = description or "No description metadata found.",
                selectable = false,
            },
        },
    }

    mp.commandv(
        "script-message-to",
        "uosc",
        "open-menu",
        utils.format_json(menu)
    )
end

mp.register_script_message("show", show_description)
