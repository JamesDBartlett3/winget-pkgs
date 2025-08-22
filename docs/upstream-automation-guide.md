# 🚀 Automated Upstream PR Creation Guide

This guide explains how to set up automation that will automatically create pull requests directly to Microsoft's winget-pkgs repository when new Bitwig Studio releases are detected.

## 🎯 **Two Automation Options**

### **Option 1: Fork-Only Automation (Current Setup) ✅**
- Creates PRs within your fork (automation branch)
- You manually create clean PRs to upstream
- **Pros**: Simple, safe, no special permissions needed
- **Cons**: Requires manual step to create upstream PR

### **Option 2: Direct Upstream Automation 🚀**
- Automatically creates PRs to Microsoft's winget-pkgs repo
- Completely hands-off once configured
- **Pros**: Fully automated, zero manual intervention
- **Cons**: Requires Personal Access Token setup

## 🔧 **Setting Up Direct Upstream Automation**

If you want the automation to create PRs directly to Microsoft's repo, follow these steps:

### **Step 1: Create Personal Access Token**

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Set these permissions:
   - ✅ `public_repo` (for creating PRs to public repos)
   - ✅ `workflow` (for triggering workflows)
4. Set expiration (recommended: 1 year)
5. Copy the token (you won't see it again!)

### **Step 2: Add Token to Repository Secrets**

1. Go to your fork repository settings
2. Navigate to "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Name: `PAT_TOKEN`
5. Value: Paste your personal access token
6. Click "Add secret"

### **Step 3: Enable the Upstream Workflow**

The upstream workflow is already created at `.github/workflows/bitwig-auto-update-upstream.yml`.

To activate it:

```powershell
# Switch to automation branch
git checkout automation

# The upstream workflow is ready to use
# Just ensure PAT_TOKEN secret is configured
```

### **Step 4: Configure GitHub CLI (for the workflow)**

The workflow uses GitHub CLI internally. It's pre-installed on GitHub Actions runners, so no additional setup needed.

## ⚡ **How Direct Upstream Automation Works**

When enabled, the automation will:

1. **🔍 Daily Check** - Monitors Bitwig's download page at 10 AM UTC
2. **📥 Version Detection** - Checks if new version exists in upstream repo
3. **⬇️ Download & Verify** - Downloads installer and calculates checksum
4. **📝 Create Manifests** - Generates all three required YAML files
5. **🌿 Create Branch** - Creates branch from upstream master
6. **📤 Push to Fork** - Pushes new branch to your fork
7. **🔄 Create Upstream PR** - Opens PR from your fork to Microsoft's repo

### **Example Workflow:**

```
Bitwig releases 5.3.14
       ↓
Automation detects new version
       ↓
Creates branch: bitwig.bitwig-5.3.14-automated
       ↓
Downloads installer, calculates SHA256
       ↓
Creates manifest files in your fork
       ↓
Opens PR: YourFork:bitwig.bitwig-5.3.14-automated → microsoft:master
       ↓
Microsoft team reviews and merges
```

## 🛡️ **Security Considerations**

### **Personal Access Token Security:**
- ✅ Store only in GitHub Secrets (never commit to code)
- ✅ Use minimal required permissions
- ✅ Set reasonable expiration dates
- ✅ Rotate tokens periodically

### **Automation Safety:**
- ✅ Only downloads from official Bitwig URLs
- ✅ Validates checksums before creating PR
- ✅ Creates descriptive PR with full verification details
- ✅ Microsoft team still reviews before merging

## 📋 **Switching Between Modes**

### **Currently Active: Fork-Only Mode**
```powershell
# Check current workflows
ls .github/workflows/

# You'll see:
# bitwig-auto-update.yml (creates PRs to your fork)
```

### **To Enable Direct Upstream Mode:**
```powershell
# 1. Ensure PAT_TOKEN secret is configured in GitHub
# 2. Both workflows will be available:
#    - bitwig-auto-update.yml (fork PRs)
#    - bitwig-auto-update-upstream.yml (upstream PRs)

# 3. You can disable fork-only mode by renaming the file:
git mv .github/workflows/bitwig-auto-update.yml .github/workflows/bitwig-auto-update.yml.disabled
git commit -m "Switch to upstream-only automation"
```

### **To Use Both Modes:**
You can run both workflows simultaneously:
- Fork workflow creates PRs for your review
- Upstream workflow creates direct PRs to Microsoft

This gives you a staging area to review before upstream submission.

## 🔍 **Testing the Setup**

### **Test Fork-Only Mode:**
```powershell
# Trigger manual run
# Go to GitHub Actions tab → "Auto-update Bitwig Studio" → "Run workflow"
```

### **Test Direct Upstream Mode:**
```powershell
# 1. Ensure PAT_TOKEN is configured
# 2. Go to GitHub Actions tab → "Auto-update Bitwig Studio (Direct to Upstream)" → "Run workflow"
# 3. Check if PR appears in microsoft/winget-pkgs
```

## 📊 **Monitoring Automation**

### **GitHub Actions Tab:**
- Monitor workflow runs
- Check logs for errors
- View success/failure status

### **Expected Outcomes:**
- ✅ **New version found**: PR created automatically
- ℹ️ **No new version**: Workflow completes with no action
- ❌ **Error**: Check logs for download/validation issues

### **Email Notifications:**
GitHub can email you about workflow failures:
1. Go to GitHub Settings → Notifications
2. Enable "Actions" notifications
3. You'll get emails if automation fails

## 🆘 **Troubleshooting**

### **PAT Token Issues:**
```bash
# Error: "Bad credentials" or "Not found"
# Solution: Regenerate PAT token with correct permissions
```

### **Permission Issues:**
```bash
# Error: "Resource not accessible by integration"
# Solution: Ensure PAT has 'public_repo' scope
```

### **Workflow Not Running:**
```bash
# Check if workflow is enabled in GitHub Actions tab
# Ensure PAT_TOKEN secret exists and is spelled correctly
```

### **PR Creation Fails:**
```bash
# Check GitHub CLI authentication in workflow logs
# Verify your fork has the automation branch pushed
```

## 🎉 **Result**

With direct upstream automation enabled:

1. **🔄 Fully Automated**: Zero manual intervention required
2. **⚡ Fast Response**: New versions submitted within hours of release
3. **🛡️ Safe**: All standard validation and review processes maintained
4. **📝 Professional**: PRs include complete verification details
5. **🎯 Targeted**: Only creates PRs when truly new versions are available

**Microsoft's winget team gets professionally formatted, automatically verified PRs for every new Bitwig Studio release!** 🚀
