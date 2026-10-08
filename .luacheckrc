std = "luajit"
globals = { "vim" }
max_line_length = false

files["tests/"] = {
    std = "+busted",
}
