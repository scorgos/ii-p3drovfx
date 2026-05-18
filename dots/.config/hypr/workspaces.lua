-- nwg-displays & Quickshell support
-- Parse the legacy workspaces.conf file and apply settings synchronously

local home_dir = HOME or os.getenv("HOME")
local file = io.open(home_dir .. "/.config/hypr/workspaces.conf", "r")

if file then
    for line in file:lines() do
        -- Trim leading and trailing whitespace
        line = line:gsub("^%s*(.-)%s*$", "%1")
        
        -- Ignore comments and empty lines
        if not line:match("^#") and line ~= "" then
            -- Match: workspace = name, options
            local name, options = line:match("^workspace%s*=%s*([^,]+)%s*,%s*(.+)$")
            if name and options then
                name = name:gsub("^%s*(.-)%s*$", "%1")
                options = options:gsub("^%s*(.-)%s*$", "%1")
                
                -- Check for native workspace rule config function (Hyprland 0.55+)
                if hl.workspace_rule then
                    local rule_table = { workspace = name }
                    for opt in string.gmatch(options, "[^,]+") do
                        local k, v = opt:match("^%s*([^:]+)%s*:%s*(.+)%s*$")
                        if k and v then
                            k = k:gsub("^%s*(.-)%s*$", "%1")
                            v = v:gsub("^%s*(.-)%s*$", "%1")
                            if v == "true" then v = true
                            elseif v == "false" then v = false
                            end
                            rule_table[k] = v
                        end
                    end
                    hl.workspace_rule(rule_table)
                elseif hl.workspace then
                    hl.workspace({
                        workspace = name,
                        options = options
                    })
                else
                    hl.config({
                        workspace = name .. "," .. options
                    })
                end
            end
        end
    end
    file:close()
end
