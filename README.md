# nvm-use: Session-Isolated Node Switching for NVM

A lightweight companion utility script for `NVM` - Node Version Manager (`nvm-windows` on Windows and `nvm` on Mac/Linux) to switch node version per terminal with zero temporary symlink, zero filesystem side effects, and absolute predictability.

### Why this nvm-use?
* **On Windows (`nvm-windows`):** Native NVM modifies a single global symlink. Changing versions in Terminal A changes it for Terminal B instantly. `nvm-use` bypasses the global symlink entirely, allowing you to run completely different Node versions in concurrent terminal windows.

## 🚀 The Core Philosophy
* **Pure Process Isolation:** Uses lightweight environment path swapping to safely adjust the active runtime in the current window without polluting other terminals.
* **Instant Startups:** Removes heavy startup valuation blocks from your profile files for instant shell initialization.

## 🛠️ Phase 1.1: Fresh Installation

> If you have already installed nvm, skip this step and go to Phase 1.2.

Go to the NVM Site(s) and follow the installation instructions for your operating system.
- [NVM Documentation - nvmnode.com](https://www.nvmnode.com/)
- [nvm-windows - GitHub](https://github.com/coreybutler/nvm-windows) - for Windows
- [nvm - GitHub](https://github.com/nvm-sh/nvm) - for Mac/Linux


## 🛠️ Phase 1.2: Existing Installation Directory Lookup/Verification

Locate your existing `nvm` home directory which contains the `nvm` executable. Use the commands `which nvm` or `where nvm` for lookup or find it from the Environment Variables:

Windows Env. Variables: `NVM_HOME` and `NVM_SYMLINK`

- Windows Command Prompt: `echo %NVM_HOME%`, `echo %NVM_SYMLINK%`

- Git-Bash(Windows): `echo $NVM_HOME`

Mac/Linux Env. Variable: `NVM_DIR`

- zsh/bash: `echo $NVM_DIR`

## 🌐 Phase 2: Global Environment Variables

Verify your User/System environment variables to establish `nvm`'s directory and map your system-wide fallback default node version in PATH.

### Windows Environment Variables

Configure these under **System Properties > Environment Variables**:

| Variable Type | Variable Name | Value | Purpose |
| :--- | :--- | :--- | :--- |
| **User/System** | `NVM_HOME` | `C:\nvm` *(or your custom path)* | Holds nvm binaries and node versions |
| **User/System** | `NVM_SYMLINK` | `C:\nvm\nodejs` *(or your custom path)* | the default node version symlink |
| **User/System** | `PATH` | *Append Entry* `%NVM_HOME%` | Makes the raw `nvm` executables globally accessible |
| **User/System** | `PATH` | *Append Entry* `%NVM_SYMLINK%` | Makes the default node version globally accessible |

> 💡 *Note: Place these entries high up in your `PATH` variable list (ideally right under your central utility binaries folder) to guarantee priority over rogue third-party software installers.*

## 📂 Phase 3: The Companion Scripts

Download and save the scripts (`nvm-use.cmd` and `nvm-use.sh`) and place them directly inside `NVM_HOME` or `NVM_DIR` folder (`C:\nvm` | `$HOME/.nvm`) so they are immediately accessible globally.

### 1. For Command Prompt / PowerShell (Windows) - `nvm-use.cmd` and `use.cmd`
1. Download and Save `nvm-use.cmd` and `use.cmd` files in `NVM_HOME` folder.

2. Make sure environment variables `NVM_HOME` and `NVM_SYMLINK` are set in your Windows System Properties environment variables panel. That's it you are all set.

### 2. For Git-Bash (Windows) - `nvm-use.sh`
1. Download and Save `nvm-use.sh` file in `NVM_HOME` folder.

2. Make sure environment variables `NVM_HOME` and `NVM_SYMLINK` are set in your Windows System Properties environment variables panel.

3. Append the following alias line to your user profile setup (`~/.bash_profile` (preferred) or `~/.bashrc`):

```bash
alias nvm-use='source "$(cygpath -u "$NVM_HOME")/nvm-use.sh"'
# alias use='source "$(cygpath -u "$NVM_HOME")/nvm-use.sh"' # Uncomment if you want it even shorter
```

That's it you are all set.

### 3. For macOS & Linux (Zsh / Bash) - `nvm-use.sh`
1. Download and Save `nvm-use.sh` file in `$NVM_DIR/version-switch` (e.g. ~/.nvm/version-switch) folder.

2. Make sure environment variables `NVM_DIR` is set in your user profile file (`~/.zprofile` (preferred) or `~/.zhrc` or `~/.bash_profile` (preferred) or `~/.bashrc`).

3. Append the following alias line to your user profile setup (`~/.zprofile` (preferred) or `~/.zhrc` or `~/.bash_profile` (preferred) or `~/.bashrc`):

```bash
# Add the nvm-use alias pointer. Adjust the folder where nvm-use.sh is saved.
alias nvm-use='source "$HOME/.nvm/version-switch/nvm-use.sh"'
# alias use='source "$HOME/.nvm/version-switch/nvm-use.sh"' # Uncomment if you want it even shorter
```

That's it you are all set.

## 📖 Command Cheat Sheet & Workflow

With this architecture implemented, use the native `nvm` engine exclusively for downloading node versions, and use this lightweight scripts for interactive version switching.

### 1. View Local Versions
Lists all versions safely extracted to your device.
```cmd
nvm list
```

### 2. Download a New Node version
Downloads and unzips a node environment cleanly into your nvm directory.
```cmd
nvm install 24
```

### 3. Establish System-Wide Default
Updates the static global default fallback link. Every newly initialized terminal tab or external system application boots with this version of choice by default.

#### Windows, Git-Bash
```cmd
nvm use 24
```

#### Mac/Linux (*Need to start a new terminal to use the default*)
```cmd
nvm alias default 24
```

### 4. Switch Shell Node Version using *`nvm-use`*
Mounts your targeted environment dynamically to the current shell window instantly without any side effects.
```cmd
nvm-use 22          :: Exact or partial major-version lookup
nvm-use v22.23.1    :: Precise version matching
nvm-use             :: Smart scanning for local .node-version or .nvmrc configuration files
nvm-use 22 default  :: Mounts version 22 and updates global NVM default profile fallback
nvm-use default 22  :: Smart argument flipping (automatically normalizes to '22 default')
nvm-use --help      :: Displays command usage interface (also accepts -h, ?, /?, help)
nvm-use --version   :: Displays current utility script version profile (also accepts -v, version)
```

### 5. Standard Environment Inspection
```cmd
node -v
npm -v
```

### 6. Manage Global Packages Across Node Versions

If you want to manage common global packages across different Node versions, try [`npm-g`](https://github.com/sucom/npm-g).

## ⚖️ LICENSE

MIT