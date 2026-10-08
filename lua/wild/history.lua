local M = {}

M.path = vim.fn.stdpath("data") .. "/command_history.json"
M.max_entries = 1000

local HOUR = 60 * 60
local DAY = 24 * HOUR
local WEEK = 7 * DAY

---@class wild.HistoryEntry
---@field line string
---@field count integer
---@field last_used integer

---@param entry wild.HistoryEntry
---@param now integer
---@return number
function M.score(entry, now)
    local age = now - entry.last_used

    if age < HOUR then
        return entry.count * 4
    elseif age < DAY then
        return entry.count * 2
    elseif age < WEEK then
        return entry.count
    end

    return entry.count * 0.25
end

---@param entries wild.HistoryEntry[]
---@param now integer
---@return wild.HistoryEntry[]
function M.sort(entries, now)
    table.sort(entries, function(a, b)
        local score_a, score_b = M.score(a, now), M.score(b, now)

        if score_a ~= score_b then
            return score_a > score_b
        end

        return a.last_used > b.last_used
    end)

    return entries
end

local function is_entry(item)
    return type(item) == "table"
        and type(item.line) == "string"
        and type(item.count) == "number"
        and type(item.last_used) == "number"
end

---@param path string
---@return wild.HistoryEntry[]
function M.read(path)
    local file = io.open(path, "r")

    if not file then
        return {}
    end

    local contents = file:read("*all")
    file:close()

    local ok, data = pcall(vim.json.decode, contents)

    if not ok or type(data) ~= "table" then
        return {}
    end

    return vim.tbl_filter(is_entry, data)
end

---@param path string
---@param entries wild.HistoryEntry[]
function M.write(path, entries)
    vim.fn.mkdir(vim.fs.dirname(path), "p")

    local tmp_path = path .. ".tmp"
    local file = io.open(tmp_path, "w")

    if not file then
        return
    end

    file:write(vim.json.encode(entries))
    file:close()

    vim.uv.fs_rename(tmp_path, path)
end

---@param path string
---@param line string
---@param now integer
---@return wild.HistoryEntry[]
function M.record(path, line, now)
    local entries = M.read(path)
    local found = false

    for _, entry in ipairs(entries) do
        if entry.line == line then
            entry.count = entry.count + 1
            entry.last_used = now
            found = true
            break
        end
    end

    if not found then
        table.insert(entries, { line = line, count = 1, last_used = now })
    end

    M.sort(entries, now)

    for i = #entries, M.max_entries + 1, -1 do
        entries[i] = nil
    end

    M.write(path, entries)

    return entries
end

return M
