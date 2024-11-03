local WildUi = {
    highlighter = {
        current_line = -1,
        namespace = vim.api.nvim_create_namespace("Highlighter")
    },
    update_buffer = true
}

WildUi.__index = WildUi

local function create_window_config()
    local ui = vim.api.nvim_list_uis()[1]
    local col = 12
    local row = 0

    if ui ~= nil then
        col = math.max(ui.width - 13, 0)
        row = math.max(ui.height - 13, 0)
    end

    print("row: ", row, "col: ", col)

    return {
        relative = "editor",
        width = 30,
        height = 10,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
        zindex = 1000,
        hide = true
    }
end

function WildUi.create_window(buf_data)
    buf_id = vim.api.nvim_create_buf(false, true)
    config = create_window_config()
    win_id = vim.api.nvim_open_win(buf_id, false, config)

    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, buf_data)

    return buf_id, win_id
end

function WildUi.hide_window(win_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_set_config(win_id, { hide = true })
        WildUi:reset_highlight()
    end
end

function WildUi.show_window(win_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_set_config(win_id, { hide = false })
    end
end

function WildUi.resize_window(win_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        --local config = create_window_config()
        --vim.api.nvim_win_set_config(win_id, config)
        --WildUi.redraw_window(win_id)
    end
end

function WildUi.redraw_window(win_id)
    vim.api.nvim_win_call(win_id, function()
        --vim.cmd([[redraw!]]) -- I don't think I need to redraw everything just my window
        vim.cmd([[redraw]])
    end)
end

function WildUi:update_buffer_contents(buf_id, data)
    if not self.update_buffer then
        return
    end

    vim.api.nvim_buf_clear_namespace(buf_id, -1, 0, -1)

    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, data)
    end
end

function WildUi:highlight_line(buf_id, win_id)
    vim.api.nvim_buf_clear_namespace(buf_id, self.highlighter.namespace, 0, -1)

    vim.api.nvim_buf_add_highlight(buf_id, self.highlighter.namespace, "Visual", self.highlighter.current_line, 0, 30)

    WildUi.redraw_window(win_id)
end

function WildUi:set_command_line(buf_id, line_number)
    self.update_buffer = false

    command = vim.api.nvim_buf_get_lines(buf_id, line_number, line_number + 1, false)[1]
    vim.fn.setcmdline(command)

    self.update_buffer = true
end

function WildUi:highlight_next_line(buf_id, win_id)
    local total_lines = vim.api.nvim_buf_line_count(buf_id)
    self.highlighter.current_line = self.highlighter.current_line + 1

    if self.highlighter.current_line > total_lines - 1 then
        self.highlighter.current_line = 0
    end

    WildUi:highlight_line(buf_id, win_id)
    WildUi:set_command_line(buf_id, self.highlighter.current_line)
end

function WildUi:highlight_previous_line(buf_id, win_id)
    local total_lines = vim.api.nvim_buf_line_count(buf_id)
    self.highlighter.current_line = self.highlighter.current_line - 1

    if self.highlighter.current_line < 0 then
        self.highlighter.current_line = total_lines - 1
    end

    WildUi:highlight_line(buf_id, win_id)
    WildUi:set_command_line(buf_id, self.highlighter.current_line)
end

function WildUi:reset_highlight()
    self.highlighter.current_line = -1
end

return WildUi
