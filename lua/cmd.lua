local Cmd = {
    commands = {},
    help_tags = {},
    cmd_history = {},
    max_cmd_history = 15
}

function Cmd:get_commands()
    for _, name in pairs(vim.fn.getcompletion("", "cmdline")) do
        if not string.match(name, "[~!?#&<>@=]") then
            table.insert(self.commands, name)
        end
    end
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

function Cmd:match(input)
    for _, cmd in ipairs(self.commands) do
        if string.match(cmd, input) and input ~= "" then
            return input
        end
    end

    return nil
end

function Cmd:sort_history()
    local sorted= {}

    for cmd, count in pairs(self.cmd_history) do
        table.insert(sorted, {cmd = cmd, count = count})
    end

    table.sort(sorted, function(a, b)
        return a.count > b.count
    end)

    local pruned= {}
    for i = 1, math.min(#sorted, self.max_cmd_history) do
        pruned[sorted[i].cmd] = sorted[i].count
    end

    self.cmd_history = pruned
end

function Cmd:set_history()
    local command = vim.fn.getcmdline()

    if not Cmd:match(command) then return end

    if self.cmd_history[command] then
        self.cmd_history[command] = self.cmd_history[command] + 1
    else
        self.cmd_history[command] = 1
    end

    Cmd:sort_history()
end

function Cmd:to_file()
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

function Cmd.suffix(command)
  local space_pos = command:find(" ")

  if space_pos then
    return command:sub(space_pos + 1)
  else
    return ""
  end
end

return Cmd
