local config = require("wild.config")
local history = require("wild.history")

local function run_health()
    vim.cmd("checkhealth wild")
    local buf = vim.api.nvim_get_current_buf()

    assert.is_true(
        vim.wait(5000, function()
            return vim.bo[buf].filetype == "checkhealth"
        end),
        "checkhealth did not finish"
    )

    local output = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    vim.cmd("bwipeout!")
    return output
end

local function assert_contains(output, text)
    assert.is_truthy(output:find(text, 1, true), "expected to find: " .. text .. "\n\n" .. output)
end

describe("checkhealth wild", function()
    local original_path = history.path
    local original_search_path = history.search_path

    before_each(function()
        config.options = {}
        history.path = vim.fn.tempname()
        history.search_path = vim.fn.tempname()
    end)

    after_each(function()
        os.remove(history.path)
        os.remove(history.search_path)
        history.path = original_path
        history.search_path = original_search_path
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
        local output = run_health()

        assert_contains(output, "No command history file yet")
        assert_contains(output, "No search history file yet")
    end)

    it("reports the number of commands in a valid history file", function()
        history.write(history.path, {
            { line = "e foo.txt", count = 2, last_used = os.time() },
            { line = "w", count = 1, last_used = os.time() },
        })

        assert_contains(run_health(), "OK 2 commands in history")
    end)

    it("reports the number of searches in a valid search history file", function()
        history.write(history.search_path, { { line = "foo", count = 1, last_used = os.time() } })

        assert_contains(run_health(), "OK 1 searches in history")
    end)

    it("errors when the history file is not valid JSON", function()
        vim.fn.writefile({ "not json" }, history.path)

        assert_contains(run_health(), "ERROR History file is not valid JSON")
    end)
end)
