local Cmd = require("wild.cmd")

describe("get_commands", function()
    local now = 1000000

    it("should list history lines first, ordered by frecency", function()
        local entries = {
            { line = "e foo.txt", count = 1, last_used = now },
            { line = "w", count = 5, last_used = now },
        }

        local result = (Cmd.get_commands(entries, now))

        assert.are.same({ "w", "e foo.txt" }, { result[1], result[2] })
    end)

    it("should list every vim command after the history", function()
        local result = (Cmd.get_commands({}, now))

        assert.are.same(Cmd.get_vim_commands(), result)
    end)

    it("should not list a command twice when it is also in the history", function()
        local entries = { { line = "write", count = 1, last_used = now } }

        local result = (Cmd.get_commands(entries, now))
        local writes = vim.tbl_filter(function(line)
            return line == "write"
        end, result)

        assert.is_equal("write", result[1])
        assert.is_equal(1, #writes)
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
