local config = require("wild.config")

local M = {}

local chars_ns_id = vim.api.nvim_create_namespace("wild_highlight_characters")

local function invalid_buffer(buf_id)
    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        return false
    else
        return true
    end
end

local function get_height(buf_line_count)
    return math.max(math.min(buf_line_count, config.options.window.height), 1)
end

local function get_row(height)
    local ui = vim.api.nvim_list_uis()[1]

    if ui == nil then
        return 0
    end

    return math.max(ui.height - height - 4, 0)
end

local function reset_window_height(win_id, buf_line_count)
    local win_config = vim.api.nvim_win_get_config(win_id)

    win_config.height = get_height(buf_line_count)
    win_config.row = get_row(win_config.height)

    vim.api.nvim_win_set_config(win_id, win_config)
end

function M.create_window(buf_line_count)
    local height = get_height(buf_line_count)

    local buf_id = vim.api.nvim_create_buf(false, true)
    local win_id = vim.api.nvim_open_win(buf_id, false, {
        relative = "editor",
        style = "minimal",
        width = config.options.window.width,
        height = height,
        row = get_row(height),
        col = 0,
        border = config.options.window.border,
        zindex = 250,
    })

    vim.api.nvim_set_option_value(
        "winhighlight",
        "Normal:WildNormal,FloatBorder:WildBorder,CursorLine:WildSelection",
        { win = win_id }
    )
    vim.api.nvim_set_option_value("winblend", config.options.window.opacity, { win = win_id, scope = "local" })

    return win_id, buf_id
end

function M.set_buffer_contents(buf_id, buf_data)
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, buf_data)
end

function M.close_window(win_id, buf_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
    end

    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        vim.api.nvim_buf_delete(buf_id, { force = true })
    end
end

function M.resize_window(win_id, buf_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        local buf_line_count = vim.api.nvim_buf_line_count(buf_id)
        reset_window_height(win_id, buf_line_count)
    end
end

function M.redraw()
    vim.cmd([[redraw]])
end

function M.update_buffer_contents(win_id, buf_id, data)
    if invalid_buffer(buf_id) then
        return
    end

    reset_window_height(win_id, #data)

    local results = { "No Results" }

    if #data ~= 0 then
        results = vim.tbl_map(function(d)
            return d[1]
        end, data)
    end

    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, results)
    vim.api.nvim_win_set_cursor(win_id, { 1, 0 })
    M.highlight_chars(win_id, buf_id, data)
end

local function visible_range(win_id)
    return unpack(vim.api.nvim_win_call(win_id, function()
        return { vim.fn.line("w0"), vim.fn.line("w$") }
    end))
end

function M.highlight_chars(win_id, buf_id, data)
    vim.api.nvim_buf_clear_namespace(buf_id, chars_ns_id, 0, -1)

    if not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local first, last = visible_range(win_id)

    for line_idx = first, math.min(last, #data) do
        local str, positions = data[line_idx][1], data[line_idx][2]
        for _, pos in ipairs(positions) do
            local char = str:sub(pos, pos)
            vim.api.nvim_buf_set_extmark(buf_id, chars_ns_id, line_idx - 1, pos - 1, {
                virt_text = { { char, "WildMatch" } },
                virt_text_pos = "overlay",
                hl_mode = "combine",
                priority = 99,
            })
        end
    end
end

function M.set_command_line(buf_id, line_number, prefix)
    local command = vim.api.nvim_buf_get_lines(buf_id, line_number, line_number + 1, false)[1]
    local eventignore = vim.o.eventignore

    vim.opt.eventignore:append("CmdlineChanged")
    vim.fn.setcmdline(prefix .. command)
    vim.o.eventignore = eventignore
end

function M.select_line(win_id, line_number)
    vim.api.nvim_set_option_value("cursorline", true, { win = win_id })
    vim.api.nvim_win_set_cursor(win_id, { line_number + 1, 0 })
end

function M.clear_selection(win_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_set_option_value("cursorline", false, { win = win_id })
    end
end

return M
