local ui = require("ui")
local fzy = require("fzy")
local cmd = require("cmd")

local Autocmd = {}

local file_path = vim.fn.stdpath('data') .. '/command_history.json'

local timer = false

local function get_searchables()
    local commands_from_file = cmd.from_file(file_path)
    return cmd.get_searchables(commands_from_file)
end

local function handle_cmdline_enter(searchables)
    if vim.fn.getcmdtype() ~= ":" then return searchables end

    local buf_data = ui.get_buf_data("commands", searchables)
    ui:create_window(buf_data)
    ui.redraw()

    return searchables
end

local function handle_cmdline_leave(searchables)
    if vim.fn.getcmdtype() == ":" then
        local command = vim.fn.getcmdline()
        local updated_commands = cmd.inc_command(command, searchables.commands)

        cmd.to_file(file_path, updated_commands)
        searchables.commands = updated_commands
    end

    ui:close_window()
    return searchables
end

local function handle_cmdline_changed(searchables)
    if vim.fn.getcmdtype() ~= ":" then return searchables end

    local input = vim.fn.getcmdline()
    local buf_data = ui.get_buf_data("commands", searchables)
    local matches = fzy.find_matches(input, buf_data)

    ui:update_buffer_contents(matches)
    ui.redraw()

    return searchables
end

local function handle_vim_resized()
    if vim.fn.mode() == "c" then
        vim.defer_fn(function()
            ui:resize_window()
            ui.redraw()
        end, 100)
    end
end

function Autocmd.init()
    local group = vim.api.nvim_create_augroup("wild", { clear = true })
    local autocmd = vim.api.nvim_create_autocmd

    local searchables = {commands = {}}

    autocmd('VimEnter', { callback = function()
        vim.defer_fn(function()
            searchables = get_searchables()
        end, 100)
    end, group = group })

    autocmd("CmdlineEnter", { callback = function()
        vim.defer_fn(function()
            searchables = handle_cmdline_enter(searchables)
        end, 10)
    end, group = group })

    autocmd("CmdlineLeave", { callback = function()
        searchables = handle_cmdline_leave(searchables)
    end, group = group })

    autocmd("CmdlineChanged", { callback = function()
        vim.defer_fn(function()
            searchables = handle_cmdline_changed(searchables)
        end, 10)
    end, group = group })

    autocmd("VimResized", { callback = function()
        handle_vim_resized()
    end, group = group })
end

return Autocmd
