local ui = require("wild.ui")
local fzy = require("wild.fzy")
local cmd = require("wild.cmd")
local config = require("wild.config")
local highlights = require("wild.highlights")

local M = {}

local state = {
    win_id = nil,
    buf_id = nil,
    searchables = {},
    match_count = 0,
    selected = nil,
    prefix = "",
}

local file_path = cmd.history_path

local function get_searchables()
    local commands_from_file = cmd.from_file(file_path)
    return cmd.get_searchables(commands_from_file)
end

local function handle_cmdline_enter()
    if vim.fn.getcmdtype() ~= ":" then
        return
    end

    local buf_data = ui.get_buf_data("commands", state.searchables)

    -- Deferred enters from back-to-back command lines (e.g. a mapping like
    -- `:w<CR>:echo<CR>`) can all run in the last one; replace, don't stack.
    ui.close_window(state.win_id, state.buf_id)

    state.win_id, state.buf_id = ui.create_window(#buf_data)
    state.match_count = #buf_data
    state.selected = nil
    state.prefix = ""

    ui.set_buffer_contents(state.buf_id, buf_data)
    ui.redraw()
end

local function handle_cmdline_leave()
    if vim.fn.getcmdtype() == ":" and not vim.v.event.abort then
        local command = cmd.command_name(vim.fn.getcmdline())
        local updated_commands = cmd.inc_command(command, state.searchables.commands)

        cmd.to_file(file_path, updated_commands)
        state.searchables.commands = updated_commands
    end

    ui.close_window(state.win_id, state.buf_id)
    state.match_count = 0
    state.selected = nil
end

local function handle_cmdline_changed()
    if vim.fn.getcmdtype() ~= ":" then
        return
    end

    local input, searchable_type, prefix = cmd.searchable_type_from_input(vim.fn.getcmdline())

    local buf_data = ui.get_buf_data(searchable_type, state.searchables)
    local matches = fzy.find_matches(input, buf_data)

    ui.update_buffer_contents(state.win_id, state.buf_id, matches)
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

    local function load_searchables()
        vim.defer_fn(function()
            state.searchables = get_searchables()
        end, 100)
    end

    -- When lazy-loaded, setup() can run after VimEnter has already fired.
    if vim.v.vim_did_enter == 1 then
        load_searchables()
    else
        autocmd("VimEnter", { callback = load_searchables, group = group })
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

    autocmd("CmdlineChanged", {
        callback = function()
            vim.defer_fn(function()
                handle_cmdline_changed()
            end, 10)
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
    os.remove(file_path)
    state.searchables = get_searchables()
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
