local config = require("wild.config")
local ui = require("wild.ui")

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
        ui.update_buffer_contents(win_id, buf_id, { { "edit", { 1, 2 }, 1 }, { "echo", { 1 }, 1 } })
        ui.update_buffer_contents(win_id, buf_id, { { "edit", { 1 }, 1 } })

        local marks = vim.api.nvim_buf_get_extmarks(buf_id, chars_ns_id, 0, -1, {})

        assert.is_equal(1, #marks)
    end)

    describe("with more results than fit in the window", function()
        local data = {}
        for i = 1, 50 do
            data[i] = { "item" .. i, { 1 }, 1 }
        end

        local function marked_rows()
            return vim.tbl_map(function(mark)
                return mark[2]
            end, vim.api.nvim_buf_get_extmarks(buf_id, chars_ns_id, 0, -1, {}))
        end

        local function top_row()
            return vim.api.nvim_win_call(win_id, function()
                return vim.fn.line("w0")
            end)
        end

        before_each(function()
            ui.close_window(win_id, buf_id)
            config.setup({ window = { height = 10 } })
            win_id, buf_id = ui.create_window(#data)
        end)

        it("should only highlight the visible rows", function()
            ui.update_buffer_contents(win_id, buf_id, data)

            assert.are.same({ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, marked_rows())
        end)

        it("should highlight the rows scrolled into view", function()
            ui.update_buffer_contents(win_id, buf_id, data)
            ui.select_line(win_id, 39)
            ui.highlight_chars(win_id, buf_id, data)

            local rows = marked_rows()
            assert.is_equal(10, #rows)
            assert.is_equal(top_row() - 1, rows[1])
            assert.is_true(vim.tbl_contains(rows, 39))
        end)

        it("should scroll back to the top when the results change", function()
            ui.update_buffer_contents(win_id, buf_id, data)
            ui.select_line(win_id, 39)
            ui.update_buffer_contents(win_id, buf_id, data)

            assert.is_equal(1, top_row())
        end)
    end)
end)

describe("selection", function()
    local win_id, buf_id

    before_each(function()
        config.setup()
        win_id, buf_id = ui.create_window(3)
        ui.set_buffer_contents(buf_id, { "edit", "echo", "enew" })
    end)

    after_each(function()
        ui.close_window(win_id, buf_id)
    end)

    it("select_line should move the cursor and show the cursorline", function()
        ui.select_line(win_id, 2)

        assert.are.same({ 3, 0 }, vim.api.nvim_win_get_cursor(win_id))
        assert.is_true(vim.api.nvim_get_option_value("cursorline", { win = win_id }))
    end)

    it("clear_selection should hide the cursorline", function()
        ui.select_line(win_id, 1)
        ui.clear_selection(win_id)

        assert.is_false(vim.api.nvim_get_option_value("cursorline", { win = win_id }))
    end)

    it("clear_selection should not error when the window is gone", function()
        ui.close_window(win_id, buf_id)

        ui.clear_selection(win_id)
        ui.clear_selection(nil)
    end)

    it("set_command_line should restore the previous eventignore", function()
        vim.o.eventignore = "BufEnter"

        ui.set_command_line(buf_id, 0, "")

        assert.is_equal("BufEnter", vim.o.eventignore)
        vim.o.eventignore = ""
    end)
end)
