# XxUnkn0wnxX Homebrew Tap

General-purpose Homebrew tap for formulas maintained by XxUnkn0wnxX.

The tap includes Big Sur-focused BDCLI and Go formulas, plus Shaka Packager from the `stratumadev` fork.

## Install BDCLI

```bash
brew tap xxunkn0wnxx/tap
brew install --HEAD -sv xxunkn0wnxx/tap/bdcli
```

The `bdcli` formula is HEAD-only and builds from the `main` branch of `XxUnkn0wnxX/BDCLI`. It depends on the tap-local `go` formula, which preserves a Big Sur-compatible Go toolchain.

## Install Shaka Packager

```bash
brew tap xxunkn0wnxx/tap
brew install --HEAD -sv xxunkn0wnxx/tap/shaka-packager
```

This HEAD-only formula follows the `main` branch of [stratumadev/shaka-packager](https://github.com/stratumadev/shaka-packager). It builds from source and installs `packager`, `mpd_generator`, `shaka_decrypt`, the shared `libpackager` library, public headers, pkg-config metadata and the PSSH Python tools.

Homebrew manages CMake, Git and Ninja as build dependencies, and Python 3.14 for both building and running the installed PSSH tool. Third-party C++ libraries are built from the upstream submodules. A C++17-capable compiler is required.

To update to the latest upstream commit or uninstall:

```bash
brew upgrade --fetch-HEAD -sv xxunkn0wnxx/tap/shaka-packager
brew uninstall xxunkn0wnxx/tap/shaka-packager
```

## Manage

```bash
brew reinstall --HEAD -sv xxunkn0wnxx/tap/bdcli
brew uninstall xxunkn0wnxx/tap/bdcli
```

If you want to install or manage the Go formula directly:

```bash
brew install -sv xxunkn0wnxx/tap/go
brew uninstall xxunkn0wnxx/tap/go
```

## CI checks

Formula and workflow changes run Homebrew style, loading and audit checks on macOS and Linux. Pull requests also build changed formulas from source, check their linked libraries and run their formula tests. Standard Homebrew dependency bottles may be downloaded during those builds.

Bottle creation, bottle uploads and automatic publishing are disabled. Their generated workflow definitions remain in the repository for future use.
