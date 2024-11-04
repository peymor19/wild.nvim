local WildUi = {
    highlighter = {
        current_line = -1,
        namespace = vim.api.nvim_create_namespace("Highlighter")
    },
    update_buffer = true
}

WildUi.__index = WildUi

local function create_window_config(buf_line_count)
    local ui = vim.api.nvim_list_uis()[1]
    local col = 0
    local row = 0
    local max_height = 10

    local height = math.max(math.min(buf_line_count, max_height), 1)

    if ui ~= nil then
        row = math.max(ui.height - height, 0)
    end

    return {
        relative = "editor",
        width = 30,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
        zindex = 50,
        hide = false
    }
end

function WildUi.create_window(buf_data)
    buf_id = vim.api.nvim_create_buf(false, true)
    config = create_window_config(#buf_data)

    win_id = vim.api.nvim_open_win(buf_id, false, config)

    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, buf_data)

    return buf_id, win_id
end

function WildUi.close_window(win_id, buf_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
    end

    if buf_id and vim.api.nvim_win_is_valid(buf_id) then
        vim.api.nvim_buf_delete(buf_id, { force = true })
    end

    WildUi:reset_highlight()
end

function WildUi.resize_window(win_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        local buf_line_count = vim.api.nvim_buf_line_count(buf_id)
        local config = create_window_config(buf_line_count)
        vim.api.nvim_win_set_config(win_id, config)
    end
end

function WildUi.redraw()
    vim.cmd([[redraw]])
end

function WildUi:update_buffer_contents(buf_id, data)
    if not self.update_buffer then
        return
    end

    vim.api.nvim_buf_clear_namespace(buf_id, -1, 0, -1)

    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        local config = create_window_config(#data)
        vim.api.nvim_win_set_config(win_id, config)

        if #data == 0 then
            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, { "No Results" })
        else
            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, data)
        end
    end
end

function WildUi:highlight_line(buf_id, win_id)
    vim.api.nvim_buf_clear_namespace(buf_id, self.highlighter.namespace, 0, -1)

    vim.api.nvim_buf_add_highlight(buf_id, self.highlighter.namespace, "Visual", self.highlighter.current_line, 0, 30)

    WildUi.redraw()
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

    if self.highlighter.current_line >= 0 then
        vim.api.nvim_win_set_cursor(win_id, {self.highlighter.current_line + 1, 0})
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

    if self.highlighter.current_line >= 0 then
        vim.api.nvim_win_set_cursor(win_id, {self.highlighter.current_line + 1, 0})
    end

    WildUi:highlight_line(buf_id, win_id)
    WildUi:set_command_line(buf_id, self.highlighter.current_line)
end

function WildUi:reset_highlight()
    self.highlighter.current_line = -1
end

return WildUi
