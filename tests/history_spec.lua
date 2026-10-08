local History = require("wild.history")

local HOUR = 60 * 60
local DAY = 24 * HOUR
local now = 10000000

local function lines(entries)
    return vim.tbl_map(function(entry)
        return entry.line
    end, entries)
end

describe("score", function()
    it("should weight recent use more than old use", function()
        local function score(age)
            return History.score({ line = "w", count = 4, last_used = now - age }, now)
        end

        assert.is_equal(16, score(0))
        assert.is_equal(8, score(2 * HOUR))
        assert.is_equal(4, score(2 * DAY))
        assert.is_equal(1, score(30 * DAY))
    end)
end)

describe("sort", function()
    it("should order by frecency", function()
        local entries = {
            { line = "old", count = 10, last_used = now - 30 * DAY },
            { line = "recent", count = 1, last_used = now },
            { line = "often", count = 5, last_used = now - 2 * HOUR },
        }

        assert.are.same({ "often", "recent", "old" }, lines(History.sort(entries, now)))
    end)

    it("should put the most recent first when scores are equal", function()
        local entries = {
            { line = "a", count = 1, last_used = now - 10 },
            { line = "b", count = 1, last_used = now },
        }

        assert.are.same({ "b", "a" }, lines(History.sort(entries, now)))
    end)
end)

describe("lines", function()
    it("should return the lines ordered by frecency", function()
        local entries = {
            { line = "foo", count = 1, last_used = now },
            { line = "bar", count = 5, last_used = now },
        }

        assert.are.same({ "bar", "foo" }, History.lines(entries, now))
    end)
end)

describe("read and write", function()
    local path

    before_each(function()
        path = vim.fn.tempname()
    end)

    after_each(function()
        os.remove(path)
    end)

    it("should read back what was written", function()
        local entries = { { line = "e foo.txt", count = 2, last_used = now } }

        History.write(path, entries)

        assert.are.same(entries, History.read(path))
    end)

    it("should create missing parent directories", function()
        local dir = vim.fn.tempname()
        local nested_path = dir .. "/nested/history.json"

        History.write(nested_path, { { line = "w", count = 1, last_used = now } })

        assert.is_equal(1, #History.read(nested_path))
        vim.fn.delete(dir, "rf")
    end)

    it("should not leave a temporary file behind", function()
        History.write(path, { { line = "w", count = 1, last_used = now } })

        assert.is_nil(vim.uv.fs_stat(path .. ".tmp"))
    end)

    it("should return an empty list when the file is missing", function()
        assert.are.same({}, History.read(path))
    end)

    it("should return an empty list when the file is not valid JSON", function()
        vim.fn.writefile({ "not json" }, path)

        assert.are.same({}, History.read(path))
    end)

    it("should skip malformed entries", function()
        vim.fn.writefile(
            { vim.json.encode({ { cmd = "edit", count = 1 }, { line = "w", count = 1, last_used = now } }) },
            path
        )

        assert.are.same({ "w" }, lines(History.read(path)))
    end)
end)

describe("record", function()
    local path

    before_each(function()
        path = vim.fn.tempname()
    end)

    after_each(function()
        os.remove(path)
    end)

    it("should add a new line", function()
        local entries = History.record(path, "e foo.txt", now)

        assert.are.same({ { line = "e foo.txt", count = 1, last_used = now } }, entries)
        assert.are.same(entries, History.read(path))
    end)

    it("should increment an existing line and update when it was used", function()
        History.record(path, "w", now - DAY)
        local entries = History.record(path, "w", now)

        assert.are.same({ { line = "w", count = 2, last_used = now } }, entries)
    end)

    it("should keep lines written by another instance", function()
        History.record(path, "w", now - 10)
        History.write(path, vim.list_extend(History.read(path), { { line = "q", count = 3, last_used = now } }))

        local entries = History.record(path, "e foo.txt", now)

        assert.are.same({ "q", "e foo.txt", "w" }, lines(entries))
    end)

    it("should drop the lowest scoring lines past max_entries", function()
        local original = History.max_entries
        History.max_entries = 2

        History.record(path, "a", now - 30 * DAY)
        History.record(path, "b", now - 10)
        local entries = History.record(path, "c", now)

        History.max_entries = original

        assert.are.same({ "c", "b" }, lines(entries))
    end)
end)
