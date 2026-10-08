local popup = require("wild.popup")
local config = require("wild.config")
local highlights = require("wild.highlights")

local M = {}

local function setup_global_autocmd()
    local group = vim.api.nvim_create_augroup("wild", { clear = true })
    local autocmd = vim.api.nvim_create_autocmd

    local function load_history_later()
        vim.defer_fn(popup.load_history, 100)
    end

    -- When lazy-loaded, setup() can run after VimEnter has already fired.
    if vim.v.vim_did_enter == 1 then
        load_history_later()
    else
        autocmd("VimEnter", { callback = load_history_later, group = group })
    end

    autocmd("CmdlineEnter", {
        callback = function()
            vim.defer_fn(popup.handle_cmdline_enter, 10)
        end,
        group = group,
    })

    autocmd("CmdlineLeave", {
        callback = function()
            popup.handle_cmdline_leave()
        end,
        group = group,
    })

    local changed_timer = vim.uv.new_timer()

    autocmd("CmdlineChanged", {
        callback = function()
            changed_timer:stop()
            changed_timer:start(10, 0, vim.schedule_wrap(popup.handle_cmdline_changed))
        end,
        group = group,
    })

    autocmd("ColorScheme", { callback = highlights.setup, group = group })

    autocmd("VimResized", {
        callback = function()
            popup.handle_vim_resized()
        end,
        group = group,
    })
end

-- Selects from the wild window when it is open; otherwise sends the key on
-- as if typed, so builtin completion still works in /, ?, input(), etc.
local function select_or_fallback(key, offset)
    return function()
        if popup.is_open() then
            popup.select(offset)
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
    popup.reset_history()
    vim.notify("wild.nvim: command and search history reset")
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
