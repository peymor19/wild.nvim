local WildUi = {
    win_id = nil,
    buf_id = nil,
    buffer_locked = false,
    win_config = {
        relative = "editor",
        border = "rounded",
        --borderchars = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
        style = "minimal",
        width = 30,
        height = nil,
        col = nil,
        row = nil,
        zindex = 250
    },
    window = {
        opacity = 15
    },
    highlighter = {
        current_line = -1,
        namespace = vim.api.nvim_create_namespace("Highlighter")
    }
}

function WildUi:create_window_config(buf_line_count)
    local ui = vim.api.nvim_list_uis()[1]
    local col = 0
    local row = 0
    local max_height = 10

    local height = math.max(math.min(buf_line_count, max_height), 1)

    if ui ~= nil then
        row = math.max(ui.height - height - 4, 0)
    end

    self.win_config.height = height
    self.win_config.col = col
    self.win_config.row = row
end

function WildUi:create_window(buf_data)
    WildUi:create_window_config(#buf_data)

    self.buf_id = vim.api.nvim_create_buf(false, true)
    self.win_id = vim.api.nvim_open_win(self.buf_id, false, self.win_config)

    vim.api.nvim_set_option_value("winblend", self.window.opacity, { win = self.win_id, scope = "local" })

    vim.api.nvim_buf_set_lines(self.buf_id, 0, -1, false, buf_data)
end

function WildUi:close_window()
    if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
        vim.api.nvim_win_close(self.win_id, true)
    end

    if self.buf_id and vim.api.nvim_win_is_valid(self.buf_id) then
        vim.api.nvim_buf_delete(self.buf_id, { force = true })
    end

    WildUi:reset_highlight()
end

function WildUi:resize_window()
    if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
        local buf_line_count = vim.api.nvim_buf_line_count(self.buf_id)
        WildUi:create_window_config(buf_line_count)
        vim.api.nvim_win_set_config(self.win_id, self.win_config)
    end
end

function WildUi.redraw()
    vim.cmd([[redraw]])
end

function WildUi:update_buffer_contents(data)
    if self.buffer_locked then return end

    vim.api.nvim_buf_clear_namespace(self.buf_id, -1, 0, -1)

    if self.buf_id and vim.api.nvim_buf_is_valid(self.buf_id) then
        WildUi:create_window_config(#data)
        vim.api.nvim_win_set_config(self.win_id, self.win_config)

        if #data == 0 then data = { "No Results" } end

        vim.api.nvim_buf_set_lines(self.buf_id, 0, -1, false, data)
    end
end

function WildUi:set_command_line(line_number)
    self.buffer_locked = true

    command = vim.api.nvim_buf_get_lines(self.buf_id, line_number, line_number + 1, false)[1]
    vim.fn.setcmdline(command)

    self.buffer_locked = false
end

function WildUi:highlight_line()
    vim.api.nvim_buf_clear_namespace(self.buf_id, self.highlighter.namespace, 0, -1)

    vim.api.nvim_buf_add_highlight(self.buf_id, self.highlighter.namespace, "Visual", self.highlighter.current_line, 0, 30)

    WildUi.redraw()
end

function WildUi:highlight_next_line()
    local total_lines = vim.api.nvim_buf_line_count(self.buf_id)
    self.highlighter.current_line = self.highlighter.current_line + 1

    if self.highlighter.current_line > total_lines - 1 then
        self.highlighter.current_line = 0
    end

    if self.highlighter.current_line >= 0 then
        vim.api.nvim_win_set_cursor(self.win_id, {self.highlighter.current_line + 1, 0})
    end

    WildUi:highlight_line()
    WildUi:set_command_line(self.highlighter.current_line)
end

function WildUi:highlight_previous_line()
    local total_lines = vim.api.nvim_buf_line_count(self.buf_id)
    self.highlighter.current_line = self.highlighter.current_line - 1

    if self.highlighter.current_line < 0 then
        self.highlighter.current_line = total_lines - 1
    end

    if self.highlighter.current_line >= 0 then
        vim.api.nvim_win_set_cursor(self.win_id, {self.highlighter.current_line + 1, 0})
    end

    WildUi:highlight_line()
    WildUi:set_command_line(self.highlighter.current_line)
end

function WildUi:reset_highlight()
    self.highlighter.current_line = -1
end

return WildUi
