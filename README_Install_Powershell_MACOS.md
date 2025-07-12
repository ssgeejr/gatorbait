## ✅ How to Install PowerShell 7+ on macOS

### 🔹 Option 1: **Homebrew (Recommended)**

If you use [Homebrew](https://brew.sh):

```bash
brew install --cask powershell
```

Then run it with:

```bash
pwsh
```

### 🔹 Option 2: **Direct .pkg Download**

1. Go to: [GitHub PowerShell Releases](https://github.com/PowerShell/PowerShell/releases)
2. Download the latest `.pkg` file for macOS
3. Install it using the macOS Installer
4. Launch it with:

   ```bash
   pwsh
   ```

---

## ✅ How to Confirm Version

```powershell
$PSVersionTable.PSVersion
```

---

## ✅ macOS Compatibility

| PowerShell            | Compatible macOS                                                 |
| --------------------- | ---------------------------------------------------------------- |
| 7.0+                  | macOS 10.13+                                                     |
| 7.2–7.5               | macOS 10.14+                                                     |
| Native Apple Silicon? | ✅ Yes, PowerShell 7.2+ has ARM64-native builds for M1/M2/M3 Macs |

---

## ✅ Pro Tip

If you want to **set `pwsh` as your default shell** on macOS:

```bash
chsh -s /usr/local/bin/pwsh
```

Or wherever Homebrew installed it (you can confirm path with `which pwsh`).

---

## ✅ Step-by-Step: Install Microsoft Graph Modules on macOS

### 🔹 1. Open PowerShell

```bash
pwsh
```

### 🔹 2. Trust the PowerShell Gallery (if prompted)

If you've never installed from the gallery:

```powershell
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
```

---

### 🔹 3. Install the Full Graph SDK (Recommended)

This gets you everything you need (and more):

```powershell
Install-Module Microsoft.Graph -Scope AllUsers -Force
```

✅ This includes all common submodules:

* `Microsoft.Graph.Authentication`
* `Microsoft.Graph.Users`
* `Microsoft.Graph.Identity.SignIns`
* ... and over 30 more

---

### 🔹 4. (Optional) Install Specific Modules Only

If you're tight on disk space or just want the essentials:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope AllUsers -Force
Install-Module Microsoft.Graph.Users -Scope AllUsers -Force
Install-Module Microsoft.Graph.Identity.SignIns -Scope AllUsers -Force
```

---

### 🔹 5. Verify Install

```powershell
Get-Module -ListAvailable Microsoft.Graph.*
```

You should see output like:

```
ModuleType Version    Name                                 ExportedCommands
---------- -------    ----                                 ----------------
Script     1.27.0     Microsoft.Graph.Authentication       {Connect-MgGraph, Disconnect-MgGraph, Select-MgProfile}
Script     1.27.0     Microsoft.Graph.Users                {Get-MgUser, New-MgUser, Remove-MgUser, Update-MgUser}
...
```

---

## ✅ Try It Out

```powershell
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"
Get-MgUser -Top 5
```

> If you’re using **client credential auth** (no MFA), I can walk you through setting that up too — just say the word.

---
