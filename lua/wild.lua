local ui = require("ui")
local autocmd = require("autocmd")

local Wild = {
    binds = {
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
    }
}

function Wild:setup()
    autocmd:init()

    vim.api.nvim_create_user_command("WildNext", function() ui:highlight_next_line() end, {desc = "Next Command" })
    vim.api.nvim_create_user_command("WildPrevious", function() ui:highlight_previous_line() end, {desc = "Previous Command" })
    vim.api.nvim_set_keymap('c', self.binds.next_key, "<Cmd>WildNext<CR>", { noremap = true })
    vim.api.nvim_set_keymap('c', self.binds.previous_key, "<Cmd>WildPrevious<CR>", { noremap = true })

    -- vim.api.nvim_create_user_command("WildResetHistory", function() cmd:resethistory() end, {desc = "Resets command history" })

    -- disables builtin neovim command history
    vim.api.nvim_set_keymap('c', '<C-f>', '<Nop>', { noremap = true, silent = true })
end

return Wild
