local ui = require("ui")
local fzy = require("fzy")
local cmd = require("cmd")

local Wild = {
    binds = {
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
    }
}

function Wild:setup()
    local group = vim.api.nvim_create_augroup("wild", { clear = true })

    cmd:from_file()

    vim.api.nvim_create_autocmd('VimEnter', {
        callback = function()
            vim.defer_fn(function()
                cmd:get_commands()
                cmd:get_help_tags()
            end, 100)
        end, group = group })

    vim.api.nvim_create_autocmd("CmdlineEnter", {
        callback = function()
            if vim.fn.getcmdtype() == ":" then
                ui:create_window()
                ui.redraw()
            end
        end, group = group })

    vim.api.nvim_create_autocmd("CmdlineLeave", {
        callback = function()
            cmd:set_history()
            ui:close_window()
        end, group = group })

    vim.api.nvim_create_autocmd("CmdlineChanged", {
        callback = function()
            if vim.fn.getcmdtype() == ":" then
                local input = vim.fn.getcmdline()

                matches = fzy.find_matches(input)

                ui:update_buffer_contents(matches)
                ui.redraw()
            end
        end, group = group })

    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if vim.fn.mode() == "c" then
                vim.defer_fn(function()
                    ui:resize_window()
                    ui.redraw()
                end, 100)
            end
        end, group = group })

    vim.api.nvim_create_autocmd("VimLeave", {
        pattern = "*",
        callback = function()
            cmd:to_file()
        end, group = group })

    vim.api.nvim_create_user_command("WildNext", function() ui:highlight_next_line() end, {desc = "Next Command" })
    vim.api.nvim_create_user_command("WildPrevious", function() ui:highlight_previous_line() end, {desc = "Previous Command" })
    vim.api.nvim_set_keymap('c', self.binds.next_key, "<Cmd>WildNext<CR>", { noremap = true })
    vim.api.nvim_set_keymap('c', self.binds.previous_key, "<Cmd>WildPrevious<CR>", { noremap = true })
    vim.api.nvim_set_keymap('c', self.binds.previous_key, "<Cmd>WildPrevious<CR>", { noremap = true })

    -- disables builtin neovim command history
    vim.api.nvim_set_keymap('c', '<C-f>', '<Nop>', { noremap = true, silent = true })

end

return Wild
