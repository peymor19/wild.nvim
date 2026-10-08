local Cmd = require("wild.cmd")

describe("get_searchables", function()
    it("should return a list searchable items", function()
        local commands_from_file =
            { { cmd = "foo", count = 1 }, { cmd = "bar", count = 10 }, { cmd = "baz", count = 5 } }

        local result = Cmd.get_searchables(commands_from_file)

        assert.is_true(type(result) == "table")
        assert.are_not.equals(#result["commands"], 0)
    end)
end)

describe("get_vim_commands", function()
    it("should return a list of vim commands", function()
        local result = Cmd.get_vim_commands()

        assert.is_true(type(result) == "table")
        assert.are_not.equals(#result, 0)
    end)
end)

describe("command_name", function()
    it("should resolve abbreviations to the full command name", function()
        assert.is_equal("edit", Cmd.command_name("e"))
        assert.is_equal("echo", Cmd.command_name("ec"))
    end)

    it("should ignore ranges and arguments", function()
        assert.is_equal("edit", Cmd.command_name("e foo.txt"))
        assert.is_equal("substitute", Cmd.command_name("%s/foo/bar/g"))
    end)

    it("should return nil for an invalid command", function()
        assert.is_nil(Cmd.command_name("notacommand"))
        assert.is_nil(Cmd.command_name(""))
    end)
end)

describe("inc_command", function()
    it("should increment a commands usage count with matching command", function()
        local commands = {
            { cmd = "bar", count = 10 },
            { cmd = "baz", count = 5 },
            { cmd = "foo", count = 1 },
        }

        local result = Cmd.inc_command("foo", commands)

        local expected = {
            { cmd = "bar", count = 10 },
            { cmd = "baz", count = 5 },
            { cmd = "foo", count = 2 },
        }

        assert.are.same(expected, result)
    end)

    it("should return list with a not matching command", function()
        local commands = {
            { cmd = "bar", count = 10 },
            { cmd = "baz", count = 5 },
            { cmd = "foo", count = 1 },
        }

        local result = Cmd.inc_command("foobar", commands)

        assert.are.same(commands, result)
    end)

    it("should not add a new entry for a partial command", function()
        local commands = { { cmd = "echo", count = 1 } }

        local result = Cmd.inc_command("ec", commands)

        assert.are.same({ { cmd = "echo", count = 1 } }, result)
    end)

    it("should move a command up when it passes another in usage", function()
        local commands = { { cmd = "bar", count = 2 }, { cmd = "foo", count = 2 } }

        local result = Cmd.inc_command("foo", commands)

        assert.are.same({ { cmd = "foo", count = 3 }, { cmd = "bar", count = 2 } }, result)
    end)

    it("should ignore empty and invalid commands", function()
        local commands = { { cmd = "echo", count = 1 } }

        assert.are.same({ { cmd = "echo", count = 1 } }, Cmd.inc_command("", commands))
        assert.are.same({ { cmd = "echo", count = 1 } }, Cmd.inc_command(nil, commands))
    end)

    it("should not error on input containing lua pattern characters", function()
        local commands = { { cmd = "echo", count = 1 } }

        for _, input in ipairs({ "echo(", "%", "e[" }) do
            assert.are.same({ { cmd = "echo", count = 1 } }, Cmd.inc_command(input, commands))
        end
    end)
end)

describe("get_help_tags", function()
    it("should return tag names from the runtime help files", function()
        local tags = Cmd.get_help_tags()
        local names = vim.tbl_map(function(item)
            return item.cmd
        end, tags)

        assert.is_true(vim.tbl_contains(names, "help"))
        assert.is_false(vim.tbl_contains(names, "!_TAG_FILE_ENCODING"))
    end)
end)

describe("is_help", function()
    it("should match every abbreviation of help followed by a space", function()
        for _, input in ipairs({ "h ", "he tags", "hel x", "help options" }) do
            assert.is_true(Cmd.is_help(input), input)
        end
    end)

    it("should not match other commands or help without an argument", function()
        for _, input in ipairs({ "help", "hi Normal", "helpgrep foo", "edit h ", "" }) do
            assert.is_false(Cmd.is_help(input), input)
        end
    end)
end)

describe("sort_by_usage", function()
    it("should return a list of vim commands sorted by most used", function()
        local commands = { { cmd = "foo", count = 1 }, { cmd = "bar", count = 10 }, { cmd = "baz", count = 5 } }

        local result = Cmd.sort_by_usage(commands)

        local expected = { { cmd = "bar", count = 10 }, { cmd = "baz", count = 5 }, { cmd = "foo", count = 1 } }

        assert.are.same(expected, result)
    end)
end)

describe("to_file", function()
    local file_path = vim.fn.tempname()

    before_each(function()
        os.remove(file_path)
    end)

    after_each(function()
        os.remove(file_path)
    end)

    it("writes commands to a file when commands are not empty", function()
        local commands = { { cmd = "foo", count = 2 }, { cmd = "bar", count = 1 } }
        Cmd.to_file(file_path, commands)

        local file = io.open(file_path, "r")
        assert.is_not_nil(file)

        local contents = file:read("*all")
        file:close()

        local results = vim.json.decode(contents)
        assert.are.same(commands, results)
    end)

    it("creates missing parent directories", function()
        local dir = vim.fn.tempname()
        local nested_path = dir .. "/nested/history.json"
        local commands = { { cmd = "foo", count = 1 } }

        Cmd.to_file(nested_path, commands)

        local file = io.open(nested_path, "r")
        assert.is_not_nil(file)
        file:close()

        vim.fn.delete(dir, "rf")
    end)

    it("only writes commands that have been used", function()
        Cmd.to_file(file_path, { { cmd = "foo", count = 2 }, { cmd = "bar", count = 0 } })

        assert.are.same({ { cmd = "foo", count = 2 } }, Cmd.from_file(file_path))
    end)

    it("does not create a file when commands are empty", function()
        Cmd.to_file(file_path, {})
        assert.is_nil(io.open(file_path, "r"))
    end)
end)

describe("from_file", function()
    local file_path = vim.fn.tempname()

    before_each(function()
        os.remove(file_path)
    end)

    after_each(function()
        os.remove(file_path)
    end)

    it("reads commands from a file with valid json", function()
        local commands = { { cmd = "foo", count = 2 }, { cmd = "bar", count = 1 } }

        local file = io.open(file_path, "w")
        file:write(vim.json.encode(commands))
        file:close()

        local results = Cmd.from_file(file_path)
        assert.are.same(commands, results)
    end)

    it("returns an empty table when the file is missing", function()
        local results = Cmd.from_file(file_path)
        assert.are.same({}, results)
    end)

    it("returns an empty table when the file contains invalid json", function()
        local file = io.open(file_path, "w")
        file:write("invalid_json")
        file:close()

        local results = Cmd.from_file(file_path)
        assert.are.same({}, results)
    end)
end)

describe("tail", function()
    it("should return the tail of the command string", function()
        local result = Cmd.tail("test command")

        assert.is_equal(result, "command")
    end)

    it("should return return empty string with no tail", function()
        local result = Cmd.tail("test")

        assert.is_equal(result, "")
    end)
end)

describe("searchable_type_from_input", function()
    it("should search commands for plain input", function()
        local input, type, prefix = Cmd.searchable_type_from_input("ed")

        assert.is_equal("ed", input)
        assert.is_equal("commands", type)
        assert.is_equal("", prefix)
    end)

    it("should search help tags for help input", function()
        local input, type, prefix = Cmd.searchable_type_from_input("h tags")

        assert.is_equal("tags", input)
        assert.is_equal("help_tags", type)
        assert.is_equal("help ", prefix)
    end)
end)
