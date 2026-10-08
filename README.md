# wild.nvim

Fuzzy command-line completion for Neovim, ranked by your command history.

Press `:` and a popup lists the command lines you run most, followed by every other Ex command. Type to fuzzy filter, press `<Tab>` to pick. After a space it fuzzy completes the command's arguments: files, options, colorschemes, help tags and more.

<!-- TODO: demo GIF -->

## Features

- Popup opens as soon as you press `:`, no extra key needed
- Fuzzy matching with [fzy](https://github.com/romgrk/fzy-lua-native), with the matched characters highlighted
- Past command lines ranked by frecency (how often and how recently you ran them)
- History is shared between Neovim instances
- Fuzzy argument completion for any command Neovim can complete (`:e`, `:set`, `:colorscheme`, `:h`, `:lua`, ...)
- Arguments you used before come first
- Search history for `/` and `?`, ranked and fuzzy filtered the same way
- `<Tab>` and `<S-Tab>` work as usual in `input()` prompts
- Auto width and a match counter
- Highlight groups that follow your colorscheme
- `:checkhealth wild`

## Requirements

- Neovim 0.12 or newer
- [romgrk/fzy-lua-native](https://github.com/romgrk/fzy-lua-native)

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "peymor19/wild.nvim",
    dependencies = { "romgrk/fzy-lua-native" },
    config = function()
        require("wild").setup()
    end,
}
```

## Configuration

`setup()` takes an optional table. Anything you leave out uses the default below.

```lua
require("wild").setup({
    window = {
        width = 30, -- a number, or "auto" to fit the longest match
        max_width = 80, -- largest width when width is "auto"
        height = 10,
        border = "rounded", -- any border accepted by nvim_open_win()
        opacity = 0, -- 0 (opaque) to 100
        background_hl = nil, -- e.g. { bg = "#1e1e2e" }, defaults to a link to Normal
        border_hl = nil, -- e.g. { fg = "#89b4fa" }, defaults to a link to FloatBorder
        counter = true, -- show "3/28" in the bottom border
    },
    highlights = {
        line_color = "#FFA500", -- selected line
        character_color = "#6495ED", -- matched characters
    },
    keymaps = {
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
    },
    disable_cmdwin = true, -- turn off q:, q/, q? and <C-f> in the command line
    search = true, -- show search history for / and ?
})
```

See `:h wild-config` for details on every option.

## Highlight groups

| Group           | Used for                  | Default                 |
| --------------- | ------------------------- | ----------------------- |
| `WildNormal`    | Popup background          | links to `Normal`       |
| `WildBorder`    | Popup border and counter  | links to `FloatBorder`  |
| `WildMatch`     | Characters matching input | `character_color`, bold |
| `WildSelection` | Selected line             | `line_color`, bold      |

The groups are set as defaults, so your colorscheme or your own `nvim_set_hl()` call wins:

```lua
vim.api.nvim_set_hl(0, "WildSelection", { fg = "#ff79c6", bold = true })
```

## Commands

| Command             | Description                                 |
| ------------------- | ------------------------------------------- |
| `:WildResetHistory` | Delete the saved command and search history |

## History

Each command line you run from `:` is saved exactly as typed, so `:e foo.txt` and `:e bar.txt` are separate entries. Cancelled lines and invalid commands are not saved. Searches from `/` and `?` get their own history, saved the same way.

Entries are ranked by frecency: each use counts 4× within the last hour, 2× within a day, 1× within a week and ¼× after that. Up to 1000 entries are kept, and every Neovim instance adds to the same file.

History is saved to `stdpath("data")/command_history.json` and `stdpath("data")/search_history.json`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
