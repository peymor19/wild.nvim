local Cmd = require "cmd"

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
