# haql-releases — haql-rs binary distribution

**haql-rs** is a zero-dependency C++20 physics-informed neural network engine for reservoir simulation. This repo hosts only the compiled binaries and installer — no source code.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/No1MLEngineer/haql-releases/master/install.sh | sh
# installs to ~/.local/bin/haql-rs, verifies SHA256, checks PATH
```

Custom version or directory:
```bash
HAQL_VERSION=v0.1.1 curl -sSL https://raw.githubusercontent.com/No1MLEngineer/haql-releases/master/install.sh | sh
HAQL_INSTALL_DIR=/usr/local/bin curl -sSL ... | sh
```

Verify manually:
```bash
sha256sum -c SHASUMS256.txt --ignore-missing
./haql-rs-linux-x86_64 --help
```

## Usage

```bash
haql-rs status              # show version + Device ID + license
haql-rs license --hwid      # print HWID for ordering
haql-rs run --epochs 5 -n 500 --quiet
haql-rs --help
```

## Licensing

Commercial use requires a license. Contact: **No1MLEngineer** via GitHub.

Source code is private and not included here. Binary releases are built from the private `No1MLEngineer/haql` repo via CI.

## Links

- Public releases: https://github.com/No1MLEngineer/haql-releases/releases
- Raw installer: https://raw.githubusercontent.com/No1MLEngineer/haql-releases/master/install.sh
