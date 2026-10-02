local ui = require("ui")
local fzy = require("fzy")
local cmd = require("cmd")
local config = require("config")

local M = {}

M.state = {
    win_id = nil,
    buf_id = nil,
    searchables = {}
}

local file_path = vim.fn.stdpath('data') .. '/command_history.json'

local function get_searchables()
    local commands_from_file = cmd.from_file(file_path)
    return cmd.get_searchables(commands_from_file)
end

local function handle_cmdline_enter(state)
    if vim.fn.getcmdtype() ~= ":" then return state end

    local buf_data = ui.get_buf_data("commands", state.searchables)

    -- Deferred enters from back-to-back command lines (e.g. a mapping like
    -- `:w<CR>:echo<CR>`) can all run in the last one; replace, don't stack.
    ui.close_window(state.win_id, state.buf_id)

    state.win_id, state.buf_id = ui.create_window(#buf_data)

    ui.set_buffer_contents(state.buf_id, buf_data)
    ui.redraw()

    return state
end

local function handle_cmdline_leave(state)
    if vim.fn.getcmdtype() == ":" and not vim.v.event.abort then
        local command = cmd.command_name(vim.fn.getcmdline())
        local updated_commands = cmd.inc_command(command, state.searchables.commands)

        cmd.to_file(file_path, updated_commands)
        state.searchables.commands = updated_commands
    end

    ui.close_window(state.win_id, state.buf_id)

    return state
end

local function handle_cmdline_changed(state)
    if vim.fn.getcmdtype() ~= ":" then return state end

    local input, searchable_type = cmd.searchable_type_from_input(vim.fn.getcmdline())

    local buf_data = ui.get_buf_data(searchable_type, state.searchables)
    local matches = fzy.find_matches(input, buf_data)

    ui.update_buffer_contents(state.win_id, state.buf_id, matches)
    ui.redraw()

    return state
end

local function handle_vim_resized(state)
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

    local function load_searchables()
        vim.defer_fn(function()
            M.state.searchables = get_searchables()
        end, 100)
    end

    -- When lazy-loaded, setup() can run after VimEnter has already fired.
    if vim.v.vim_did_enter == 1 then
        load_searchables()
    else
        autocmd('VimEnter', { callback = load_searchables, group = group })
    end

    autocmd("CmdlineEnter", { callback = function()
        vim.defer_fn(function()
            M.state = handle_cmdline_enter(M.state)
        end, 10)
    end, group = group })

    autocmd("CmdlineLeave", { callback = function()
        M.state = handle_cmdline_leave(M.state)
    end, group = group })

    autocmd("CmdlineChanged", { callback = function()
        vim.defer_fn(function()
            M.state = handle_cmdline_changed(M.state)
        end, 10)
    end, group = group })

    autocmd("VimResized", { callback = function()
        handle_vim_resized(M.state)
    end, group = group })
end

-- Selects from the wild window when it is open; otherwise sends the key on
-- as if typed, so builtin completion still works in /, ?, input(), etc.
local function select_or_fallback(key, offset)
    return function()
        if M.state.win_id and vim.api.nvim_win_is_valid(M.state.win_id) then
            ui.select_command(M.state.win_id, M.state.buf_id, offset)
        else
            local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
            vim.api.nvim_feedkeys(keys, "nti", false)
        end
    end
end

local function setup_keymaps()
    local next_key = config.options.keymaps.next_key
    local previous_key = config.options.keymaps.previous_key

    vim.api.nvim_set_keymap('c', next_key, "", { callback = select_or_fallback(next_key, 1), noremap = true })
    vim.api.nvim_set_keymap('c', previous_key, "", { callback = select_or_fallback(previous_key, -1), noremap = true })
    -- vim.api.nvim_create_user_command("WildResetHistory", function() cmd:resethistory() end, {desc = "Resets command history" })
end

local function disable_nvim_builtin_cmd_history()
    vim.api.nvim_set_keymap('c', '<C-f>', '<Nop>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', 'q:', '<Nop>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', 'q/', '<Nop>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', 'q?', '<Nop>', { noremap = true, silent = true })
end

function M.setup(opts)
    config.setup(opts)

    disable_nvim_builtin_cmd_history()
    setup_global_autocmd()
    setup_keymaps()
end

return M
