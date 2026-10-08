local Completion = require("wild.completion")

describe("get_help_tags", function()
    it("should return tag names from the runtime help files", function()
        local tags = Completion.get_help_tags()

        assert.is_true(vim.tbl_contains(tags, "help"))
        assert.is_false(vim.tbl_contains(tags, "!_TAG_FILE_ENCODING"))
    end)
end)

describe("completion_context", function()
    it("should split off the argument being completed", function()
        assert.are.same(
            { type = "help", prefix = "h ", needle = "tag", query = "h " },
            Completion.completion_context("h tag", "tag", "help")
        )
    end)

    it("should complete an empty argument after a space", function()
        assert.are.same(
            { type = "color", prefix = "colorscheme ", needle = "", query = "colorscheme " },
            Completion.completion_context("colorscheme ", "", "color")
        )
    end)

    it("should query the directory of a path but match the whole path", function()
        assert.are.same(
            { type = "file", prefix = "e ", needle = "lua/wild/in", query = "e lua/wild/" },
            Completion.completion_context("e lua/wild/in", "lua/wild/in", "file")
        )
    end)

    it("should keep the lua table path in the prefix", function()
        assert.are.same(
            { type = "lua", prefix = "lua vim.api.", needle = "nvim_buf", query = "lua vim.api." },
            Completion.completion_context("lua vim.api.nvim_buf", "vim.api.nvim_buf", "lua")
        )
    end)

    it("should return nil when there is nothing to complete", function()
        assert.is_nil(Completion.completion_context("s/a b", "b", ""))
    end)

    it("should return nil while typing the command name", function()
        assert.is_nil(Completion.completion_context("edi", "edi", "command"))
    end)
end)

describe("get_arguments", function()
    it("should list arguments from the history first", function()
        local entries = {
            { line = "colorscheme tokyonight", count = 2, last_used = 0 },
            { line = "e foo.txt", count = 1, last_used = 0 },
            { line = "colorscheme blue", count = 1, last_used = 0 },
        }

        local result = Completion.get_arguments("colorscheme ", { "blue", "default", "tokyonight" }, entries)

        assert.are.same({ "tokyonight", "blue", "default" }, result)
    end)

    it("should skip history lines with no argument", function()
        local entries = { { line = "colorscheme", count = 1, last_used = 0 } }

        assert.are.same({ "blue" }, Completion.get_arguments("colorscheme ", { "blue" }, entries))
    end)
end)
