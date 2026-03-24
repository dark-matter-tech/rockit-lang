# Editor Setup

Rockit includes a Language Server Protocol (LSP) implementation for editor integration.

## VS Code

1. Install the Rockit extension from the VS Code marketplace (search "Rockit")
2. Or configure manually in `.vscode/settings.json`:

```json
{
  "rockit.serverPath": "/path/to/rockit-lsp"
}
```

## Neovim

Add to your LSP config:

```lua
local lspconfig = require('lspconfig')

lspconfig.rockit = {
  default_config = {
    cmd = { 'rockit-lsp' },
    filetypes = { 'rockit' },
    root_dir = function(fname)
      return lspconfig.util.find_git_ancestor(fname)
    end,
  },
}

lspconfig.rockit.setup{}
```

## LSP Features

The Rockit LSP supports all 28 standard LSP methods:

| Feature | Status |
|---------|--------|
| Diagnostics (errors/warnings) | Real-time |
| Hover (type info) | Working |
| Go to Definition | Working |
| Find References | Working |
| Completion (dot + scope) | Working |
| Document Symbols (outline) | Working |
| Formatting | Working |
| Rename | Working |
| Semantic Tokens (highlighting) | Working |
| Signature Help | Working |
| Folding Ranges | Working |
| Document Highlight | Working |
| Selection Range | Working |
| Inlay Hints | Working |
| Code Actions | Working |
| Call Hierarchy | Working |
| Type Hierarchy | Working |
| Code Lens | Working |

## File Extension

Rockit files use the `.rok` extension. Bytecode files use `.rokb`.
