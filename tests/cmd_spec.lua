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

describe("get_help_tags", function()
    it("should return tag names from the runtime help files", function()
        local tags = Cmd.get_help_tags()

        assert.is_true(vim.tbl_contains(tags, "help"))
        assert.is_false(vim.tbl_contains(tags, "!_TAG_FILE_ENCODING"))
    end)
end)

describe("completion_context", function()
    it("should split off the argument being completed", function()
        assert.are.same(
            { type = "help", prefix = "h ", needle = "tag", query = "h " },
            Cmd.completion_context("h tag", "tag", "help")
        )
    end)

    it("should complete an empty argument after a space", function()
        assert.are.same(
            { type = "color", prefix = "colorscheme ", needle = "", query = "colorscheme " },
            Cmd.completion_context("colorscheme ", "", "color")
        )
    end)

    it("should query the directory of a path but match the whole path", function()
        assert.are.same(
            { type = "file", prefix = "e ", needle = "lua/wild/in", query = "e lua/wild/" },
            Cmd.completion_context("e lua/wild/in", "lua/wild/in", "file")
        )
    end)

    it("should keep the lua table path in the prefix", function()
        assert.are.same(
            { type = "lua", prefix = "lua vim.api.", needle = "nvim_buf", query = "lua vim.api." },
            Cmd.completion_context("lua vim.api.nvim_buf", "vim.api.nvim_buf", "lua")
        )
    end)

    it("should return nil when there is nothing to complete", function()
        assert.is_nil(Cmd.completion_context("s/a b", "b", ""))
    end)

    it("should return nil while typing the command name", function()
        assert.is_nil(Cmd.completion_context("edi", "edi", "command"))
    end)
end)

describe("get_arguments", function()
    it("should list arguments from the history first", function()
        local entries = {
            { line = "colorscheme tokyonight", count = 2, last_used = 0 },
            { line = "e foo.txt", count = 1, last_used = 0 },
            { line = "colorscheme blue", count = 1, last_used = 0 },
        }

        local result = Cmd.get_arguments("colorscheme ", { "blue", "default", "tokyonight" }, entries)

        assert.are.same({ "tokyonight", "blue", "default" }, result)
    end)

    it("should skip history lines with no argument", function()
        local entries = { { line = "colorscheme", count = 1, last_used = 0 } }

        assert.are.same({ "blue" }, Cmd.get_arguments("colorscheme ", { "blue" }, entries))
    end)
end)
