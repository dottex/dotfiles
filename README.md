# Universal Fast Development Environment & Dotfiles

A lightweight, fast, and idempotent environment bootstrap system designed to work seamlessly across:
- 🚀 **GitHub Codespaces** (native dotfiles support)
- 💻 **ChromeOS (Crostini Linux)**
- ☁️ **Google Cloud Shell** (automatic `.customize_environment`)
- ⚡ **Ephemeral & Temporary Linux VMs** (Ubuntu / Debian / AWS / GCP)

---

## 📦 What's Included

| Component | Tool / Feature | Details |
| :--- | :--- | :--- |
| **Time Tracking** | [Timewarrior](https://timewarrior.net/) (`timew`, `tw`) | Command-line time tracking |
| **Tasks & Notes** | [Taskbook](https://github.com/klaussinani/taskbook) (`tb`) | Minimalist terminal task & note manager |
| **Repo Manager** | [ghq](https://github.com/x-motemen/ghq) | Manage remote repository clones locally |
| **Editor** | Vim with native packages | Fast, modern `.vimrc` configuration |
| **Vim Plugins** | [vim-wakatime](https://github.com/wakatime/vim-wakatime) | Automatic coding time metrics |
| | [vimwiki](https://github.com/vimwiki/vimwiki) | Personal wiki with **Markdown syntax** (`~/vimwiki/`) |
| | [vim-surround](https://github.com/tpope/vim-surround) | Quoting/parenthesizing mappings (`ys`, `cs`, `ds`) |
| | [vim-commentary](https://github.com/tpope/vim-commentary) | Comment toggling (`gcc`, `gc`) |
| | [vim-fugitive](https://github.com/tpope/vim-fugitive) | Git integration inside Vim |
| | [vim-sensible](https://github.com/tpope/vim-sensible) | Universal sensible defaults |
| | [vim-repeat](https://github.com/tpope/vim-repeat) | Extended `.` repeat for plugin maps |
| **Node / NVM** | Auto-Detects NVM vs System Node | Zero permission conflicts (`~/.npm-global` for system Node, clean prefix for NVM) |
| **Shell Aliases** | `.bash_aliases` | PATH configuration, git shortcuts, `today`, `wiki` helpers |

---

## 🚀 Quick Start / Installation

### 1. GitHub Codespaces
GitHub Codespaces automatically discovers and installs dotfiles repositories:
1. Push this repository to GitHub (e.g. `github.com/<username>/dotfiles`).
2. In your GitHub account settings, go to **Settings > Codespaces > Dotfiles**.
3. Select your dotfiles repository and enable **"Automatically install dotfiles"**.
4. Every new Codespace you launch will automatically run `install.sh`.

### 2. ChromeOS (Crostini Linux) & Local Machines
Clone and run the installer:
```bash
git clone https://github.com/<username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
source ~/.bashrc
```

### 3. Google Cloud Shell
In Google Cloud Shell, `.customize_environment` runs automatically as `root` every time your environment boots:
```bash
# Clone to ~/dotfiles and link the customization script:
git clone https://github.com/<username>/dotfiles.git ~/dotfiles
ln -sf ~/dotfiles/.customize_environment ~/.customize_environment
```
To run it immediately in Cloud Shell:
```bash
sudo ~/.customize_environment
source ~/.bashrc
```

### 4. Ephemeral / Temporary Cloud VMs (One-Liner)
When spinning up a quick temporary instance on AWS, GCP, or DigitalOcean:
```bash
git clone https://github.com/<username>/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh && source ~/.bashrc
```

---

## 🛠️ Quick Reference & Cheat Sheet

### Taskbook (`tb`)
```bash
tb                  # View all tasks and notes
tb -t "Buy coffee"  # Create a new task
tb -n "Project idea"# Create a new note
tb -c 1             # Check / uncheck task #1
tb -s 1             # Star / unstar item #1
tb -d 1             # Delete item #1
tb -l               # Show by timeline
```

### Timewarrior (`tw` / `timew`)
```bash
tw start Project    # Start tracking time on 'Project'
tw stop             # Stop tracking
tw summary :today   # View summary of time spent today
tw summary :week    # View summary of time spent this week
tw track 9am - 11am Project # Track a past block of time
```

### Vim & Vimwiki
- Run `wiki` or inside Vim press `<Leader>ww` (Space + w + w) to open your personal wiki index at `~/vimwiki/index.md`.
- Press `Enter` on any text `[[Topic]]` to jump to or create that note.
- `gcc` in normal mode or `gc` in visual mode toggles comments (via `vim-commentary`).
- `ysiw"` surrounds the current word in quotes (via `vim-surround`).
- `:G` opens Git status (via `vim-fugitive`).

### Daily Helper Command
```bash
today
```
Prints your current Taskbook list and your Timewarrior summary for today side-by-side.

---

## 📁 Repository Structure
```
.
├── install.sh                  # Main idempotent installer
├── .customize_environment      # Google Cloud Shell root startup hook
├── .vimrc                      # Sensible Vim config with Vimwiki & plugins
├── .bash_aliases               # Shell shortcuts, PATH export, and helpers
└── README.md                   # Documentation and cheat sheet
```
