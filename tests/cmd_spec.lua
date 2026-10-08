local Cmd = require "wild.cmd"

describe("get_searchables", function()
    it("should return a list searchable items", function()
        local commands_from_file = {{cmd = "foo", count = 1}, {cmd = "bar", count = 10}, {cmd="baz", count = 5}}

        local result = Cmd.get_searchables(commands_from_file)

        assert.is_true(type(result) == "table")
        assert.are_not.equals(#result["commands"], 0)
    end)
end)

describe("get_vim_commands", function()
    it("should return a list of vim commands", function()
        result = Cmd.get_vim_commands()

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

describe("in_list", function()
    it("should return true with command input matching a command in list", function()
        local commands = {{cmd = "foo", count = 1}, {cmd = "bar", count = 10}, {cmd="baz", count = 5}}

        local result = Cmd.in_list("foo", commands)

        assert.truthy(result)
    end)

    it("should return false with command input not matching a command in list", function()
        local commands = {{cmd = "foo", count = 1}, {cmd = "bar", count = 10}, {cmd="baz", count = 5}}

        local result = Cmd.in_list("foobar", commands)

        assert.falsy(result)
    end)

    it("should return false with input that is only a substring of a command", function()
        local commands = {{cmd = "echo", count = 1}}

        assert.falsy(Cmd.in_list("ec", commands))
    end)

    it("should return false with empty input", function()
        local commands = {{cmd = "echo", count = 1}}

        assert.falsy(Cmd.in_list("", commands))
    end)

    it("should not error on input containing lua pattern characters", function()
        local commands = {{cmd = "echo", count = 1}}

        for _, input in ipairs({"echo(", "%", "e["}) do
            assert.falsy(Cmd.in_list(input, commands))
        end
    end)
end)

describe("inc_command", function()
    it("should increment a commands usage count with matching command", function()
        local commands = {
            {cmd = "bar", count = 10},
            {cmd = "baz", count = 5},
            {cmd="foo", count = 1}
        }

        local result = Cmd.inc_command("foo", commands)

        expected = {
            {cmd = "bar", count = 10},
            {cmd = "baz", count = 5},
            {cmd="foo", count = 2}
        }

        assert.are.same(expected, result)
    end)

    it("should return list with a not matching command", function()
        local commands = {
            {cmd = "bar", count = 10},
            {cmd = "baz", count = 5},
            {cmd="foo", count = 1}
        }

        result = Cmd.inc_command("foobar", commands)

        assert.are.same(commands, result)
    end)

    it("should not add a new entry for a partial command", function()
        local commands = {{cmd = "echo", count = 1}}

        local result = Cmd.inc_command("ec", commands)

        assert.are.same({{cmd = "echo", count = 1}}, result)
    end)
end)

describe("sort_by_usage", function()
    it("should return a list of vim commands sorted by most used", function()
        local commands = {{cmd = "foo", count = 1}, {cmd = "bar", count = 10}, {cmd="baz", count = 5}}

        local result = Cmd.sort_by_usage(commands)

        local expected = {{cmd = "bar", count = 10}, {cmd = "baz", count = 5}, {cmd="foo", count = 1}}

        assert.are.same(expected, result)
    end)
end)

describe("to_file", function()
    local file_path = vim.fn.stdpath('data') .. '/command_history_test.json'

    before_each(function()
        os.remove(file_path)
    end)

    after_each(function()
        os.remove(file_path)
    end)

    it("writes commands to a file when commands are not empty", function()
        local commands = { { cmd = "foo", count = 2 }, { cmd = "bar", count = 1 } }
        Cmd.to_file(file_path, commands)

        local file = io.open(file_path, 'r')
        assert.is_not_nil(file)

        local contents = file:read('*all')
        file:close()

        local results = vim.json.decode(contents)
        assert.are.same(commands, results)
    end)

    it("does not create a file when commands are empty", function()
        Cmd.to_file(file_path, {})
        assert.is_nil(io.open(file_path, 'r'))
    end)

end)

describe("from_file", function()
    local file_path = vim.fn.stdpath('data') .. '/command_history_test.json'

    before_each(function()
        os.remove(file_path)
    end)

    after_each(function()
        os.remove(file_path)
    end)

    it("reads commands from a file with valid json", function()
        local commands = { { cmd = "foo", count = 2 }, { cmd = "bar", count = 1 } }

        local file = io.open(file_path, 'w')
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
        local file = io.open(file_path, 'w')
        file:write("invalid_json")
        file:close()

        local results = Cmd.from_file(file_path)
        assert.are.same({}, results)
    end)
end)

describe("tail", function()
    it("should return the tail of the command string", function()
        result = Cmd.tail("test command")

        assert.is_equal(result, "command")
    end)

    it("should return return empty string with no tail", function()
        result = Cmd.tail("test")

        assert.is_equal(result, "")
    end)
end)

describe("searchable_type_from_input", function()
    it("should search commands for plain input", function()
        local input, type = Cmd.searchable_type_from_input("ed")

        assert.is_equal("ed", input)
        assert.is_equal("commands", type)
    end)

    it("should search help tags for help input", function()
        local input, type = Cmd.searchable_type_from_input("h tags")

        assert.is_equal("tags", input)
        assert.is_equal("help_tags", type)
    end)
end)
