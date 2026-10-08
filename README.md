# wild.nvim

Fuzzy command-line completion for Neovim, ordered by how often you use each command.

Press `:` and a popup lists every Ex command, most used first. Type to fuzzy filter, press `<Tab>` to pick. Type `:h ` and it searches help tags instead.

<!-- TODO: demo GIF -->

## Features

- Popup opens as soon as you press `:`, no extra key needed
- Fuzzy matching with [fzy](https://github.com/romgrk/fzy-lua-native), with the matched characters highlighted
- Commands you run most often come first
- `:h`, `:he`, `:hel` and `:help` search help tags
- `<Tab>` and `<S-Tab>` work as usual in `/`, `?` and `input()` prompts
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
        width = 30,
        height = 10,
        border = "rounded", -- any border accepted by nvim_open_win()
        opacity = 0, -- 0 (opaque) to 100
        background_hl = nil, -- e.g. { bg = "#1e1e2e" }, defaults to a link to Normal
        border_hl = nil, -- e.g. { fg = "#89b4fa" }, defaults to a link to FloatBorder
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
})
```

See `:h wild-config` for details on every option.

## Highlight groups

| Group           | Used for                  | Default                 |
| --------------- | ------------------------- | ----------------------- |
| `WildNormal`    | Popup background          | links to `Normal`       |
| `WildBorder`    | Popup border              | links to `FloatBorder`  |
| `WildMatch`     | Characters matching input | `character_color`, bold |
| `WildSelection` | Selected line             | `line_color`, bold      |

The groups are set as defaults, so your colorscheme or your own `nvim_set_hl()` call wins:

```lua
vim.api.nvim_set_hl(0, "WildSelection", { fg = "#ff79c6", bold = true })
```

## Commands

| Command             | Description                                  |
| ------------------- | -------------------------------------------- |
| `:WildResetHistory` | Delete the saved history and start from zero |

## History

Each command you run from `:` adds one to its count. Counts are kept per command, so `:e foo.txt` and `:edit bar.txt` both count toward `edit`. Cancelled command lines are not counted.

History is saved to `stdpath("data")/command_history.json`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
