
local function main()
  --print("Hello from our plugin")
end

local function setup()
    local augroup = vim.api.nvim_create_augroup("Wild", { clear = true })
    vim.api.nvim_create_autocmd("VimEnter", { group = augroup, desc = "Test", once = true, callback = main })
end

return { setup = setup }
