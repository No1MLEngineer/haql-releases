# haql-rs — Tester Guide

**haql-rs** is a command-line reservoir simulation tool. It runs physics-informed neural network models for single- and two-phase flow. This page takes you from install to a working licensed run.

---

## 1. Install

Run in your terminal (Linux):

```bash
curl -sSL https://raw.githubusercontent.com/No1MLEngineer/haql-releases/master/install.sh | sh
```

This installs `haql-rs` to `~/.local/bin`, verifies the SHA256, and checks it is executable.

**If you see `haql-rs: command not found` after install**, your shell does not have `~/.local/bin` on its `PATH`. Add it:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Add that line to `~/.bashrc` (or `~/.zshrc`) and restart your terminal, or run it once in the current shell.

Verify:

```bash
haql-rs --help
haql-rs status
```

You do not need Python, CUDA, or any dependencies.

---

## 2. Get your license activated

Licenses are offline and bound to your machine. You need to send your Device ID (HWID) once and you will receive a `HAQL1....` key back.

### Step 1 — Get your Device ID

```bash
haql-rs status
```

On first run with no license, you will see:

```
  ┌─ Welcome to haql ----------------------------------------┐
  │ First run — no license found.                           │
  │                                                         │
  │   Your Device ID (HWID):  0a90df7a75916177                │
  │   Send this ID to your provider to receive your         │
  │   HAQL1. license key.                                   │
  └------------------------------------------------------------┘

  Device ID: 0a90df7a75916177
```

Your HWID will be different — it is 16 hex characters derived from your machine. You can also run just:

```bash
haql-rs license --hwid
# prints only: 0a90df7a75916177
```

### Step 2 — Send your HWID

Send that 16-character HWID to your contact for this test program.

> **TODO — operator: replace this line with actual contact.** Example: email `you@company.com` or Slack DM `@your-handle` in `#haql-testers`. Do not guess — confirm before sending tester invites.

### Step 3 — Activate the key you receive

You will receive a single line starting with `HAQL1.` (several hundred characters). All three methods do the same — pick one:

**A) Interactive (paste when prompted):**
```bash
haql-rs license
# Paste HAQL1.... when prompted → writes to ~/.haql/license.key
```

**B) Environment variable (per-run, good for CI):**
```bash
HAQL_LICENSE=HAQL1.... haql-rs run -e 5
```

**C) File (persistent):**
```bash
echo HAQL1.... > ~/.haql/license.key
chmod 600 ~/.haql/license.key
```

File locations checked (in order): `HAQL_LICENSE` env → `~/.haql/license.key` → `haql.license` in current directory. The file is outside any repo — do not `git add` it.

### Step 4 — Confirm it worked

```bash
haql-rs status
```

You should now see:

```
  ┌─ License active ----------------------------------------┐
  │   ✓ geophysics-student (team, 1 seats) until 2027-09-01  │
  │   362 days remaining  ·  HWID: 0a90df7a75916177           │
  └------------------------------------------------------------┘

  ✓ Status report complete
```

Instead of `Welcome to haql / First run — no license found`. If you still see the welcome box, the key did not save — retry Step 3 and check the HWID in the `License active` line matches your `haql-rs license --hwid`.

---

## 3. Quick test run

This is the smoke test — it trains a small 2-phase model and prints results. With a valid license it should finish in ~5 seconds:

```bash
haql-rs run --epochs 5 --interior 500 --quiet
```

**Healthy output looks like:**

```
  Loss Breakdown
  Oil PDE  1.8e-08
  Gas PDE  1.9e-03
  BC       2.8e+01
  IC       1.2e+00
  Total    1.15e+01 (5 epochs)

  Well Results
  ┌─────────────┬──────────┬────────┬──────────────┬───────┐
  │ Well        │ Pressure │   Sg   │ Target       │ Match │
  ├─────────────┼──────────┼────────┼──────────────┼───────┤
  │ Injector    │     4801 │    0.0%│ 4801 psi / 0%│  ✓    │
  │ Producer    │     3840 │    8.6%│ 3840 psi / 8%│  ✓    │
  └─────────────┴──────────┴────────┴──────────────┴───────┘

  FDM Reference Comparison
  │ Injector pressure │       4801 │       4801 │      0 psi │
  │ Producer pressure │       3840 │       3840 │      0 psi │
  │ Producer Sg       │       8.6% │       8.6% │   0.0%   │

  ✓ ALL TARGETS MATCHED
```

- `Total` should drop from `~50` to `~10-20` over 5 epochs.
- `Well Results` should show `Injector 4801` and `Producer 3840` with `✓`.
- If you see `✗ haql run requires a valid license` — you are not licensed (see Section 2).
- If you see `ALL TARGETS MATCHED`, the install + license are good.

Tester recommendation: start with `5` epochs for speed, then `50` epochs for a fuller run: `haql-rs run -e 50 -n 800 -q` (~7s/epoch at 500 pts, ~23s at 2000).

---

## 4. Common commands

| Command | What it does |
|---------|--------------|
| `haql-rs status` | Show version, license, HWID, and FDM targets |
| `haql-rs run` | Train and evaluate 2-phase PINN (see `run --help` for flags) |
| `haql-rs predict --x 0.5 --y 0.5 --t 100 --dim` | Predict pressure/Sg at a point |
| `haql-rs validate` | Quick validation benchmarks |
| `haql-rs license` | Paste/verify license (`--hwid` prints Device ID only) |
| `haql-rs --help` | All flags and run options |

Run options you will use most: `-e/--epochs`, `-n/--interior`, `--quiet`, `--output <csv>`. Full list: `haql-rs run --help`.

---

## 5. Troubleshooting

**`haql-rs: command not found`**
- You missed the `PATH` step. Run `export PATH="$HOME/.local/bin:$PATH"` and retry. If you used `sudo sh` the binary went to `/usr/local/bin` — try `/usr/local/bin/haql-rs status` and add that dir to `PATH` instead.

**`haql: run requires a valid license` / `no license found`**
- You have not activated a key. See Section 2, Step 3.

**`license HWID mismatch (bound to ab12..., this host 0a90...)` or `license invalid` / `expired`**
- Each key is locked to one HWID. If you reinstall the OS, change machine, or clone to a new VM, your HWID changes and the old key stops working. Run `haql-rs license --hwid` on the new machine and contact your provider for a new `HAQL1.`.

**`checksum mismatch` or `failed to download` during install**
- Network/proxy issue. Re-run the `curl ... | sh` command. If behind a corporate proxy, try `HAQL_VERSION=v.0.1.3 curl -sSL ... | sh` to pin a version. Manual verify: `curl -sSL https://github.com/No1MLEngineer/haql-releases/releases/download/v.0.1.3/SHASUMS256.txt | sha256sum -c`.

**`vector::_M_range_check` or `terminate`** on old builds
- `git pull` is not relevant for binary installs — re-run the install command to get the latest `v.0.1.3` build.

---

## 6. How to report issues / results

> **TODO — operator: confirm before sending to testers.** Example: open an issue at `https://github.com/No1MLEngineer/haql-releases/issues` or email `you@company.com` with `haql-rs run` output (copy/paste the `Well Results` table and `Total` line). If this is not yet decided, replace this section.

What helps:
- The exact command you ran + full terminal output (or `haql-rs run ... --quiet` table).
- `haql-rs status` output (shows license/HWID).
- For benchmarks, the `__HAQL_HISTORY_JSON__` line if you need per-epoch loss.

For detailed physics/benchmark docs, see the separate technical guide `HAQL_RS_GUIDE.md` in the private `haql` repo — this README is intentionally only install → license → run.

---

*Install source: `https://github.com/No1MLEngineer/haql-releases` — binaries only, no source. Source is private (`No1MLEngineer/haql`).*
