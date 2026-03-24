# Getting Started

## Install

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/dark-matter-tech/rockit-lang/develop/scripts/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/dark-matter-tech/rockit-lang/develop/scripts/install.ps1 | iex
```

## Your First Program

Create `hello.rok`:
```rockit
fun main() {
    println("Hello, Rockit!")
}
```

Run it:
```bash
rockit run hello.rok
```

Compile to native:
```bash
rockit build-native hello.rok -o hello
./hello
```

## Create a Project

```bash
fuel init my-app
cd my-app
fuel build
fuel run
```

This creates:
```
my-app/
  fuel.toml       # Project config
  src/
    main.rok      # Entry point
```

## What's in the Toolchain

| Command | Description |
|---------|-------------|
| `rockit run <file>` | Run a .rok file |
| `rockit build-native <file>` | Compile to native binary |
| `rockit build <file>` | Compile to bytecode |
| `rockit test <file>` | Run tests |
| `rockit lsp` | Start language server |
| `fuel init <name>` | Create new project |
| `fuel build` | Build project |
| `fuel run` | Run project |
| `fuel test` | Run project tests |
| `fuel install <pkg>` | Install a package |
