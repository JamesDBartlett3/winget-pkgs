# 🚀 Quick Reference: Fork Workflow Commands

## 📋 **Common Tasks**

### **Setup (One-time)**

```powershell
# Set up branch structure
.\Tools\Manage-ForkWorkflow.ps1 -Action setup
```

### **Daily Maintenance**

```powershell
# Sync with upstream Microsoft repo
.\Tools\Manage-ForkWorkflow.ps1 -Action sync

# Check repository status
.\Tools\Manage-ForkWorkflow.ps1 -Action status
```

### **Creating Upstream PRs**

```powershell
# 1. Create clean PR branch
.\Tools\Manage-ForkWorkflow.ps1 -Action create-pr

# 2. Add your manifests (copy from automation branch)
git checkout automation
# Copy manifests to temporary location
git checkout your-pr-branch
# Add manifests to PR branch

# 3. Commit and push
git add manifests/
git commit -m "Add Package X.Y.Z"
git push -u origin your-pr-branch

# 4. Create PR to Microsoft repo (GitHub web interface)
```

### **Manual Package Updates**

```powershell
# Check for latest version
.\Tools\Update-BitwigManifest.ps1

# Create manifests for specific version
.\Tools\Update-BitwigManifest.ps1 -Version "5.3.14"

# Test without downloading
.\Tools\Update-BitwigManifest.ps1 -SkipDownload
```

## 🔍 **Verification Commands**

### **Check Branch Cleanliness**

```powershell
# Verify no automation files in master
git checkout master
Test-Path ".github/workflows/bitwig-*"  # Should be False
Test-Path "Tools/Update-Bitwig*"        # Should be False

# Verify automation files exist in automation branch
git checkout automation
Test-Path ".github/workflows/bitwig-*"  # Should be True
Test-Path "Tools/Update-Bitwig*"        # Should be True
```

### **Pre-PR Checklist**

```powershell
# Before creating upstream PR, verify branch is clean:
git checkout your-pr-branch

# These should all return False:
Test-Path ".github/workflows/bitwig-auto-update.yml"
Test-Path "Tools/Update-BitwigManifest.ps1"
Test-Path "Tools/Manage-ForkWorkflow.ps1"
Test-Path "docs/bitwig-automation.md"

# Only package manifests should exist:
git status  # Should show only manifests/ changes
```

## 🌳 **Branch Overview**

| Branch       | Purpose               | Contains                 | Used For               |
| ------------ | --------------------- | ------------------------ | ---------------------- |
| `master`     | Clean upstream sync   | Official files only      | Base for PR branches   |
| `automation` | Your automation tools | Scripts, workflows, docs | Running automation     |
| `package-*`  | Individual PRs        | Single package manifests | Upstream contributions |

## ⚡ **Emergency Commands**

### **Fix Polluted PR Branch**

```powershell
# Delete and recreate clean branch
git checkout master
git branch -D polluted-branch
.\Tools\Manage-ForkWorkflow.ps1 -Action create-pr
```

### **Reset Automation Branch**

```powershell
# If automation branch gets corrupted
git checkout automation
git reset --hard origin/automation
```

### **Force Sync with Upstream**

```powershell
# Nuclear option: force sync everything
git checkout master
git fetch upstream
git reset --hard upstream/master
git push origin master --force
```

## 🔗 **Useful Git Commands**

```powershell
# Show all branches
git branch -a

# Show current branch
git branch --show-current

# Show files changed in current branch vs master
git diff master --name-only

# Show remote URLs
git remote -v

# Check if automation files exist
ls .github/workflows/ | Where-Object {$_.Name -like "*bitwig*"}
```

---

💡 **Pro Tip**: Bookmark this page and keep it handy for quick reference!
