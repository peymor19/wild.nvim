local Commands = {}

function Commands.is_help(input)
    local valid_prefixes = { "h ", "he ", "hel ", "help " }

    for _, prefix in ipairs(valid_prefixes) do
        if string.sub(input, 1, #prefix) == prefix then
            return true
        end
    end

    return false
end

function Commands.suffix(command)
  local space_pos = command:find(" ")

  if space_pos then
    return command:sub(space_pos + 1)
  else
    return ""
  end
end

function Commands.get_commands()
    commands = {}

    for _, name in pairs(vim.fn.getcompletion("", "cmdline")) do
        if not string.match(name, "[~!?#&<>@=]") then
            table.insert(commands, name)
        end
    end

    return commands
end

function Commands.get_help_tags()
  local runtimepath = vim.o.runtimepath
  local paths = vim.split(runtimepath, ',')

    help_tags = {}

    for _, path in ipairs(paths) do
        local doc_path = path .. '/doc'

        if vim.fn.isdirectory(doc_path) then
            local files = vim.fn.globpath(doc_path, 'tags', false, true)

            for _, file in ipairs(files) do
                local lines = vim.fn.readfile(file)

                for _, line in ipairs(lines) do
                    if not line:match "^!_TAG_" then
                        local fields = vim.split(line, "\t", { trimempty = true })
                        table.insert(help_tags, fields[1])
                    end
                end
            end
        end
    end

    return help_tags
end

return Commands
