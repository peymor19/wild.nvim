local M = {}

function M.get_help_tags()
    local help_tags = {}

    for _, file in ipairs(vim.api.nvim_get_runtime_file("doc/tags", true)) do
        for _, line in ipairs(vim.fn.readfile(file)) do
            if not line:match("^!_TAG_") then
                table.insert(help_tags, line:match("^[^\t]+"))
            end
        end
    end

    return help_tags
end

---@class wild.CompletionContext
---@field type string
---@field prefix string
---@field needle string
---@field query string

---@param line string
---@param pattern string
---@param type string
---@return wild.CompletionContext?
function M.completion_context(line, pattern, type)
    if type == "" or not line:find("%s") or not vim.endswith(line, pattern) then
        return nil
    end

    local prefix = line:sub(1, #line - #pattern)

    if type == "lua" then
        local stem = pattern:match("^(.*%.)") or ""
        return { type = type, prefix = prefix .. stem, needle = pattern:sub(#stem + 1), query = prefix .. stem }
    end

    local stem = pattern:match("^(.*/)") or ""
    return { type = type, prefix = prefix, needle = pattern, query = prefix .. stem }
end

function M.get_arguments(prefix, candidates, entries)
    local arguments = {}
    local seen = {}

    local function add(argument)
        if argument ~= "" and not seen[argument] then
            seen[argument] = true
            table.insert(arguments, argument)
        end
    end

    for _, entry in ipairs(entries) do
        if vim.startswith(entry.line, prefix) then
            add(entry.line:sub(#prefix + 1))
        end
    end

    for _, candidate in ipairs(candidates) do
        add(candidate)
    end

    return arguments
end

return M
