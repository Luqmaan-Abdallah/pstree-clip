## Clip-Tree

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows&logoColor=white)

**Clip-Tree** is a PowerShell utility designed to capture directory structures as clean, text-based trees and pipe them directly to your clipboard. It is built for developers who need to provide instant project context to LLMs or generate quick file-structure documentation without manual formatting.

---

## Features

* **Recursive Mapping:** Generates a visual tree of the current directory.
* **Auto-Clipboard:** No file output management needed; the tree is copied to your clipboard instantly.
* **LLM Optimized:** Produces a clean indentation style that is easily parsed by Claude, GPT, and other models.
* **Global Access:** Once installed, the command is available from any terminal session via your PowerShell profile.

---

## Installation

### GUI Method (Recommended)

Run the graphical installer to handle directory setup and profile linking automatically:

```powershell
.\Install-Clip-Tree-GUI.ps1

```

### CLI Method

For a head-less setup, use the CLI installer:

```powershell
.\Install-Clip-Tree-CLI.ps1

```

---

## Usage

Once the installation is complete, restart your terminal. You can use the primary command or the shorthand aliases:

```powershell
# Primary command
Clip-Tree

# Shorthand aliases
ct
clip-tree

```

The script will scan the current directory and notify you once the tree is ready in your clipboard.

---

## Uninstallation

To remove the tool and clean the loader from your `$PROFILE`, run the uninstaller:

```powershell
.\Uninstall-Clip-Tree-GUI.ps1
# OR
.\Uninstall-Clip-Tree-CLI.ps1

```

---

**Repo:** [https://github.com/Luqmaan-Abdallah/clip-tree](https://github.com/Luqmaan-Abdallah/clip-tree)
