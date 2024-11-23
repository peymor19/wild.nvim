local fzy = require('fzy-lua-native')
local cmd = require("cmd")

local WildFzy = {}
WildFzy.__index = WildFzy


function WildFzy.find_matches(needle)
    if cmd.is_help(needle) then
        haystack = cmd.help_tags
        needle = cmd.tail(needle)
    else
        haystack = cmd.commands
    end

    needle = needle:lower()

    -- returns {line, position, score}
    scored_haystack = fzy.filter(needle, haystack, false)

    table.sort(scored_haystack, function(a, b) return a[3] > b[3] end)

    local sorted_lines = {}

    for _, item in pairs(scored_haystack) do
        table.insert(sorted_lines, item[1])
    end

    return sorted_lines
end

return WildFzy
