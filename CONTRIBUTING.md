# Contributing

Bug reports, ideas and pull requests are welcome. For anything bigger than a small fix, open an issue first so we can agree on the approach.

## Setup

You need:

- Neovim 0.12 or newer
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) cloned next to this repo (or set `PLENARY_DIR`)
- [fzy-lua-native](https://github.com/romgrk/fzy-lua-native) cloned next to this repo (or set `FZY_DIR`)
- [StyLua](https://github.com/JohnnyMorganz/StyLua)
- [luacheck](https://github.com/lunarmodules/luacheck)

```sh
git clone https://github.com/nvim-lua/plenary.nvim ../plenary.nvim
git clone https://github.com/romgrk/fzy-lua-native ../fzy-lua-native
```

## Running checks

| Command             | What it does                      |
| ------------------- | --------------------------------- |
| `make test`         | Run the test suite                |
| `make lint`         | Run luacheck                      |
| `make format`       | Format the code with StyLua       |
| `make format-check` | Check formatting without changing |
| `make check`        | Lint, format check and tests      |

Use other checkouts, such as the ones your plugin manager installed, with:

```sh
make test PLENARY_DIR=/path/to/plenary.nvim FZY_DIR=/path/to/fzy-lua-native
```

`tests/integration_spec.lua` starts a separate Neovim for each test, types into it like a user would, and checks the popup and command line.

CI runs the same checks against Neovim stable and nightly, so run `make check` before opening a pull request.

## Project layout

| Path                      | Purpose                                       |
| ------------------------- | --------------------------------------------- |
| `lua/wild/init.lua`       | `setup()`: autocmds, keymaps and commands     |
| `lua/wild/popup.lua`      | Popup state and command-line event handlers   |
| `lua/wild/config.lua`     | Defaults, option types and validation         |
| `lua/wild/cmd.lua`        | Commands, arguments and help tags             |
| `lua/wild/ui.lua`         | The popup window                              |
| `lua/wild/highlights.lua` | Highlight groups                              |
| `lua/wild/fzy.lua`        | Fuzzy matching                                |
| `lua/wild/history.lua`    | The history file and frecency ranking         |
| `lua/wild/health.lua`     | `:checkhealth wild`                           |
| `doc/wild.txt`            | `:h wild`                                     |
| `tests/`                  | plenary busted tests (`*_spec.lua`)           |

## Pull requests

- Keep each pull request to one change.
- Add or update tests for behavior changes.
- Update `doc/wild.txt` and `README.md` when you add or change an option, command or highlight group.
