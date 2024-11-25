local ui = require("ui")
local fzy = require("fzy")
local cmd = require("cmd")

local Autocmd = { searchables = {} }

function Autocmd.on_vim_enter()
    searchables = cmd.get_searchables()
    --cmd:get_help_tags()
    return searchables
end

function Autocmd.on_cmdline_enter(searchables)
    if vim.fn.getcmdtype() == ":" then
        buf_data = ui.get_buf_data("commands", searchables)
        ui:create_window(buf_data)
        ui.redraw()
    end
end

function Autocmd.on_cmdline_leave(searchables)
    if vim.fn.getcmdtype() == ":" then
        local command = vim.fn.getcmdline()
        searchables.commands = cmd.inc_command(command, searchables.commands)

        cmd.to_file(searchables.commands)
        ui:close_window()
    end

    return searchables
end

function Autocmd:on_cmdline_changed(searchables)
    if vim.fn.getcmdtype() == ":" then
        local input = vim.fn.getcmdline()
        local buf_data = ui.get_buf_data("commands", searchables)
        local matches = fzy.find_matches(input, buf_data)

        ui:update_buffer_contents(matches)
        ui.redraw()
    end
end

local function on_vim_resized()
    if vim.fn.mode() == "c" then
        vim.defer_fn(function()
            ui:resize_window()
            ui.redraw()
        end, 100)
    end
end

function Autocmd:init()
    local group = vim.api.nvim_create_augroup("wild", { clear = true })
    local autocmd = vim.api.nvim_create_autocmd

    autocmd('VimEnter', { callback = function()
        vim.defer_fn(function() self.searchables = Autocmd.on_vim_enter() end, 100)
    end, group = group })

    autocmd("CmdlineEnter", { callback = function()
        Autocmd.on_cmdline_enter(self.searchables)
    end, group = group })

    autocmd("CmdlineLeave", { callback = function()
        self.searchables = Autocmd.on_cmdline_leave(self.searchables)
    end, group = group })

    autocmd("CmdlineChanged", { callback = function()
        Autocmd:on_cmdline_changed(self.searchables)
    end, group = group })

    autocmd("VimResized", { callback = function()
        on_vim_resized()
    end, group = group })
end

return Autocmd
