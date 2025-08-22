# 🔀 Fork Workflow Strategy: Keeping Automation Isolated

This document explains how to manage a winget-pkgs fork with automation tools while ensuring those tools never pollute upstream pull requests.

## 🎯 **The Problem**

When you add automation tools to your winget-pkgs fork:

- ❌ GitHub Actions workflows get included in upstream PRs
- ❌ Custom scripts pollute the Microsoft repository
- ❌ Automation files cause merge conflicts
- ❌ Your PRs get rejected for containing unwanted files

## ✅ **The Solution: Branch Isolation Strategy**

We use a **three-branch strategy** to keep automation isolated:

```
📦 Your Fork Repository
├── 🌟 master branch          (Clean, syncs with upstream)
├── 🤖 automation branch      (Contains your automation tools)
└── 📋 package-* branches     (Clean branches for individual PRs)
```

## 🛠️ **Setup Process**

### **1. Initial Setup**

```powershell
# From your automation branch (where automation files exist)
.\Tools\Manage-ForkWorkflow.ps1 -Action setup
```

This will:

- ✅ Create clean `master` branch synced with upstream
- ✅ Keep automation files isolated in `automation` branch
- ✅ Set up proper remote tracking

### **2. Configure GitHub Actions**

The automation workflow is configured to:

- ✅ Only run on `automation` branch
- ✅ Create PRs targeting `automation` branch
- ✅ Never interfere with clean upstream PRs

```yaml
on:
  schedule:
    - cron: "0 10 * * *" # Daily checks
  push:
    branches:
      - automation # Only runs on automation branch
```

## 📋 **Daily Workflow**

### **For Automated Updates**

1. **Automation runs daily** on `automation` branch
2. **Finds new Bitwig versions** and creates manifests
3. **Creates PR within your fork** (automation → automation)
4. **You review and merge** the automation PR
5. **Clean manifest files** are now in your `automation` branch

### **For Upstream Contributions**

When you want to contribute a package to Microsoft's repo:

```powershell
# 1. Create a clean PR branch from master
.\Tools\Manage-ForkWorkflow.ps1 -Action create-pr
# Enter package name: bitwig.bitwig
# Enter version: 5.3.14

# 2. Copy manifest files from automation branch
git checkout automation
cp -r "manifests/b/bitwig/bitwig/5.3.14" /tmp/
git checkout bitwig.bitwig-5.3.14
cp -r /tmp/5.3.14 "manifests/b/bitwig/bitwig/"

# 3. Commit and push
git add manifests/b/bitwig/bitwig/5.3.14/
git commit -m "Add Bitwig Studio 5.3.14"
git push -u origin bitwig.bitwig-5.3.14

# 4. Create PR to upstream Microsoft repo
# This branch contains ZERO automation files! ✅
```

## 🔄 **Sync with Upstream**

Regularly sync your branches with upstream:

```powershell
.\Tools\Manage-ForkWorkflow.ps1 -Action sync
```

This will:

- ✅ Fetch latest changes from Microsoft's repo
- ✅ Update your clean `master` branch
- ✅ Merge upstream changes into `automation` branch
- ✅ Keep everything in sync

## 📊 **Branch Structure Explained**

### **🌟 Master Branch**

- **Purpose**: Clean sync with upstream Microsoft repo
- **Contains**: Only official winget-pkgs content
- **Never contains**: Automation files, custom scripts, GitHub Actions
- **Used for**: Creating clean PR branches

### **🤖 Automation Branch**

- **Purpose**: Contains your automation tools
- **Contains**: GitHub Actions, PowerShell scripts, automation manifests
- **Never used for**: Upstream PRs
- **Used for**: Running automation, managing your tools

### **📋 Package Branches (e.g., bitwig.bitwig-5.3.14)**

- **Purpose**: Clean branches for individual upstream PRs
- **Contains**: Only the specific package manifests for one version
- **Created from**: Clean `master` branch
- **Used for**: Submitting PRs to Microsoft's repo

## 🔍 **Verification Commands**

Check your setup is working correctly:

```powershell
# Check current status
.\Tools\Manage-ForkWorkflow.ps1 -Action status

# Verify master branch is clean
git checkout master
ls .github/workflows/  # Should be empty or contain only MS files
ls Tools/Update-Bitwig* # Should not exist

# Verify automation branch has your tools
git checkout automation
ls .github/workflows/bitwig* # Should exist
ls Tools/Update-Bitwig*      # Should exist
```

## 🚨 **Important Reminders**

### **DO ✅**

- Keep automation files only in `automation` branch
- Create PR branches from clean `master`
- Sync regularly with upstream
- Use the management script for consistency

### **DON'T ❌**

- Add automation files to `master` branch
- Create PRs directly from `automation` branch
- Mix automation files with package manifests in PR branches
- Forget to sync with upstream regularly

## 🛡️ **Fail-Safe Checks**

Before creating any upstream PR, verify it's clean:

```powershell
# Switch to your PR branch
git checkout bitwig.bitwig-5.3.14

# Check for automation files (should return False)
Test-Path ".github/workflows/bitwig-auto-update.yml"
Test-Path "Tools/Update-BitwigManifest.ps1"
Test-Path "Tools/Manage-ForkWorkflow.ps1"

# Only package manifests should exist
ls manifests/b/bitwig/bitwig/5.3.14/
```

## 📈 **Benefits of This Approach**

✅ **Clean upstream PRs** - No automation pollution  
✅ **Automated maintenance** - Daily version checks continue working  
✅ **Easy management** - Scripts handle the complexity  
✅ **Sync safety** - No merge conflicts with upstream  
✅ **Professional workflow** - Follows Git best practices

## 🆘 **Troubleshooting**

### Problem: Automation files appear in PR

```powershell
# Fix: Recreate branch from clean master
git checkout master
git branch -D problematic-branch
.\Tools\Manage-ForkWorkflow.ps1 -Action create-pr
```

### Problem: GitHub Actions not running

```powershell
# Check you're on automation branch
git checkout automation
git push origin automation  # Trigger workflow
```

### Problem: Merge conflicts during sync

```powershell
# Reset automation branch and reapply changes
git checkout automation
git reset --hard origin/automation
.\Tools\Manage-ForkWorkflow.ps1 -Action sync
```

---

**🎉 Result**: You now have a professional fork management strategy that keeps your automation tools isolated while enabling clean contributions to the upstream repository!
