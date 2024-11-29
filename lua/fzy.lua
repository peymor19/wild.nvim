local fzy = require('fzy-lua-native')
local cmd = require("cmd")

local WildFzy = {}
WildFzy.__index = WildFzy


function WildFzy.find_matches(needle, haystack)
    needle = needle:lower()

    -- returns {line, position, score}
    scored_haystack = fzy.filter(needle, haystack, false)

    table.sort(scored_haystack, function(a, b) return a[3] > b[3] end)

    return scored_haystack
end

return WildFzy
