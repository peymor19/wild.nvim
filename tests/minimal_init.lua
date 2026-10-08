local plenary_dir = os.getenv("PLENARY_DIR") or "../plenary.nvim"

vim.opt.rtp:prepend(".")
vim.opt.rtp:prepend(plenary_dir)

vim.cmd("runtime! plugin/plenary.vim")
