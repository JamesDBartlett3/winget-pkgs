# Bitwig Studio Automation for winget-pkgs

This automation keeps the Bitwig Studio package in a fork up to date by checking for new releases, generating a current manifest set, validating it, and opening a review PR into your fork's `master` branch.

## 🤖 What it does

- **Monitors**: Checks Bitwig's download page daily for new releases
- **Downloads**: Retrieves the available Windows installers and calculates checksums
- **Generates**: Creates the three required winget manifest files in the current repository format
- **Validates**: Runs `winget validate` before opening a PR
- **Submits**: Opens a review PR in your fork

## 📁 Files

- **`.github/workflows/bitwig-auto-update.yml`** - GitHub Actions workflow for fork automation
- **`Tools/Update-BitwigManifest.ps1`** - Standalone PowerShell script for manual updates
- **`Tools/Setup-BitwigAutomation.ps1`** - Setup helper script

## 🚀 Quick Start

1. **Run the setup script:**

   ```powershell
   .\Tools\Setup-BitwigAutomation.ps1
   ```

2. **Commit the automation files:**

   ```bash
   git add .github/workflows/bitwig-auto-update.yml Tools/Update-BitwigManifest.ps1 Tools/Setup-BitwigAutomation.ps1
   git commit -m "Add Bitwig Studio automation"
   git push
   ```

3. **Choose the branch model you want:**

   - **Simplest**: keep the workflow on your fork's default branch.
   - **Isolated**: keep the workflow on an `automation` branch and make that branch the fork's default branch so scheduled runs stay active.

4. **Enable GitHub Actions** in your fork if not already enabled.

## 🔧 Manual Usage

You can also run the update script manually:

```powershell
# Check for the latest version and create manifests
.\Tools\Update-BitwigManifest.ps1

# Create manifests for a specific version
.\Tools\Update-BitwigManifest.ps1 -Version "5.3.14"

# Force overwrite existing manifests
.\Tools\Update-BitwigManifest.ps1 -Force

# Dry run without downloading installers
.\Tools\Update-BitwigManifest.ps1 -SkipDownload
```

## ⚙️ How it works

### Automatic Process (GitHub Actions)

1. **Version Check**: Scrapes Bitwig's download page for the latest version
2. **Comparison**: Checks whether that version already exists in `manifests/b/bitwig/bitwig/`
3. **Download**: Downloads the available Windows installers from Bitwig
4. **Metadata**: Calculates SHA256 hashes and reads MSI ProductCodes when they are available
5. **Manifest Creation**: Generates all three required YAML files
6. **Validation**: Runs `winget validate --manifest <folder>`
7. **Pull Request**: Opens a review PR in your fork, always targeting `master`

### URL Pattern

Bitwig uses predictable download URLs:

```text
https://www.bitwig.com/dl/Bitwig%20Studio/{VERSION}/installer_windows/
https://www.bitwig.com/dl/Bitwig%20Studio/{VERSION}/installer_windowsarm/
```

The automation tries the x64 installer first and adds the arm64 installer when Bitwig publishes it.

## 🔍 Monitoring

- Check the **Actions** tab in your fork
- The workflow is named **Auto-update Bitwig Studio**
- Failed runs will show download, generation, or validation errors directly in the logs

## 🛠️ Troubleshooting

### Workflow not running

- Check that GitHub Actions is enabled in your fork
- Confirm the workflow file is on the fork's default branch
- If you isolate the workflow on `automation`, make sure `automation` is the fork's default branch

### Validation failures

- Review the workflow logs for the `winget validate` output
- Run the script locally on Windows to reproduce the failure
- Compare the generated manifests with the latest committed Bitwig manifest folder

### Download failures

- Bitwig may have changed its URL layout
- Review the workflow logs to see which installer URL failed
- Retry manually with `.\Tools\Update-BitwigManifest.ps1 -Version <version>`

## 📤 Upstream submission

This workflow intentionally stops after creating a review PR in your fork. Once you are satisfied with the generated manifests, copy the single version folder into a clean contribution branch and submit that branch to `microsoft/winget-pkgs`.

## 📝 Notes

- The automation is designed for a fork, not for direct submission to the upstream repository.
- Review PRs are always based on your fork's `master` branch so automation-only branch content is excluded.
- `-SkipDownload` is only for dry runs; it does not produce submission-ready manifests.
- The workflow validates generated manifests before opening a PR.
