# wild.nvim

### Required dependencies

- [romgrk/fzy-lua-native](https://github.com/romgrk/fzy-lua-native) is required.

### Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- init.lua:
    {
    'peymor19/wild.nvim',
      dependencies = { 'romgrk/fzy-lua-native' }
    }

-- plugins/wild.lua:
return {
    'peymor19/wild.nvim',
      dependencies = { 'romgrk/fzy-lua-native' }
    }
```

### Basic Setup

```lua
require('wild').setup()
```

## Contributing

Contributions are welcome! Please submit an issue or a pull request with any improvements, bug reports, or new feature ideas.
