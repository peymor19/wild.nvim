local ui = require("ui")
local fzy = require("fzy")
local cmd = require("cmd")

local M = {}

M.config = {
    binds = {
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
    }
}

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

    ui.set_config(#buf_data)

    state.win_id, state.buf_id = ui.create_window(buf_data)

    ui.set_buffer_contents(buf_id, buf_data)
    ui.redraw()

    return state
end

local function handle_cmdline_leave(state)
    if vim.fn.getcmdtype() == ":" then
        local command = vim.fn.getcmdline()
        local updated_commands = cmd.inc_command(command, state.searchables.commands)

        cmd.to_file(file_path, updated_commands)
        state.searchables.commands = updated_commands
    end

    ui.close_window(state.win_id, state.buf_id)

    return state
end

local function handle_cmdline_changed(state)
    if vim.fn.getcmdtype() ~= ":" then return state end

    local input, searchable_type = cmd.searchable_type_from_input(input)

    local buf_data = ui.get_buf_data(searchable_type, state.searchables)
    local matches = fzy.find_matches(input, buf_data)

    ui.update_buffer_contents(state.win_id, state.buf_id, matches)
    ui.redraw()

    return state
end

local function handle_vim_resized(win_id)
    if vim.fn.mode() == "c" then
        vim.defer_fn(function()
            ui.resize_window(win_id)
            ui.redraw()
        end, 100)
    end
end

local function setup_global_autocmd()
    local group = vim.api.nvim_create_augroup("wild", { clear = true })
    local autocmd = vim.api.nvim_create_autocmd

    autocmd('VimEnter', { callback = function()
        vim.defer_fn(function()
            M.state.searchables = get_searchables()
        end, 100)
    end, group = group })

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
        handle_vim_resized(M.state.win_id)
    end, group = group })
end

local function setup_keymaps()
    vim.api.nvim_create_user_command("WildNext", function() ui:highlight_next_line(M.state.win_id, M.state.buf_id) end, {desc = "Next Command" })
    vim.api.nvim_create_user_command("WildPrevious", function() ui:highlight_previous_line(M.state.win_id, M.state.buf_id) end, {desc = "Previous Command" })
    vim.api.nvim_set_keymap('c', M.config.binds.next_key, "<Cmd>WildNext<CR>", { noremap = true })
    vim.api.nvim_set_keymap('c', M.config.binds.previous_key, "<Cmd>WildPrevious<CR>", { noremap = true })

    -- vim.api.nvim_create_user_command("WildResetHistory", function() cmd:resethistory() end, {desc = "Resets command history" })
end

local function disable_nvim_builtin_cmd_history()
    vim.api.nvim_set_keymap('c', '<C-f>', '<Nop>', { noremap = true, silent = true })
end

function M:setup()
    disable_nvim_builtin_cmd_history()
    setup_global_autocmd()
    setup_keymaps()
end

return M
