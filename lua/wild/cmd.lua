local history = require("wild.history")

local M = {}

function M.get_searchables(entries, now)
    return { commands = M.get_commands(entries, now), help_tags = M.get_help_tags() }
end

function M.get_commands(entries, now)
    local commands = {}
    local seen = {}

    for _, entry in ipairs(history.sort(entries, now)) do
        table.insert(commands, { cmd = entry.line })
        seen[entry.line] = true
    end

    for _, name in ipairs(M.get_vim_commands()) do
        if not seen[name] then
            table.insert(commands, { cmd = name })
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

function M.get_help_tags()
    local help_tags = {}

    for _, file in ipairs(vim.api.nvim_get_runtime_file("doc/tags", true)) do
        for _, line in ipairs(vim.fn.readfile(file)) do
            if not line:match("^!_TAG_") then
                table.insert(help_tags, { cmd = line:match("^[^\t]+") })
            end
        end
    end

    return help_tags
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

function M.is_help(input)
    local name = input:match("^(%a+) ")
    return name ~= nil and vim.startswith("help", name)
end

function M.searchable_type_from_input(input)
    if M.is_help(input) then
        return M.tail(input), "help_tags", "help "
    end

    return input, "commands", ""
end

function M.tail(command)
    local space_pos = command:find(" ")

    if space_pos then
        return command:sub(space_pos + 1)
    else
        return ""
    end
end

return M
