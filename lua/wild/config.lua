local M = {}

M.defaults = {
    window = {
        width = 30,
        height = 10,
        border = "rounded",
        opacity = 0,
        background_hl = nil,
        border_hl = nil,
    },
    highlights = {
        line_color = "#FFA500",
        character_color = "#6495ED",
    },
    keymaps = {
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
    },
    disable_cmdwin = true,
}

M.options = {}

function M.validate(options)
    vim.validate("window", options.window, "table")
    vim.validate("highlights", options.highlights, "table")
    vim.validate("keymaps", options.keymaps, "table")

    local window, highlights, keymaps = options.window, options.highlights, options.keymaps

    vim.validate("window.width", window.width, "number")
    vim.validate("window.height", window.height, "number")
    vim.validate("window.border", window.border, { "string", "table" })
    vim.validate("window.opacity", window.opacity, "number")
    vim.validate("window.background_hl", window.background_hl, "table", true)
    vim.validate("window.border_hl", window.border_hl, "table", true)
    vim.validate("highlights.line_color", highlights.line_color, "string")
    vim.validate("highlights.character_color", highlights.character_color, "string")
    vim.validate("keymaps.next_key", keymaps.next_key, "string")
    vim.validate("keymaps.previous_key", keymaps.previous_key, "string")
    vim.validate("disable_cmdwin", options.disable_cmdwin, "boolean")
end

function M.setup(options)
    M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
    M.validate(M.options)
end

return M
