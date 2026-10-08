local config = require("wild.config")
local ui = require("wild.ui")

describe("close_window", function()
    before_each(function()
        config.setup()
    end)

    it("should close the window and delete its buffer", function()
        local win_id, buf_id = ui.create_window({ "a", "b", "c" })

        ui.close_window(win_id, buf_id)

        assert.falsy(vim.api.nvim_win_is_valid(win_id))
        assert.falsy(vim.api.nvim_buf_is_valid(buf_id))
    end)

    it("should not error when the window and buffer are already gone", function()
        local win_id, buf_id = ui.create_window({ "a", "b", "c" })
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
        win_id, buf_id = ui.create_window({ "a", "b", "c" })
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

    it("should show a placeholder when there are no results", function()
        ui.update_buffer_contents(win_id, buf_id, {})
        assert.are.same({ "No Results" }, vim.api.nvim_buf_get_lines(buf_id, 0, -1, false))

        ui.update_buffer_contents(win_id, buf_id, {}, "No History")
        assert.are.same({ "No History" }, vim.api.nvim_buf_get_lines(buf_id, 0, -1, false))
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
            win_id, buf_id = ui.create_window(vim.tbl_map(function(item)
                return item[1]
            end, data))
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

describe("get_layout", function()
    local lines = { "edit", "echo", "a_longer_command" }

    local function layout(options, custom_lines)
        config.setup(vim.tbl_deep_extend("force", { window = { border = "rounded", height = 10 } }, options))
        return ui.get_layout(custom_lines or lines)
    end

    before_each(function()
        vim.o.columns = 80
        vim.o.lines = 24
        vim.o.cmdheight = 1
    end)

    it("should open above the command line at the bottom by default", function()
        local result = layout({ window = { width = 30 } })

        assert.are.same({ relative = "editor", width = 30, height = 3, row = 17, col = 0 }, result)
    end)

    it("should account for a missing border and a taller command line", function()
        vim.o.cmdheight = 2

        assert.is_equal(18, layout({ window = { border = "none" } }).row)
    end)

    it("should limit the height to window.height", function()
        assert.is_equal(2, layout({ window = { height = 2 } }).height)
    end)

    it("should fit the longest line when the width is auto", function()
        assert.is_equal(16, layout({ window = { width = "auto", counter = false } }).width)
    end)

    it("should cap an auto width at max_width", function()
        assert.is_equal(10, layout({ window = { width = "auto", max_width = 10 } }).width)
    end)

    it("should leave room for the counter when the width is auto", function()
        assert.is_equal(5, layout({ window = { width = "auto", counter = true } }, { "a" }).width)
    end)

    it("should use a fixed width instead of the configured one", function()
        assert.is_equal(42, ui.get_layout(lines, 42).width)

        config.setup({ window = { width = "auto" } })
        assert.is_equal(42, ui.get_layout(lines, 42).width)
    end)

    it("should never be wider than the screen", function()
        vim.o.columns = 20

        assert.is_equal(18, layout({ window = { width = 30 } }).width)
    end)
end)

describe("set_counter", function()
    local win_id, buf_id

    local function footer()
        local chunks = vim.api.nvim_win_get_config(win_id).footer
        return chunks and chunks[1] and chunks[1][1]
    end

    after_each(function()
        ui.close_window(win_id, buf_id)
    end)

    it("should show the total before anything is selected", function()
        config.setup()
        win_id, buf_id = ui.create_window({ "a", "b" })

        ui.set_counter(win_id, nil, 229)

        assert.is_equal(" 229 ", footer())
    end)

    it("should show the selected position", function()
        config.setup()
        win_id, buf_id = ui.create_window({ "a", "b" })

        ui.set_counter(win_id, 2, 229)

        assert.is_equal(" 3/229 ", footer())
    end)

    it("should not show a counter when it is turned off", function()
        config.setup({ window = { counter = false } })
        win_id, buf_id = ui.create_window({ "a", "b" })

        ui.set_counter(win_id, 2, 229)

        assert.is_nil(footer())
    end)
end)

describe("selection", function()
    local win_id, buf_id

    before_each(function()
        config.setup()
        win_id, buf_id = ui.create_window({ "edit", "echo", "enew" })
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
