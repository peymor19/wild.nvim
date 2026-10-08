local config = require("wild.config")
local highlights = require("wild.highlights")

local groups = { "WildNormal", "WildBorder", "WildMatch", "WildSelection" }

local function get_hl(name)
    return vim.api.nvim_get_hl(0, { name = name })
end

describe("highlights.setup", function()
    before_each(function()
        for _, name in ipairs(groups) do
            -- nvim_set_hl(0, name, {}) leaves a former link "defined", which
            -- makes `default = true` a no-op; :highlight clear fully resets it.
            vim.cmd("highlight clear " .. name)
        end
    end)

    it("links the window groups to Normal and FloatBorder by default", function()
        config.setup()
        highlights.setup()

        assert.are.equal("Normal", get_hl("WildNormal").link)
        assert.are.equal("FloatBorder", get_hl("WildBorder").link)
    end)

    it("uses the configured colors for matches and the selected line", function()
        config.setup({ highlights = { character_color = "#112233", line_color = "#445566" } })
        highlights.setup()

        assert.are.equal(0x112233, get_hl("WildMatch").fg)
        assert.are.equal(0x445566, get_hl("WildSelection").fg)
        assert.is_true(get_hl("WildMatch").bold)
    end)

    it("uses background_hl and border_hl overrides when given", function()
        config.setup({ window = { background_hl = { bg = "#000000" }, border_hl = { fg = "#ffffff" } } })
        highlights.setup()

        assert.are.equal(0x000000, get_hl("WildNormal").bg)
        assert.is_nil(get_hl("WildNormal").link)
        assert.are.equal(0xffffff, get_hl("WildBorder").fg)
    end)

    it("does not override a group the user already defined", function()
        vim.api.nvim_set_hl(0, "WildMatch", { fg = "#ff0000" })

        config.setup()
        highlights.setup()

        assert.are.equal(0xff0000, get_hl("WildMatch").fg)
    end)

    it("restores the groups after :highlight clear", function()
        config.setup()
        highlights.setup()

        vim.cmd("highlight clear")
        highlights.setup()

        assert.are.equal("Normal", get_hl("WildNormal").link)
        assert.is_not_nil(get_hl("WildMatch").fg)
    end)
end)
