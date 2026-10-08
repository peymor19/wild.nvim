local config = require("wild.config")

local M = {}

local function set_default(name, attrs)
    vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", attrs, { default = true }))
end

function M.setup()
    local window = config.options.window
    local highlights = config.options.highlights

    set_default("WildNormal", window.background_hl or { link = "Normal" })
    set_default("WildBorder", window.border_hl or { link = "FloatBorder" })
    set_default("WildMatch", { fg = highlights.character_color, bold = true })
    set_default("WildSelection", { fg = highlights.line_color, bold = true })
end

return M
