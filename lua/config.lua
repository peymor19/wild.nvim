local M = {}

local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
local border_hl = vim.api.nvim_get_hl(0, { name = "FloatBorder" })

M.defaults = {
    window = {
        width = 30,
        height = 10,
        border = "rounded",
        opacity = 0,
        background_hl = normal_hl,
        border_hl = border_hl
    },
    highlights = {
        line_color = "#FFA500",
        character_color = "#6495ED"
    },
    keymaps = {
        next_key = "<Tab>",
        previous_key = "<S-Tab>"
    }
}

M.options = {}

function M.setup(options)
    M.options = vim.tbl_deep_extend('force', {}, M.defaults, options or {})
end

return M
