---@class wild.WindowConfig
---@field width? integer Popup width in columns
---@field height? integer Maximum number of visible rows
---@field border? any[]|"none"|"single"|"double"|"rounded"|"solid"|"shadow"
---@field opacity? integer Transparency from 0 (opaque) to 100, see 'winblend'
---@field background_hl? vim.api.keyset.highlight Overrides the WildNormal group
---@field border_hl? vim.api.keyset.highlight Overrides the WildBorder group

---@class wild.HighlightsConfig
---@field line_color? string Color of the selected line (WildSelection)
---@field character_color? string Color of matched characters (WildMatch)

---@class wild.KeymapsConfig
---@field next_key? string Selects the next match
---@field previous_key? string Selects the previous match

---@class wild.Config
---@field window? wild.WindowConfig
---@field highlights? wild.HighlightsConfig
---@field keymaps? wild.KeymapsConfig
---@field disable_cmdwin? boolean Disable q:, q/, q? and <C-f>

local M = {}

---@type wild.Config
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

---@type wild.Config
M.options = {}

---@param options wild.Config
function M.validate(options)
    vim.validate("window", options.window, "table")
    vim.validate("highlights", options.highlights, "table")
    vim.validate("keymaps", options.keymaps, "table")

    local window = options.window --[[@as wild.WindowConfig]]
    local highlights = options.highlights --[[@as wild.HighlightsConfig]]
    local keymaps = options.keymaps --[[@as wild.KeymapsConfig]]

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

---@param options? wild.Config
function M.setup(options)
    M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
    M.validate(M.options)
end

return M
