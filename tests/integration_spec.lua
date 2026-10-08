local fzy_dir = vim.fn.fnamemodify(os.getenv("FZY_DIR") or "../fzy-lua-native", ":p")

local function wait_for(condition)
    assert.is_true(vim.wait(2000, condition, 10), "timed out waiting for the child nvim")
end

local Child = {}
Child.__index = Child

function Child.start(options)
    local data_dir = vim.fn.tempname()
    local chan = vim.fn.jobstart({
        vim.v.progpath,
        "--embed",
        "--headless",
        "-u",
        "NONE",
        "--cmd",
        "set rtp+=.," .. fzy_dir,
    }, { rpc = true, env = { XDG_DATA_HOME = data_dir } })

    local child = setmetatable({ chan = chan, data_dir = data_dir }, Child)
    child:lua("require('wild').setup(...)", { options or {} })
    wait_for(function()
        return child:lua("return vim.fn.getcompletion('', 'cmdline')")[1] ~= nil
    end)
    vim.wait(150)

    return child
end

function Child:stop()
    vim.fn.jobstop(self.chan)
    vim.fn.delete(self.data_dir, "rf")
end

function Child:lua(code, args)
    return vim.rpcrequest(self.chan, "nvim_exec_lua", code, args or {})
end

function Child:type(keys)
    vim.rpcrequest(self.chan, "nvim_input", keys)
end

function Child:popup()
    local popup = self:lua([[
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local config = vim.api.nvim_win_get_config(win)
            if config.relative ~= "" then
                return {
                    lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false),
                    counter = config.footer and config.footer[1][1],
                }
            end
        end
    ]])

    return popup ~= vim.NIL and popup or nil
end

function Child:cmdline()
    return self:lua("return vim.fn.getcmdline()")
end

function Child:wait_for_popup(condition)
    local popup
    wait_for(function()
        popup = self:popup()
        return popup ~= nil and (condition == nil or condition(popup))
    end)
    return popup
end

function Child:wait_for_cmdline(expected)
    wait_for(function()
        return self:cmdline() == expected
    end)
end

function Child:wait_for_no_popup()
    wait_for(function()
        return self:popup() == nil
    end)
end

local function first_line(expected)
    return function(popup)
        return popup.lines[1] == expected
    end
end

describe("command line", function()
    local child

    after_each(function()
        child:stop()
    end)

    it("should open a popup of commands when : is pressed", function()
        child = Child.start()
        child:type(":")

        local popup = child:wait_for_popup()

        assert.is_true(#popup.lines > 100)
        assert.is_equal(" " .. #popup.lines .. " ", popup.counter)
    end)

    it("should fuzzy filter the commands as you type", function()
        child = Child.start()
        child:type(":wri")

        child:wait_for_popup(first_line("write"))
    end)

    it("should put the selected match on the command line", function()
        child = Child.start()
        child:type(":wri")
        child:wait_for_popup(first_line("write"))

        child:type("<Tab>")

        child:wait_for_cmdline("write")
        assert.matches("^ 1/%d+ $", child:popup().counter)
    end)

    it("should wrap around to the last match with S-Tab", function()
        child = Child.start()
        child:type(":wri")
        local popup = child:wait_for_popup(first_line("write"))

        child:type("<S-Tab>")
        child:wait_for_cmdline(popup.lines[1])
        child:type("<S-Tab>")

        child:wait_for_cmdline(popup.lines[#popup.lines])
    end)

    it("should close the popup when the command line is left", function()
        child = Child.start()
        child:type(":")
        child:wait_for_popup()

        child:type("<Esc>")

        child:wait_for_no_popup()
    end)

    it("should list commands you ran first", function()
        child = Child.start()
        child:type(":echo 'wild'<CR>")
        child:wait_for_no_popup()

        child:type(":")

        child:wait_for_popup(first_line("echo 'wild'"))
    end)

    it("should not save a cancelled command", function()
        child = Child.start()
        child:type(":echo 'wild'<Esc>")
        child:wait_for_no_popup()

        child:type(":")

        local popup = child:wait_for_popup()
        assert.is_false(vim.tbl_contains(popup.lines, "echo 'wild'"))
    end)

    it("should complete arguments", function()
        child = Child.start()
        child:type(":colorscheme blu")
        child:wait_for_popup(first_line("blue"))

        child:type("<Tab>")

        child:wait_for_cmdline("colorscheme blue")
    end)

    it("should complete help tags", function()
        child = Child.start()
        child:type(":h nvim_open_w")

        child:wait_for_popup(first_line("nvim_open_win()"))
    end)
end)

describe("search", function()
    local child

    after_each(function()
        child:stop()
    end)

    it("should show that there is no history before the first search", function()
        child = Child.start()
        child:type("/")

        local popup = child:wait_for_popup(first_line("No History"))
        assert.is_equal(" 0 ", popup.counter)
    end)

    it("should list past searches", function()
        child = Child.start()
        child:type("/wild<CR>")
        child:wait_for_no_popup()

        child:type("?")
        child:wait_for_popup(first_line("wild"))

        child:type("<Tab>")
        child:wait_for_cmdline("wild")
    end)

    it("should not open a popup when search is turned off", function()
        child = Child.start({ search = false })
        child:type("/")
        vim.wait(100)

        assert.is_nil(child:popup())
    end)
end)
