local fzy = require("fzy-lua-native")

local M = {}

function M.find_matches(needle, haystack)
    needle = needle:lower()

    local order = {}
    for i, item in ipairs(haystack) do
        order[item] = order[item] or i
    end

    -- returns {line, position, score}
    local scored_haystack = fzy.filter(needle, haystack, false)

    table.sort(scored_haystack, function(a, b)
        if a[3] ~= b[3] then
            return a[3] > b[3]
        end

        return order[a[1]] < order[b[1]]
    end)

    return scored_haystack
end

return M
