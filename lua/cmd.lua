local Cmd = {
    commands = {},
    help_tags = {},
    cmd_history = {},
    max_cmd_history = 15
}

function Cmd.get_commands()
    commands = {}

    for _, name in pairs(vim.fn.getcompletion("", "cmdline")) do
        if not string.match(name, "[~!?#&<>@=]") then
            table.insert(commands, name)
        end
    end

    Cmd:from_file()

    commands = Cmd:set_most_recent_at_top(commands)

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

function Cmd.is_valid(input, commands)
    for _, cmd in ipairs(commands) do
        if string.match(cmd, input) and input ~= "" then
            return true
        end
    end

    return false
end

function Cmd.inc_usage(command, cmd_history)
    for _, item in ipairs(cmd_history) do
        if item.cmd == command then
            item.count = item.count + 1
            return cmd_history
        end
    end

    table.insert(cmd_history, {cmd = command, count = 1})

    return cmd_history
end

function Cmd.sort_history(cmd_history)
    table.sort(cmd_history, function(a, b)
        return a.count > b.count
    end)

    return cmd_history
end

function Cmd:set_history()
    local command = vim.fn.getcmdline()

    if Cmd.is_valid(command, self.commands) then
        self.cmd_history = Cmd.inc_usage(command, self.cmd_history)
        self.cmd_history = Cmd.sort_history(self.cmd_history)
    end
end

function Cmd:set_most_recent_at_top(commands)
    for i = math.min(self.max_cmd_history, #self.cmd_history), 1, -1 do
        table.insert(commands, 1, self.cmd_history[i].cmd)
    end

    return commands
end

function Cmd:to_file()
    if #self.cmd_history == 0 then return end

    local file = io.open(vim.fn.stdpath('data') .. '/command_history.json', 'w')
    if file then
        file:write(vim.json.encode(self.cmd_history))
        file:close()
    end
end

function Cmd:from_file()
    local file = io.open(vim.fn.stdpath('data') .. '/command_history.json', 'r')
    if file then
        local data = file:read('*all')
        self.cmd_history = vim.json.decode(data) or {}
        file:close()
    end
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
