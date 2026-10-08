local ui = require("wild.ui")
local fzy = require("wild.fzy")
local cmd = require("wild.cmd")
local history = require("wild.history")
local config = require("wild.config")
local highlights = require("wild.highlights")

local M = {}

local state = {
    win_id = nil,
    buf_id = nil,
    history = {},
    commands = {},
    help_tags = nil,
    candidates = {},
    match_count = 0,
    matches = {},
    selected = nil,
    prefix = "",
}

local function load_history()
    state.history = history.read(history.path)
    state.commands = cmd.get_commands(state.history, os.time())
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

local function handle_cmdline_enter()
    if vim.fn.getcmdtype() ~= ":" then
        return
    end

    local buf_data = state.commands

    -- Deferred enters from back-to-back command lines (e.g. a mapping like
    -- `:w<CR>:echo<CR>`) can all run in the last one; replace, don't stack.
    ui.close_window(state.win_id, state.buf_id)

    state.win_id, state.buf_id = ui.create_window(#buf_data)
    state.match_count = #buf_data
    state.matches = {}
    state.selected = nil
    state.prefix = ""
    state.candidates = {}

    ui.set_buffer_contents(state.buf_id, buf_data)
    ui.redraw()
end

local function handle_cmdline_leave()
    if vim.fn.getcmdtype() == ":" and not vim.v.event.abort then
        local line = vim.trim(vim.fn.getcmdline())
        local name = cmd.command_name(line)

        if name and name ~= "" then
            local now = os.time()
            state.history = history.record(history.path, line, now)
            state.commands = cmd.get_commands(state.history, now)
        end
    end

    ui.close_window(state.win_id, state.buf_id)
    state.match_count = 0
    state.matches = {}
    state.selected = nil
end

local function handle_cmdline_changed()
    if vim.fn.getcmdtype() ~= ":" then
        return
    end

    local line = vim.fn.getcmdline()
    local context = cmd.completion_context(line, vim.fn.getcmdcomplpat(), vim.fn.getcmdcompltype())
    local needle, items, prefix = line, state.commands, ""

    if context then
        local arguments = cmd.get_arguments(context.prefix, get_candidates(context), state.history)

        if #arguments > 0 then
            needle, items, prefix = context.needle, arguments, context.prefix
        end
    end

    local matches = fzy.find_matches(needle, items)

    ui.update_buffer_contents(state.win_id, state.buf_id, matches)
    state.matches = matches
    ui.clear_selection(state.win_id)
    state.match_count = #matches
    state.selected = nil
    state.prefix = prefix

    ui.redraw()
end

local function select(offset)
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
    ui.set_command_line(state.buf_id, state.selected, state.prefix)
    ui.redraw()
end

local function handle_vim_resized()
    if vim.fn.mode() == "c" then
        vim.defer_fn(function()
            ui.resize_window(state.win_id, state.buf_id)
            ui.redraw()
        end, 100)
    end
end

local function setup_global_autocmd()
    local group = vim.api.nvim_create_augroup("wild", { clear = true })
    local autocmd = vim.api.nvim_create_autocmd

    local function load_history_later()
        vim.defer_fn(load_history, 100)
    end

    -- When lazy-loaded, setup() can run after VimEnter has already fired.
    if vim.v.vim_did_enter == 1 then
        load_history_later()
    else
        autocmd("VimEnter", { callback = load_history_later, group = group })
    end

    autocmd("CmdlineEnter", {
        callback = function()
            vim.defer_fn(function()
                handle_cmdline_enter()
            end, 10)
        end,
        group = group,
    })

    autocmd("CmdlineLeave", {
        callback = function()
            handle_cmdline_leave()
        end,
        group = group,
    })

    local changed_timer = vim.uv.new_timer()

    autocmd("CmdlineChanged", {
        callback = function()
            changed_timer:stop()
            changed_timer:start(10, 0, vim.schedule_wrap(handle_cmdline_changed))
        end,
        group = group,
    })

    autocmd("ColorScheme", { callback = highlights.setup, group = group })

    autocmd("VimResized", {
        callback = function()
            handle_vim_resized()
        end,
        group = group,
    })
end

-- Selects from the wild window when it is open; otherwise sends the key on
-- as if typed, so builtin completion still works in /, ?, input(), etc.
local function select_or_fallback(key, offset)
    return function()
        if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
            select(offset)
        else
            local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
            vim.api.nvim_feedkeys(keys, "nti", false)
        end
    end
end

local function setup_keymaps()
    local next_key = config.options.keymaps.next_key
    local previous_key = config.options.keymaps.previous_key

    vim.keymap.set("c", next_key, select_or_fallback(next_key, 1), { desc = "wild: select next" })
    vim.keymap.set("c", previous_key, select_or_fallback(previous_key, -1), { desc = "wild: select previous" })
end

local function disable_cmdwin()
    vim.keymap.set("c", "<C-f>", "<Nop>", { desc = "wild: cmdwin disabled" })
    vim.keymap.set("n", "q:", "<Nop>", { desc = "wild: cmdwin disabled" })
    vim.keymap.set("n", "q/", "<Nop>", { desc = "wild: cmdwin disabled" })
    vim.keymap.set("n", "q?", "<Nop>", { desc = "wild: cmdwin disabled" })
end

local function reset_history()
    os.remove(history.path)
    load_history()
    vim.notify("wild.nvim: command history reset")
end

local function setup_user_commands()
    vim.api.nvim_create_user_command("WildResetHistory", reset_history, { desc = "Reset wild.nvim command history" })
end

function M.setup(opts)
    config.setup(opts)
    highlights.setup()

    if config.options.disable_cmdwin then
        disable_cmdwin()
    end

    setup_global_autocmd()
    setup_keymaps()
    setup_user_commands()
end

return M
