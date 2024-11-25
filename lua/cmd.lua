local Cmd = {
    help_tags = {}
}

function Cmd.get_searchables()
    vim_commands = Cmd.get_vim_commands()
    most_used_commands = Cmd.from_file()

    local command_usage = {}
    for _, item in ipairs(most_used_commands) do
        command_usage[item.cmd] = item.count
    end

    local commands_with_count = {}
    for _, cmd in ipairs(vim_commands) do
        table.insert(commands_with_count, {
            cmd = cmd,
            count = command_usage[cmd] or 0
        })
    end

    commands = Cmd.sort_by_usage(commands_with_count)
    return { commands = commands }
end

function Cmd.get_vim_commands()
    commands = {}

    for _, name in pairs(vim.fn.getcompletion("", "cmdline")) do
        if not string.match(name, "[~!?#&<>@=]") then
            table.insert(commands, name)
        end
    end

    return commands
end

function Cmd:get_help_tags()
  local runtimepath = vim.o.runtimepath
  local paths = vim.split(runtimepath, ',')

    for _, path in ipairs(paths) do
        local doc_path = path .. '/doc'

        if vim.fn.isdirectory(doc_path) then
            local files = vim.fn.globpath(doc_path, 'tags', false, true)

            for _, file in ipairs(files) do
                local lines = vim.fn.readfile(file)

                for _, line in ipairs(lines) do
                    if not line:match "^!_TAG_" then
                        local fields = vim.split(line, "\t", { trimempty = true })
                        table.insert(self.help_tags, fields[1])
                    end
                end
            end
        end
    end
end

function Cmd.in_list(input, commands)
    for _, item in ipairs(commands) do
        if string.match(item.cmd, input) and input ~= "" then
            return true
        end
    end

    return false
end

function Cmd.inc_command(command, commands)
    if not Cmd.in_list(command, commands) then return commands end

    for _, item in ipairs(commands) do
        if item.cmd == command then
            item.count = item.count + 1
            commands = Cmd.sort_by_usage(commands)
            return commands
        end
    end

    table.insert(commands, {cmd = command, count = 1})

    commands = Cmd.sort_by_usage(commands)

    return commands
end

function Cmd.sort_by_usage(commands)
    table.sort(commands, function(a, b)
        return a.count > b.count
    end)

    return commands
end

function Cmd.to_file(commands)
    if #commands == 0 then return end

    local file = io.open(vim.fn.stdpath('data') .. '/command_history.json', 'w')
    if file then
        file:write(vim.json.encode(commands))
        file:close()
    end
end

function Cmd.from_file()
    local file = io.open(vim.fn.stdpath('data') .. '/command_history.json', 'r')
    local data = ""

    if file then
        data = file:read('*all')
        file:close()
    end

    local ok, commands = pcall(vim.json.decode, data)

    if not ok then
        return {}
    end

    return commands
end

function Cmd.is_help(input)
    local valid_prefixes = { "h ", "he ", "hel ", "help " }

    for _, prefix in ipairs(valid_prefixes) do
        if string.sub(input, 1, #prefix) == prefix then
            return true
        end
    end

    return false
end

function Cmd.tail(command)
  local space_pos = command:find(" ")

  if space_pos then
    return command:sub(space_pos + 1)
  else
    return ""
  end
end

return Cmd
