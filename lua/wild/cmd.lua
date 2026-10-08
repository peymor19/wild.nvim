local history = require("wild.history")

local M = {}

function M.get_commands(entries, now)
    local commands = {}
    local seen = {}

    for _, entry in ipairs(history.sort(entries, now)) do
        table.insert(commands, entry.line)
        seen[entry.line] = true
    end

    for _, name in ipairs(M.get_vim_commands()) do
        if not seen[name] then
            table.insert(commands, name)
        end
    end

    return commands
end

function M.get_vim_commands()
    local commands = {}

    for _, name in pairs(vim.fn.getcompletion("", "cmdline")) do
        if not string.match(name, "[~!?#&<>@=]") then
            table.insert(commands, name)
        end
    end

    return commands
end

-- Resolves a command line to its full command name, e.g. "e foo.txt" -> "edit".
-- Returns nil when the line is not a valid ex command.
function M.command_name(command_line)
    local ok, parsed = pcall(vim.api.nvim_parse_cmd, command_line, {})

    if not ok then
        return nil
    end

    return parsed.cmd
end

return M
