local cmd = require("cmd")

local M = {}

M.config = {
    is_results = true,
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
        id = nil,
        current_line = -1,
        namespace = vim.api.nvim_create_namespace("Highlighter"),
        char_color = "#ff8800"
    }
}

function M.get_buf_data(type, searchables)
    return vim.tbl_map(function(item)
        return item.cmd
    end, searchables[type])
end

function M.set_config(buf_line_count)
    local ui = vim.api.nvim_list_uis()[1]
    local col = 0
    local row = 0
    local max_height = 10

    local height = math.max(math.min(buf_line_count, max_height), 1)

    if ui ~= nil then
        row = math.max(ui.height - height - 4, 0)
    end

    M.config.win_config.height = height
    M.config.win_config.col = col
    M.config.win_config.row = row
end

function M.create_window()
    buf_id = vim.api.nvim_create_buf(false, true)
    win_id = vim.api.nvim_open_win(buf_id, false, M.config.win_config)

    vim.api.nvim_set_option_value("winblend", M.config.window.opacity, { win = win_id, scope = "local" })

    return win_id, buf_id
end

function M.set_buffer_contents(buf_id, buf_data)
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, buf_data)
end

function M.close_window(win_id, buf_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
    end

    if buf_id and vim.api.nvim_win_is_valid(buf_id) then
        vim.api.nvim_buf_delete(state.buf_id, { force = true })
    end

    M:reset_highlight()
end

function M.resize_window(win_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        local buf_line_count = vim.api.nvim_buf_line_count(buf_id)
        M.set_config(buf_line_count)
        vim.api.nvim_win_set_config(win_id, M.config.win_config)
    end
end

function M.redraw()
    vim.cmd([[redraw]])
end

function M.update_buffer_contents(win_id, buf_id, data)
    vim.api.nvim_buf_clear_namespace(buf_id, -1, 0, -1)

    if #data == 0 then
        M.config.is_results = false
        data = { { "No Results", {}, 0 } }
    else
        M.config.is_results = true
    end

    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        M.set_config(#data)
        vim.api.nvim_win_set_config(win_id, M.config.win_config)

        local command_string = {}
        for _, item in ipairs(data) do
            table.insert(command_string, item[1]) -- Extract the strings
        end

        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, command_string)

        M.highlight_chars(buf_id, data, M.config.highlighter.char_color)
    end
end

function M.highlight_chars(buf_id, data, color)
    local ns_id = vim.api.nvim_create_namespace("wild.nvim")
    vim.api.nvim_set_hl(0, "hlcolor", { fg = color })

    for line_idx, item in ipairs(data) do
        local str, positions = item[1], item[2]
        for _, pos in ipairs(positions) do
            local char = str:sub(pos, pos)
            vim.api.nvim_buf_set_extmark(buf_id, ns_id, line_idx - 1, pos - 1, {
                virt_text = { { char, "hlcolor" } },
                virt_text_pos = "overlay",
                priority = 0
            })
        end
    end
end

function M.set_command_line(buf_id, line_number)
    local command = vim.api.nvim_buf_get_lines(buf_id, line_number, line_number + 1, false)[1]
    local input = vim.fn.getcmdline()

    vim.o.eventignore = "CmdlineChanged"

    if cmd.is_help(input) then
        vim.fn.setcmdline("help ".. command)
    else
        vim.fn.setcmdline(command)
    end

    vim.o.eventignore = ""
end

function M:highlight_line(buf_id)
    vim.api.nvim_buf_clear_namespace(buf_id, M.config.highlighter.namespace, 0, -1)

    local line_content = vim.api.nvim_buf_get_lines(buf_id, M.config.highlighter.current_line, M.config.highlighter.current_line + 1, false)[1]

    M.config.highlighter.id = vim.api.nvim_buf_set_extmark(buf_id, M.config.highlighter.namespace, M.config.highlighter.current_line, 0, {
        virt_text = { { line_content, "Visual" } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
        priority = 100
    })

    M.redraw()
end

function M:highlight_next_line(win_id, buf_id)
    if not M.config.is_results then return end

    local total_lines = vim.api.nvim_buf_line_count(buf_id)
    M.config.highlighter.current_line = M.config.highlighter.current_line + 1

    if M.config.highlighter.current_line > total_lines - 1 then
        M.config.highlighter.current_line = 0
    end

    if M.config.highlighter.current_line >= 0 then
        vim.api.nvim_win_set_cursor(win_id, {M.config.highlighter.current_line + 1, 0})
    end

    M:highlight_line(buf_id)
    M.set_command_line(buf_id, M.config.highlighter.current_line)
end

function M:highlight_previous_line(win_id, buf_id)
    if not M.config.is_results then return end

    local total_lines = vim.api.nvim_buf_line_count(buf_id)
    M.config.highlighter.current_line = M.config.highlighter.current_line - 1

    if M.config.highlighter.current_line < 0 then
        M.config.highlighter.current_line = total_lines - 1
    end

    if M.config.highlighter.current_line >= 0 then
        vim.api.nvim_win_set_cursor(win_id, {M.config.highlighter.current_line + 1, 0})
    end

    M:highlight_line(buf_id)
    M.set_command_line(buf_id, M.config.highlighter.current_line)
end

function M:reset_highlight()
    M.config.highlighter.current_line = -1
end

return M
