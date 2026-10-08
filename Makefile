.PHONY: test lint format format-check check

PLENARY_DIR ?= ../plenary.nvim

test:
	PLENARY_DIR=$(PLENARY_DIR) nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua', sequential = true}"

lint:
	luacheck lua tests

format:
	stylua lua tests

format-check:
	stylua --check lua tests

check: lint format-check test
