# Fuel Package Manager

Fuel is Rockit's package manager, bundled with the toolchain.

## Commands

| Command | Description |
|---------|-------------|
| `fuel init <name>` | Create a new project |
| `fuel build` | Build the project |
| `fuel run` | Build and run |
| `fuel test` | Run tests |
| `fuel install <pkg>` | Install a dependency |
| `fuel update` | Update dependencies |
| `fuel clean` | Remove build artifacts |

## Project Structure

```
my-app/
  fuel.toml           # Project configuration
  src/
    main.rok           # Entry point
  tests/
    test_main.rok      # Tests
```

## fuel.toml

```toml
[package]
name = "my-app"
version = "0.1.0"

[dependencies]
# name = "version"

[test]
files = ["tests/*.rok"]
```

## Creating a Project

```bash
fuel init my-app
cd my-app
fuel run
```

## Adding Dependencies

```bash
fuel install some-package
```

This adds the package to `fuel.toml` and downloads it to the local cache.
