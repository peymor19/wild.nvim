local config = require "wild.config"
local ui = require "wild.ui"

describe("close_window", function()
    before_each(function()
        config.setup()
    end)

    it("should close the window and delete its buffer", function()
        local win_id, buf_id = ui.create_window(3)

        ui.close_window(win_id, buf_id)

        assert.falsy(vim.api.nvim_win_is_valid(win_id))
        assert.falsy(vim.api.nvim_buf_is_valid(buf_id))
    end)

    it("should not error when the window and buffer are already gone", function()
        local win_id, buf_id = ui.create_window(3)
        vim.api.nvim_win_close(win_id, true)
        vim.api.nvim_buf_delete(buf_id, { force = true })

        ui.close_window(win_id, buf_id)
        ui.close_window(nil, nil)
    end)
end)

describe("get_buf_data", function()
    it("should return the names for the given searchable type", function()
        local searchables = { commands = {{cmd = "edit", count = 1}, {cmd = "echo", count = 0}} }

        assert.are.same({"edit", "echo"}, ui.get_buf_data("commands", searchables))
    end)

    it("should return an empty list before searchables have loaded", function()
        assert.are.same({}, ui.get_buf_data("commands", {}))
    end)
end)

describe("update_buffer_contents", function()
    local chars_ns_id = vim.api.nvim_create_namespace("wild_highlight_characters")
    local win_id, buf_id

    before_each(function()
        config.setup()
        win_id, buf_id = ui.create_window(3)
    end)

    after_each(function()
        ui.close_window(win_id, buf_id)
    end)

    it("should only highlight matched characters of the current results", function()
        ui.update_buffer_contents(win_id, buf_id, {{"edit", {1, 2}, 1}, {"echo", {1}, 1}})
        ui.update_buffer_contents(win_id, buf_id, {{"edit", {1}, 1}})

        local marks = vim.api.nvim_buf_get_extmarks(buf_id, chars_ns_id, 0, -1, {})

        assert.is_equal(1, #marks)
    end)
end)
