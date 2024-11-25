local ui = require("ui")
local fzy = require("fzy")
local cmd = require("cmd")

local Autocmd = { searchables = {} }
local file_path = vim.fn.stdpath('data') .. '/command_history.json'

function Autocmd.on_vim_enter()
    commands_from_file = cmd.from_file(file_path)
    searchables = cmd.get_searchables(commands_from_file)
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

        cmd.to_file(file_path, searchables.commands)
    end

    ui:close_window()

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
