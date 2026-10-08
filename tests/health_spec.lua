local config = require("wild.config")
local cmd = require("wild.cmd")

local function run_health()
    vim.cmd("checkhealth wild")
    local output = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    vim.cmd("bwipeout!")
    return output
end

local function assert_contains(output, text)
    assert.is_truthy(output:find(text, 1, true), "expected to find: " .. text .. "\n\n" .. output)
end

describe("checkhealth wild", function()
    local original_path = cmd.history_path

    before_each(function()
        config.options = {}
        cmd.history_path = vim.fn.tempname()
    end)

    after_each(function()
        os.remove(cmd.history_path)
        cmd.history_path = original_path
        pcall(vim.keymap.del, "c", "<C-n>")
    end)

    it("reports the Neovim version", function()
        assert_contains(run_health(), "OK Neovim " .. tostring(vim.version()))
    end)

    it("warns when setup() has not been called", function()
        assert_contains(run_health(), "WARNING setup() has not been called")
    end)

    it("warns when a selection key is mapped by something else", function()
        config.setup({ keymaps = { next_key = "<C-n>" } })
        vim.keymap.set("c", "<C-n>", "<Down>", { desc = "other plugin" })

        assert_contains(run_health(), "WARNING <C-n> is mapped by something else: other plugin")
    end)

    it("reports when there is no history file yet", function()
        assert_contains(run_health(), "No history file yet")
    end)

    it("reports the number of commands in a valid history file", function()
        cmd.to_file(cmd.history_path, { { cmd = "edit", count = 2 }, { cmd = "write", count = 1 } })

        assert_contains(run_health(), "OK 2 commands in history")
    end)

    it("errors when the history file is not valid JSON", function()
        vim.fn.writefile({ "not json" }, cmd.history_path)

        assert_contains(run_health(), "ERROR History file is not valid JSON")
    end)
end)
