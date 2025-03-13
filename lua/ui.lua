local config = require("config")
local cmd = require("cmd")

local M = {}

M.state = {
    is_results = true,
    current_buf_line = nil,
    highlight_namespace = vim.api.nvim_create_namespace("Highlighter")
}

local function get_height(buf_line_count)
    return math.max(math.min(buf_line_count, config.options.window.height), 1)
end

local function get_row(height)
    local ui = vim.api.nvim_list_uis()[1]

    if ui == nil then return 0 end

    return math.max(ui.height - height - 4, 0)
end

local function reset_window_height(win_id, buf_line_count)
    local config = vim.api.nvim_win_get_config(win_id)

    config.height = get_height(buf_line_count)
    config.row = get_row(config.height)

    vim.api.nvim_win_set_config(win_id, config)
end

function M.create_window(buf_line_count)
    local height = get_height(buf_line_count)

    buf_id = vim.api.nvim_create_buf(false, true)
    win_id = vim.api.nvim_open_win(buf_id, false, {
        relative = 'editor',
        style = 'minimal',
        width = config.options.window.width,
        height = height,
        row = get_row(height),
        col = 0,
        border = config.options.window.border,
        zindex = 250,
    })

    vim.api.nvim_set_option_value("winblend", config.options.window.opacity, { win = win_id, scope = "local" })

    return win_id, buf_id
end

function M.get_buf_data(type, searchables)
    return vim.tbl_map(function(item)
        return item.cmd
    end, searchables[type])
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

    M.reset_highlight()
end

function M.resize_window(win_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        local buf_line_count = vim.api.nvim_buf_line_count(buf_id)
        reset_window_height(win_id, buf_line_count)
    end
end

function M.redraw()
    vim.cmd([[redraw]])
end

function M.update_buffer_contents(win_id, buf_id, data)
    vim.api.nvim_buf_clear_namespace(buf_id, -1, 0, -1)

    if #data == 0 then
        M.state.is_results = false
        data = { { "No Results", {}, 0 } }
    else
        M.state.is_results = true
    end

    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        reset_window_height(win_id, #data)

        local command_string = {}
        for _, item in ipairs(data) do
            table.insert(command_string, item[1]) -- Extract the strings
        end

        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, command_string)

        M.highlight_chars(buf_id, data)
    end
end

function M.highlight_chars(buf_id, data)
    local ns_id = vim.api.nvim_create_namespace("wild.nvim")
    vim.api.nvim_set_hl(0, "hlcolor", { fg = config.options.highlights.character_color })

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

function M.highlight_line(buf_id, line)
    vim.api.nvim_buf_clear_namespace(buf_id, M.state.highlight_namespace, 0, -1)

    local line_content = vim.api.nvim_buf_get_lines(buf_id, line, line + 1, false)[1]

    vim.api.nvim_buf_set_extmark(buf_id, M.state.highlight_namespace, line, 0, {
        virt_text = { { line_content, "Visual" } },
        virt_text_pos = "overlay",
        hl_mode = "combine",
        priority = 100
    })

    M.redraw()
end

function M.select_command(win_id, buf_id, offset)
    local state = M.state

    if not state.is_results then return end

    local total_lines = vim.api.nvim_buf_line_count(buf_id)
    if total_lines == 0 then return end

    if state.current_buf_line == nil then
        state.current_buf_line = 0
    else
        local delta = offset == 1 and 1 or -1
        state.current_buf_line = (state.current_buf_line + delta) % total_lines
    end

    vim.api.nvim_win_set_cursor(win_id, {state.current_buf_line + 1, 0})
    M.highlight_line(buf_id, state.current_buf_line)
    M.set_command_line(buf_id, state.current_buf_line)
end

function M.reset_highlight()
    M.state.current_buf_line = nil
end

return M
