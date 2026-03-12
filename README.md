# Clip-Tree

<p align="left">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" />
  <img src="https://img.shields.io/powershellgallery/v/Clip-Tree.svg" alt="PowerShell Gallery Version" />
  <img src="https://img.shields.io/powershellgallery/dt/Clip-Tree.svg" alt="PowerShell Gallery Downloads" />
  <img src="https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows&logoColor=white" alt="Platform: Windows" />
</p>

**Clip-Tree** is a high-speed PowerShell utility designed to capture directory structures as clean, text-based trees and pipe them directly to your clipboard. 

It is specifically built for developers who need to provide instant project context to Large Language Models (LLMs) like ChatGPT and Claude, or generate file-structure documentation without manual formatting.

---

## Installation

The most efficient way to install Clip-Tree is directly from the PowerShell Gallery.

```powershell
Install-Module -Name Clip-Tree -Scope CurrentUser
```

---

## Features

* **Instant Recursive Mapping:** Quickly generates a visual representation of any directory depth.
* **Automatic Clipboard Integration:** Copies the generated tree to your clipboard immediately upon execution.
* **LLM Optimization:** Uses a clean indentation style that is highly readable for AI models and documentation.
* **Multiple Visual Styles:** Supports different branch characters to suit your documentation needs.

---

## Usage

Once installed, the module provides a primary command and several shorthand aliases for speed.

```powershell
# Use the default shorthand alias
ct

# Use the full cmdlet name
Get-Tree

# Target a specific path and style
ct -Path ./src -Style Modern

```

### Command Reference

| Command | Type | Description |
| --- | --- | --- |
| `Get-Tree` | Function | The primary command to generate and copy the tree structure. |
| `ct` | Alias | Shorthand for Get-Tree. |
| `gt` | Alias | Shorthand for Get-Tree. |
| `clip-tree` | Alias | Shorthall for Get-Tree. |
| `Update-TreeConfig` | Function | Sets and saves your default style preferences. |

---

## Configuration

You can customize the default behavior of Clip-Tree so you don't have to pass parameters every time.

### Change Default Style

Available styles: `Classic` (+/-), `Modern` (├─), `Visual` (folder icons), or `None`.

```powershell
Update-TreeConfig -Style Modern
```

### Toggle Quiet Mode

To suppress the "Copied to clipboard" notification:

```powershell
Update-TreeConfig -Quiet $true
```

---

## Uninstallation

To completely remove the module from your system:

```powershell
Uninstall-Module -Name Clip-Tree
```

---

## Repository

[https://github.com/Luqmaan-Abdallah/clip-tree](https://github.com/Luqmaan-Abdallah/clip-tree)

## PSGallery
[https://www.powershellgallery.com/packages/Clip-Tree](https://www.powershellgallery.com/packages/Clip-Tree/1.0.1)
