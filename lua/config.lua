local M = {}

M.defaults = {
    window = {
        width = 30,
        height = 10,
        border = "rounded",
        opacity = 15
    },
    highlights = {
        character_color = "#ff8800",
        line_color = "#ff8800",
    }
}

M.options = {}

function M.setup(options)
    M.options = vim.tbl_deep_extend('force', {}, M.defaults, options or {})
end

return M
