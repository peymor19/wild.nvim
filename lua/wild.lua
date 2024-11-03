local ui = require("ui")
local fzy = require("fzy")

local config = {
    binds = {
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
    }
}

local Wild = {state = state, config = config}

local function get_commands()
    local data = {}

    for _, name in pairs(vim.fn.getcompletion("", "cmdline")) do
        table.insert(data, name)
    end

    for name, _ in pairs(vim.api.nvim_get_commands({})) do
        table.insert(data, name)
    end

    return data
end

function Wild:setup()
    commands = get_commands()

    local buf_id, win_id = ui.create_window(commands)

    vim.api.nvim_create_user_command("WildNext", function() ui:highlight_next_line(buf_id, win_id) end, {desc = "Next Command" })
    vim.api.nvim_create_user_command("WildPrevious", function() ui:highlight_previous_line(buf_id, win_id) end, {desc = "Previous Command" })
    vim.api.nvim_set_keymap('c', self.config.binds.next_key, "<Cmd>WildNext<CR>", { noremap = true })
    vim.api.nvim_set_keymap('c', self.config.binds.previous_key, "<Cmd>WildPrevious<CR>", { noremap = true })

    local group = vim.api.nvim_create_augroup("wild", { clear = true })

    vim.api.nvim_create_autocmd("CmdlineEnter", { callback = function()
        if vim.fn.getcmdtype() == ":" then
            ui:update_buffer_contents(buf_id, commands)
            ui.show_window(win_id)
            ui.redraw_window(win_id)
        end
    end, group = group })

    vim.api.nvim_create_autocmd("CmdlineLeave", { callback = function() ui.hide_window(win_id) end, group = group })

    vim.api.nvim_create_autocmd("CmdlineChanged", {
        callback = function()
            if vim.fn.getcmdtype() == ":" then
                local input = vim.fn.getcmdline()

                matches = fzy.find_matches(input, commands)

                ui:update_buffer_contents(buf_id, matches)
                ui.redraw_window(win_id)
            end
        end, group = group})

    --vim.api.nvim_create_autocmd("VimResized", {
    --    callback = function()
    --        WildUi.resize_window(win_id)
    --    end
    --})
end

return Wild
