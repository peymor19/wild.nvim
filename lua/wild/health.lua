local config = require("wild.config")
local history = require("wild.history")

local M = {}

local function check_requirements()
    vim.health.start("wild.nvim: requirements")

    local version = tostring(vim.version())

    if vim.fn.has("nvim-0.12") == 1 then
        vim.health.ok("Neovim " .. version)
    else
        vim.health.error("Neovim 0.12 or newer is required, found " .. version)
    end

    local ok, err = pcall(require, "fzy-lua-native")

    if ok then
        vim.health.ok("fzy-lua-native is installed")
    else
        vim.health.error("fzy-lua-native could not be loaded", {
            "Add romgrk/fzy-lua-native as a dependency of wild.nvim",
            err:match("^[^\n]+"),
        })
    end
end

local function describe_mapping(map)
    local source = map.desc or map.rhs or "a Lua function"
    local info = map.sid and map.sid > 0 and vim.fn.getscriptinfo({ sid = map.sid })[1]

    if info and map.lnum > 0 then
        return string.format("%s (%s:%d)", source, info.name, map.lnum)
    elseif info then
        return string.format("%s (%s)", source, info.name)
    end

    return source
end

local function check_setup()
    vim.health.start("wild.nvim: setup")

    if next(config.options) == nil then
        vim.health.warn("setup() has not been called", "Add require('wild').setup() to your config")
        return
    end

    vim.health.ok("setup() has been called")

    for _, key in ipairs({ config.options.keymaps.next_key, config.options.keymaps.previous_key }) do
        local map = vim.fn.maparg(key, "c", false, true)

        if vim.tbl_isempty(map) then
            vim.health.warn(key .. " is not mapped in command-line mode")
        elseif map.desc and vim.startswith(map.desc, "wild:") then
            vim.health.ok(key .. " is mapped")
        else
            vim.health.warn(
                key .. " is mapped by something else: " .. describe_mapping(map),
                "Remove the other mapping or change keymaps in wild's setup()"
            )
        end
    end
end

local function check_history_file(path, name, plural)
    local dir = vim.fs.dirname(path)

    if vim.fn.isdirectory(dir) == 1 and vim.fn.filewritable(dir) ~= 2 then
        vim.health.error("Cannot write to " .. dir .. ", history will not be saved")
    end

    if not vim.uv.fs_stat(path) then
        vim.health.info("No " .. name .. " history file yet, it is created after your first " .. name .. ": " .. path)
        return
    end

    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))

    if ok and type(data) == "table" then
        vim.health.ok(string.format("%d %s in history: %s", #data, plural, path))
    else
        vim.health.error("History file is not valid JSON: " .. path, "Run :WildResetHistory to start over")
    end
end

local function check_history()
    vim.health.start("wild.nvim: history")

    check_history_file(history.path, "command", "commands")
    check_history_file(history.search_path, "search", "searches")
end

function M.check()
    check_requirements()
    check_setup()
    check_history()
end

return M
