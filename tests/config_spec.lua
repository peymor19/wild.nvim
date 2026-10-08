local config = require("wild.config")

describe("config.setup", function()
    it("should use the defaults when no options are given", function()
        config.setup()

        assert.are.same(config.defaults, config.options)
    end)

    it("should merge user options over the defaults", function()
        config.setup({ window = { width = 50 }, disable_cmdwin = false })

        assert.is_equal(50, config.options.window.width)
        assert.is_equal(10, config.options.window.height)
        assert.is_false(config.options.disable_cmdwin)
    end)

    it("should accept a border given as a table", function()
        config.setup({ window = { border = { "+", "-", "+", "|", "+", "-", "+", "|" } } })

        assert.is_equal("table", type(config.options.window.border))
    end)

    it("should error on an option with the wrong type", function()
        local ok, err = pcall(config.setup, { window = { width = "wide" } })

        assert.is_false(ok)
        assert.matches("window.width", err)
    end)

    it("should error when a section is not a table", function()
        local ok, err = pcall(config.setup, { keymaps = "<Tab>" })

        assert.is_false(ok)
        assert.matches("keymaps", err)
    end)

    it("should error when disable_cmdwin is not a boolean", function()
        local ok, err = pcall(config.setup, { disable_cmdwin = "yes" })

        assert.is_false(ok)
        assert.matches("disable_cmdwin", err)
    end)
end)
