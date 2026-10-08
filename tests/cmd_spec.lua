local Cmd = require("wild.cmd")

describe("get_searchables", function()
    it("should return commands and help tags", function()
        local result = Cmd.get_searchables({}, os.time())

        assert.are_not.equals(#result.commands, 0)
        assert.are_not.equals(#result.help_tags, 0)
    end)
end)

describe("get_commands", function()
    local now = 1000000

    local function lines(commands)
        return vim.tbl_map(function(item)
            return item.cmd
        end, commands)
    end

    it("should list history lines first, ordered by frecency", function()
        local entries = {
            { line = "e foo.txt", count = 1, last_used = now },
            { line = "w", count = 5, last_used = now },
        }

        local result = lines(Cmd.get_commands(entries, now))

        assert.are.same({ "w", "e foo.txt" }, { result[1], result[2] })
    end)

    it("should list every vim command after the history", function()
        local result = lines(Cmd.get_commands({}, now))

        assert.are.same(Cmd.get_vim_commands(), result)
    end)

    it("should not list a command twice when it is also in the history", function()
        local entries = { { line = "write", count = 1, last_used = now } }

        local result = lines(Cmd.get_commands(entries, now))
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
