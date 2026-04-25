# XxUnkn0wnxX Homebrew Tap

General-purpose Homebrew tap for formulas maintained by XxUnkn0wnxX.

The current `bdcli` formula is focused on macOS Big Sur-compatible builds from `XxUnkn0wnxX/BDCLI`, but the tap itself is not limited to BDCLI.

## Install BDCLI

```bash
brew tap xxunkn0wnxx/tap
brew install -sv xxunkn0wnxx/tap/bdcli
```

The `bdcli` formula builds from the pinned BDCLI source snapshot defined in this tap. It depends on the tap-local `go` formula, which preserves a Big Sur-compatible Go toolchain.

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
