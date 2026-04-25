# XxUnkn0wnxX Homebrew Tap

Homebrew tap for macOS Big Sur-focused builds from `XxUnkn0wnxX/BDCLI`.

## Install BDCLI

```bash
brew tap xxunkn0wnxx/tap
brew install -sv xxunkn0wnxx/tap/bdcli
```

The `bdcli` formula builds from the `main` branch of `XxUnkn0wnxX/BDCLI`. It depends on the tap-local `go` formula, which preserves a Big Sur-compatible Go toolchain.

## Manage

```bash
brew reinstall -sv xxunkn0wnxx/tap/bdcli
brew uninstall xxunkn0wnxx/tap/bdcli
```

If you want to install or manage the Go formula directly:

```bash
brew install -sv xxunkn0wnxx/tap/go
brew uninstall xxunkn0wnxx/tap/go
```
