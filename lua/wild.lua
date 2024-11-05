local ui = require("ui")
local fzy = require("fzy")

local Wild = {
    binds = {
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
    }
}

local function get_commands()
    local data = {}

    for _, name in pairs(vim.fn.getcompletion("", "cmdline")) do
        if not string.match(name, "[~!?#&<>@=]") then
            table.insert(data, name)
        end
    end

    return data
end

function Wild:setup()
    local group = vim.api.nvim_create_augroup("wild", { clear = true })

    vim.api.nvim_create_autocmd('VimEnter', {
        callback = function()
            commands = get_commands()
        end, group = group })

    vim.api.nvim_create_autocmd("CmdlineEnter", {
        callback = function()
            if vim.fn.getcmdtype() == ":" then
                ui:create_window(commands)
                ui.redraw()
            end
        end, group = group })

    vim.api.nvim_create_autocmd("CmdlineLeave", {
        callback = function()
            ui:close_window()
        end, group = group })

    vim.api.nvim_create_autocmd("CmdlineChanged", {
        callback = function()
            if vim.fn.getcmdtype() == ":" then
                local input = vim.fn.getcmdline()

                matches = fzy.find_matches(input, commands)

                ui:update_buffer_contents(matches)
                ui.redraw()
            end
        end, group = group })

    vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
            if vim.fn.mode() == "c" then
                vim.defer_fn(function()
                    ui:resize_window()
                    ui.redraw()
                end, 100)
            end
        end, group = group })

    vim.api.nvim_create_user_command("WildNext", function() ui:highlight_next_line() end, {desc = "Next Command" })
    vim.api.nvim_create_user_command("WildPrevious", function() ui:highlight_previous_line() end, {desc = "Previous Command" })
    vim.api.nvim_set_keymap('c', self.binds.next_key, "<Cmd>WildNext<CR>", { noremap = true })
    vim.api.nvim_set_keymap('c', self.binds.previous_key, "<Cmd>WildPrevious<CR>", { noremap = true })
end

return Wild
