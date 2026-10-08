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

local function border_size()
    local border = config.options.window.border

    if border == "none" or (type(border) == "table" and #border == 0) then
        return 0
    end

    return 2
end

local function counter_text(selected, total)
    if selected then
        return string.format(" %d/%d ", selected + 1, total)
    end

    return string.format(" %d ", total)
end

function M.get_layout(lines, fixed_width)
    local window = config.options.window
    local border = border_size()
    local height = math.max(math.min(#lines, window.height), 1)
    local width = fixed_width or window.width

    if width == "auto" then
        width = 1

        for _, line in ipairs(lines) do
            width = math.max(width, vim.api.nvim_strwidth(line))
        end

        if window.counter then
            width = math.max(width, #counter_text(#lines - 1, #lines))
        end

        width = math.min(width, window.max_width)
    end

    width = math.max(math.min(width, vim.o.columns - border), 1)

    local row = vim.o.lines - height - border - vim.o.cmdheight - 1

    return { relative = "editor", width = width, height = height, row = math.max(row, 0), col = 0 }
end

local function apply_layout(win_id, buf_id, fixed_width)
    local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
    vim.api.nvim_win_set_config(win_id, M.get_layout(lines, fixed_width))
end

function M.create_window(lines, fixed_width)
    local buf_id = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)

    local win_config = M.get_layout(lines, fixed_width)
    win_config.style = "minimal"
    win_config.border = config.options.window.border
    win_config.zindex = 250

    local win_id = vim.api.nvim_open_win(buf_id, false, win_config)

    vim.api.nvim_set_option_value(
        "winhighlight",
        "Normal:WildNormal,FloatBorder:WildBorder,FloatFooter:WildBorder,CursorLine:WildSelection",
        { win = win_id }
    )
    vim.api.nvim_set_option_value("winblend", config.options.window.opacity, { win = win_id, scope = "local" })

    return win_id, buf_id
end

function M.set_counter(win_id, selected, total)
    if not config.options.window.counter or not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    vim.api.nvim_win_set_config(win_id, { footer = counter_text(selected, total), footer_pos = "right" })
end

function M.close_window(win_id, buf_id)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
    end

    if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        vim.api.nvim_buf_delete(buf_id, { force = true })
    end
end

function M.resize_window(win_id, buf_id, fixed_width)
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        apply_layout(win_id, buf_id, fixed_width)
    end
end

function M.redraw()
    vim.cmd([[redraw]])
end

function M.update_buffer_contents(win_id, buf_id, data, empty_text, fixed_width)
    if invalid_buffer(buf_id) then
        return
    end

    local results = { empty_text or "No Results" }

    if #data ~= 0 then
        results = vim.tbl_map(function(d)
            return d[1]
        end, data)
    end

    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, results)
    apply_layout(win_id, buf_id, fixed_width)
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
