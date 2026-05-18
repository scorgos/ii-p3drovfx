-- nwg-displays & Quickshell SystemDisplay support
-- Parse the legacy monitors.conf file and apply setting synchronously

-- hl.exec_cmd("notify-send 'Hyprland monitors.lua' 'Started execution' -a 'Hyprland'")

local home_dir = HOME or os.getenv("HOME")
local file = io.open(home_dir .. "/.config/hypr/monitors.conf", "r")

if file then
    for line in file:lines() do
        -- Trim leading and trailing whitespace
        line = line:gsub("^%s*(.-)%s*$", "%1")
        
        -- Ignore comments and empty lines
        if not line:match("^#") and line ~= "" then
            -- Match: monitor = output, disable
            local match_disable = line:match("^monitor%s*=%s*([^,]-)%s*,%s*disable%s*$")
            if match_disable then
                hl.monitor({
                    output = match_disable,
                    mode = "disabled"
                })
            else
                -- Match: monitor = output, mode, position, scale
                local output, mode, position, scale = line:match("^monitor%s*=%s*([^,]-)%s*,%s*([^,]+)%s*,%s*([^,]+)%s*,%s*([^,]+)")
                if output and mode and position and scale then
                    output = output:gsub("^%s*(.-)%s*$", "%1")
                    mode = mode:gsub("^%s*(.-)%s*$", "%1")
                    position = position:gsub("^%s*(.-)%s*$", "%1")
                    scale = scale:gsub("^%s*(.-)%s*$", "%1")
                    
-- hl.exec_cmd("notify-send 'Hyprland monitors.lua' 'Found monitor " .. output .. " scale " .. scale .. "' -a 'Hyprland'")
                    
                    hl.monitor({
                        output = output,
                        mode = mode,
                        position = position,
                        scale = scale
                    })
                end
            end
        end
    end
    file:close()
end
