# Scripts

Utility scripts for managing development environments and CLI tools.

## Environment Switcher

**Script:** `env-switch.sh`

Manages multiple Vercel and Stripe accounts, allowing you to switch between different projects/environments quickly.

### Why This Exists

When working with multiple projects (e.g., Experiment Lacrosse + The Lacrosse Lab), each may have:
- Different Vercel accounts/teams
- Different Stripe accounts (test vs live, different businesses)
- Different environment variables

This script lets you save and restore complete environment configurations.

### How It Works

- **Vercel:** Backs up and swaps the auth token stored in `~/Library/Application Support/com.vercel.cli/auth.json`
- **Stripe:** Modifies the active project in `~/.config/stripe/config.toml`
- **Profiles:** Stores combined Vercel + Stripe configurations in `~/.config/env-switch/profiles/`

### Shell Aliases

These aliases are added to `~/.zshrc` for natural language usage:

#### Status & Information

| Command | Description |
|---------|-------------|
| `show-env` | Show current Vercel and Stripe accounts |
| `which-env` | Same as `show-env` |
| `current-env` | Same as `show-env` |
| `list-envs` | List all saved environment profiles |

#### Switching Environments

| Command | Description |
|---------|-------------|
| `switch-env` | Interactive menu for all options |
| `load-env <name>` | Load a saved profile by name |
| `use-env <name>` | Same as `load-env` |
| `save-env <name>` | Save current setup as a new profile |

#### Vercel-Specific

| Command | Description |
|---------|-------------|
| `switch-vercel` | List saved Vercel accounts |
| `switch-vercel <name>` | Switch to a specific Vercel account |
| `use-vercel <name>` | Same as above |
| `vercel-accounts` | List saved Vercel accounts |
| `switch-vercel login` | Login to a new Vercel account |
| `switch-vercel save <name>` | Save current Vercel login |

#### Stripe-Specific

| Command | Description |
|---------|-------------|
| `switch-stripe` | List Stripe accounts |
| `switch-stripe <name>` | Switch to a specific Stripe account |
| `use-stripe <name>` | Same as above |
| `stripe-accounts` | List Stripe accounts |

#### Project Shortcuts

| Command | Description |
|---------|-------------|
| `use-experiment` | Switch to experiment-lacrosse profile |
| `use-lacrosse-lab` | Switch to lacrosse-lab profile |

#### Dictation-Friendly (No Hyphens)

For voice input or faster typing:

| Command | Equivalent |
|---------|------------|
| `showenv` | `show-env` |
| `switchenv` | `switch-env` |
| `switchvercel` | `switch-vercel` |
| `switchstripe` | `switch-stripe` |
| `saveenv` | `save-env` |
| `loadenv` | `load-env` |

### Usage Examples

```bash
# See what environment you're currently using
show-env

# Save your current setup as a profile
save-env my-project

# Switch to a different profile
load-env other-project

# Just switch Vercel account
switch-vercel other-account

# Just switch Stripe account
switch-stripe "Other Business Name"

# Interactive menu with all options
switch-env
```

### Setting Up a New Account

```bash
# 1. Login to the new Vercel account
switch-vercel login

# 2. Save the Vercel credentials
switch-vercel save new-account-name

# 3. If needed, login to a new Stripe account
switch-stripe login

# 4. Save everything as a profile
save-env new-project-name
```

### File Locations

| File | Purpose |
|------|---------|
| `~/.config/env-switch/vercel/*.auth.json` | Saved Vercel auth tokens |
| `~/.config/env-switch/profiles/*.profile` | Saved environment profiles |
| `~/.config/stripe/config.toml` | Stripe CLI configuration |
| `~/Library/Application Support/com.vercel.cli/auth.json` | Active Vercel auth |

---

## Stripe Switcher (Legacy)

**Script:** `stripe-switch.sh`

A standalone Stripe account switcher with an interactive menu. This is now integrated into `env-switch.sh`, but remains available for Stripe-only switching.

### Usage

```bash
./stripe-switch.sh              # Interactive menu
./stripe-switch.sh --list       # List accounts
./stripe-switch.sh <name>       # Switch by name
./stripe-switch.sh --add        # Add new account
```

---

## Adding New Aliases

To add project-specific shortcuts, edit `~/.zshrc` and add:

```bash
use-myproject() { "$ENV_SWITCH" load myproject; }
```

Then run `source ~/.zshrc` to activate.
