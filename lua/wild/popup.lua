local ui = require("wild.ui")
local fzy = require("wild.fzy")
local cmd = require("wild.cmd")
local history = require("wild.history")
local config = require("wild.config")

local M = {}

local state = {
    win_id = nil,
    buf_id = nil,
    history = {},
    commands = {},
    search_history = {},
    searches = {},
    help_tags = nil,
    candidates = {},
    match_count = 0,
    matches = {},
    selected = nil,
    prefix = "",
    fixed_width = nil,
}

function M.load_history()
    local now = os.time()

    state.history = history.read(history.path)
    state.commands = cmd.get_commands(state.history, now)
    state.search_history = history.read(history.search_path)
    state.searches = history.lines(state.search_history, now)
end

local function is_search(cmdtype)
    return (cmdtype == "/" or cmdtype == "?") and config.options.search
end

local function get_candidates(context)
    if context.type == "help" then
        state.help_tags = state.help_tags or cmd.get_help_tags()
        return state.help_tags
    end

    if not state.candidates[context.query] then
        state.candidates[context.query] = vim.fn.getcompletion(context.query, "cmdline")
    end

    return state.candidates[context.query]
end

function M.handle_cmdline_enter()
    local cmdtype = vim.fn.getcmdtype()
    local buf_data

    if cmdtype == ":" then
        buf_data = state.commands
        state.fixed_width = nil
    elseif is_search(cmdtype) then
        buf_data = state.searches
        state.fixed_width = ui.get_layout(state.commands).width
    else
        return
    end

    -- Deferred enters from back-to-back command lines (e.g. a mapping like
    -- `:w<CR>:echo<CR>`) can all run in the last one; replace, don't stack.
    ui.close_window(state.win_id, state.buf_id)

    state.win_id, state.buf_id = ui.create_window(#buf_data > 0 and buf_data or { "No History" }, state.fixed_width)
    state.match_count = #buf_data
    state.matches = {}
    state.selected = nil
    state.prefix = ""
    state.candidates = {}

    ui.set_counter(state.win_id, nil, #buf_data)
    ui.redraw()
end

function M.handle_cmdline_leave()
    local cmdtype = vim.fn.getcmdtype()

    if cmdtype == ":" and not vim.v.event.abort then
        local line = vim.trim(vim.fn.getcmdline())
        local name = cmd.command_name(line)

        if name and name ~= "" then
            local now = os.time()
            state.history = history.record(history.path, line, now)
            state.commands = cmd.get_commands(state.history, now)
        end
    elseif is_search(cmdtype) and not vim.v.event.abort then
        local line = vim.fn.getcmdline()

        if line ~= "" then
            local now = os.time()
            state.search_history = history.record(history.search_path, line, now)
            state.searches = history.lines(state.search_history, now)
        end
    end

    ui.close_window(state.win_id, state.buf_id)
    state.match_count = 0
    state.matches = {}
    state.selected = nil
end

function M.handle_cmdline_changed()
    if not M.is_open() then
        return
    end

    local cmdtype = vim.fn.getcmdtype()
    local line = vim.fn.getcmdline()
    local needle, items, prefix = line, state.commands, ""
    local empty_text, context

    if cmdtype == ":" then
        context = cmd.completion_context(line, vim.fn.getcmdcomplpat(), vim.fn.getcmdcompltype())
    elseif is_search(cmdtype) then
        items = state.searches
        empty_text = #items == 0 and "No History" or nil
    else
        return
    end

    if context then
        local arguments = cmd.get_arguments(context.prefix, get_candidates(context), state.history)

        if #arguments > 0 then
            needle, items, prefix = context.needle, arguments, context.prefix
        end
    end

    local matches = fzy.find_matches(needle, items)

    ui.update_buffer_contents(state.win_id, state.buf_id, matches, empty_text, state.fixed_width)
    ui.set_counter(state.win_id, nil, #matches)
    state.matches = matches
    ui.clear_selection(state.win_id)
    state.match_count = #matches
    state.selected = nil
    state.prefix = prefix

    ui.redraw()
end

function M.select(offset)
    if state.match_count == 0 then
        return
    end

    if state.selected == nil then
        state.selected = 0
    else
        state.selected = (state.selected + offset) % state.match_count
    end

    ui.select_line(state.win_id, state.selected)
    ui.highlight_chars(state.win_id, state.buf_id, state.matches)
    ui.set_counter(state.win_id, state.selected, state.match_count)
    ui.set_command_line(state.buf_id, state.selected, state.prefix)
    ui.redraw()
end

function M.handle_vim_resized()
    if vim.fn.mode() == "c" then
        vim.defer_fn(function()
            ui.resize_window(state.win_id, state.buf_id, state.fixed_width)
            ui.redraw()
        end, 100)
    end
end

function M.is_open()
    return state.win_id ~= nil and vim.api.nvim_win_is_valid(state.win_id)
end

function M.reset_history()
    os.remove(history.path)
    os.remove(history.search_path)
    M.load_history()
end

return M
