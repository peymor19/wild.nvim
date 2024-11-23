local Cmd = require "cmd"

describe("get_commands", function()
    it("should return a list of vim commands", function()
        result = Cmd.get_commands()

        assert.are_not.equals(#result, 0)
        assert.is_true(type(result) == "table")
    end)
end)

describe("is_valid", function()
    it("should return true with command input matching a command in list", function()
        local commands = { "test1", "test2", "test3" }

        local result = Cmd.is_valid("test1", commands)

        assert.truthy(result)
    end)

    it("should return false with command input not matching a command in list", function()
        local commands = { "test1", "test2", "test3" }

        local result = Cmd.is_valid("foo", commands)

        assert.falsy(result)
    end)
end)

describe("inc_usage", function()
    it("should increment a commands usage count with matching command", function()
        local cmd_history = {
            {cmd = "test1", count = 1},
            {cmd = "test2", count = 1}
        }

        result = Cmd.inc_usage("test1", cmd_history)

        assert.is_equal(result[1].cmd, "test1")
        assert.is_equal(result[1].count, 2)
        assert.is_equal(result[2].cmd, "test2")
        assert.is_equal(result[2].count, 1)
    end)

    it("should insert into commands table with a not matching command", function()
        local cmd_history = {
            {cmd = "test1", count = 1},
            {cmd = "test2", count = 1}
        }

        result = Cmd.inc_usage("foo", cmd_history)

        assert.is_equal(result[3].cmd, "foo")
        assert.is_equal(result[3].count, 1)
    end)
end)

describe("sort_history", function()
    it("should sort a table by count in descending order", function()
        local cmd_history = {
            {cmd = "test1", count = 5},
            {cmd = "test2", count = 3},
            {cmd = "test3", count = 8}
        }

        local result = Cmd.sort_history(cmd_history)

        assert.is_equal(result[1].cmd, "test3")
        assert.is_equal(result[1].count, 8)
        assert.is_equal(result[2].cmd, "test1")
        assert.is_equal(result[2].count, 5)
        assert.is_equal(result[3].cmd, "test2")
        assert.is_equal(result[3].count, 3)
    end)

    it("should preserve the relative order of items with the same count", function()
        local cmd_history = {
            {cmd = "test1", count = 5},
            {cmd = "test2", count = 3},
            {cmd = "test3", count = 5}
        }

        local result = Cmd.sort_history(cmd_history)

        assert.is_equal(result[1].cmd, "test1")
        assert.is_equal(result[1].count, 5)
        assert.is_equal(result[2].cmd, "test3")
        assert.is_equal(result[2].count, 5)
        assert.is_equal(result[3].cmd, "test2")
        assert.is_equal(result[3].count, 3)
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
