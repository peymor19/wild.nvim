local M = {}

M.history_path = vim.fn.stdpath("data") .. "/command_history.json"

function M.get_searchables(commands_from_file)
    local vim_commands = M.get_vim_commands()

    local command_usage = {}
    for _, item in ipairs(commands_from_file) do
        command_usage[item.cmd] = item.count
    end

    local commands_with_count = {}
    for _, cmd in ipairs(vim_commands) do
        table.insert(commands_with_count, {
            cmd = cmd,
            count = command_usage[cmd] or 0,
        })
    end

    local commands = M.sort_by_usage(commands_with_count)

    local help_tags = M.get_help_tags()
    return { commands = commands, help_tags = help_tags }
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

function M.inc_command(command, commands)
    for _, item in ipairs(commands) do
        if item.cmd == command then
            item.count = item.count + 1
            return M.sort_by_usage(commands)
        end
    end

    return commands
end

function M.sort_by_usage(commands)
    table.sort(commands, function(a, b)
        return a.count > b.count
    end)

    return commands
end

function M.to_file(file_path, commands)
    if #commands == 0 then
        return
    end

    local used = vim.tbl_filter(function(item)
        return item.count > 0
    end, commands)

    vim.fn.mkdir(vim.fs.dirname(file_path), "p")

    local file = io.open(file_path, "w")
    if file then
        file:write(vim.json.encode(used))
        file:close()
    end
end

function M.from_file(file_path)
    local file = io.open(file_path, "r")
    local data = ""

    if file then
        data = file:read("*all")
        file:close()
    end

    local ok, commands = pcall(vim.json.decode, data)

    if not ok then
        return {}
    end

    return commands
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
