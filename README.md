# ndo.vim

A Neovim plugin for managing `.TODO` files with status tracking, timestamps, and tags.

## Features

- **Three status states**: `[ ]` new, `[-]` pending, `[x]` done
- **Automatic timestamps**: Tracks when items change status
- **Elapsed time display**: Shows how long tasks have been in progress
- **Tags**: Organize with `@tag` syntax
- **Subtasks**: Indented child tasks under parent items
- **Notes**: Add context with `>` prefixed lines
- **Archive**: Move completed items to an archive section
- **Virtual text**: Clean display with raw data hidden in normal mode

## Installation

### lazy.nvim

```lua
{
  dir = "~/path/to/ndo.vim",
  keys = {
    { "<leader>T", function() require("ndo").open_todo() end, desc = "Open TODO file" },
  },
  ft = "todo",
  config = function()
    require("ndo").setup({})
  end,
}
```

## Display

**Normal mode** - clean view with formatted timestamps:
```
[ ] Buy groceries                    ○ 16 Dec 08:30
[-] Fix login bug @work              ◐ 16 Dec 09:15 → 2h 30m
  [ ] Reproduce the issue            ○ 16 Dec 09:20
  [ ] Write unit test                ○ 16 Dec 09:20
  > Check the auth middleware first
[x] Write documentation              ● 16 Dec 11:45
```

**Insert mode** - raw data visible for editing:
```
[ ] Buy groceries {new:16-12-2025T08:30:00}
[-] Fix login bug @work {new:16-12-2025T08:00:00} {pending:16-12-2025T09:15:00}
[x] Write documentation {new:16-12-2025T08:00:00} {pending:16-12-2025T09:00:00} {done:16-12-2025T11:45:00}
```

## Keymaps

Global:
| Key | Action |
|-----|--------|
| `<leader>T` | Open/create TODO file |

In `.TODO` files:
| Key | Action |
|-----|--------|
| `<leader>tn` | Create new todo (prompts for text) |
| `<leader>tt` | Toggle status (new → pending → done → new) |
| `<leader>td` | Mark done `[x]` |
| `<leader>tp` | Mark pending `[-]` |
| `<leader>tr` | Reset to new `[ ]` |
| `<leader>tk` | Move todo up |
| `<leader>tj` | Move todo down |
| `<leader>ta` | Archive completed items |
| `<leader>tF` | Format file |
| `<leader>ts` | Add subtask (prompts for text) |
| `<leader>tN` | Add note (prompts for text) |
| `<leader>t@` | Add tag (prompts for name) |
| `<leader>tX` | Remove tag |
| `<leader>t/` | Find by tag |

## Commands

| Command | Description |
|---------|-------------|
| `:NdoOpen` | Open closest TODO file |
| `:NdoCreate` | Create new todo item (prompts for text) |
| `:NdoToggle` | Toggle status |
| `:NdoDone` | Mark as done |
| `:NdoPending` | Mark as pending |
| `:NdoNew` | Mark as new |
| `:NdoMoveUp` | Move line up |
| `:NdoMoveDown` | Move line down |
| `:NdoArchive` | Archive done items |
| `:NdoFormat` | Format buffer |
| `:NdoSubtask` | Add indented subtask (prompts for text) |
| `:NdoNote` | Add indented note (prompts for text) |
| `:NdoAddTag [tag]` | Add tag to line (prompts if no arg) |
| `:NdoRemoveTag [tag]` | Remove tag from line |
| `:NdoFindTag [tag]` | Jump to tag |

## Configuration

```lua
require("ndo").setup({
  markers = {
    new = "[ ]",
    pending = "[-]",
    done = "[x]",
  },
  archive_section = "## Archived",
  date_format = "%Y-%m-%d",
  timestamp_format = "%d-%m-%YT%H:%M:%S",
})
```

## File Detection

The plugin recognizes these files as TODO files:
- `.TODO`
- `TODO`
- `.todo`
- `todo.TODO`

## Timestamp Behavior

- **New → Pending**: Keeps `{new:...}`, adds `{pending:...}`
- **Pending → Done**: Keeps `{new:...}` and `{pending:...}`, adds `{done:...}`
- **Done → Pending**: Removes `{done:...}`, keeps others
- **Any → New**: Removes all except `{new:...}`

## License

MIT
