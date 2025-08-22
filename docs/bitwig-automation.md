# Bitwig Studio Automation for winget-pkgs

This automation helps keep the Bitwig Studio package in winget-pkgs up to date by automatically checking for new releases and creating pull requests with updated manifests.

## 🤖 What it does

- **Monitors**: Checks Bitwig's download page daily for new releases
- **Downloads**: Automatically downloads new installers and calculates checksums
- **Creates**: Generates complete winget manifest files
- **Submits**: Opens pull requests with the new package version

## 📁 Files

- **`.github/workflows/bitwig-auto-update.yml`** - GitHub Actions workflow for automation
- **`Tools/Update-BitwigManifest.ps1`** - Standalone PowerShell script for manual updates
- **`Tools/Setup-BitwigAutomation.ps1`** - Setup helper script

## 🚀 Quick Start

1. **Run the setup script:**

   ```powershell
   .\Tools\Setup-BitwigAutomation.ps1
   ```

2. **Commit the automation files:**

   ```bash
   git add .github/workflows/bitwig-auto-update.yml Tools/Update-BitwigManifest.ps1
   git commit -m "Add Bitwig Studio automation"
   git push
   ```

3. **Enable GitHub Actions** in your repository settings if not already enabled.

## 🔧 Manual Usage

You can also run the update script manually:

```powershell
# Check for latest version and create manifests
.\Tools\Update-BitwigManifest.ps1

# Create manifests for a specific version
.\Tools\Update-BitwigManifest.ps1 -Version "5.3.14"

# Force overwrite existing manifests
.\Tools\Update-BitwigManifest.ps1 -Force

# Test without downloading (useful for development)
.\Tools\Update-BitwigManifest.ps1 -SkipDownload
```

## ⚙️ Configuration

### GitHub Actions Schedule

The workflow runs daily at 10:00 AM UTC. You can modify this in `.github/workflows/bitwig-auto-update.yml`:

```yaml
schedule:
  - cron: "0 10 * * *" # Change this line
```

### Manual Trigger

You can trigger the workflow manually from the GitHub Actions tab in your repository.

## 📋 How it works

### Automatic Process (GitHub Actions)

1. **Version Check**: Scrapes Bitwig's download page for the latest version
2. **Validation**: Checks if the version already exists in manifests
3. **Download**: Downloads the Windows installer from Bitwig's CDN
4. **Checksum**: Calculates SHA256 hash of the installer
5. **Manifest Creation**: Generates all three required YAML files:
   - `bitwig.bitwig.yaml` (version manifest)
   - `bitwig.bitwig.installer.yaml` (installer manifest)
   - `bitwig.bitwig.locale.en-US.yaml` (locale manifest)
6. **Pull Request**: Creates a new branch and opens a PR with the changes

### URL Pattern

Bitwig uses a predictable URL pattern for downloads:

```
https://www.bitwig.com/dl/Bitwig%20Studio/{VERSION}/installer_windows/
```

The automation detects the latest version from their main download page and constructs the appropriate URL.

## 🔍 Monitoring

### GitHub Actions

- Check the "Actions" tab in your GitHub repository
- The workflow is named "Auto-update Bitwig Studio"
- Failed runs will show error details

### Notifications

The workflow will:

- ✅ Create a PR when a new version is found
- ℹ️ Do nothing when no new version is available
- ❌ Fail and log errors if something goes wrong

## 🛠️ Troubleshooting

### Common Issues

1. **Workflow not running**

   - Check if GitHub Actions is enabled in repository settings
   - Verify the workflow file is in `.github/workflows/`
   - Ensure you've pushed the changes to your repository

2. **Download failures**

   - Bitwig may have changed their URL structure
   - Check if the installer URL is accessible
   - Review the error logs in GitHub Actions

3. **Checksum mismatches**
   - The installer might have been updated after release
   - Try running the script again
   - Manually verify the installer integrity

### Debug Mode

Run the manual script with verbose output:

```powershell
$VerbosePreference = "Continue"
.\Tools\Update-BitwigManifest.ps1 -Verbose
```

## 🔒 Security

- The automation only reads from Bitwig's official website
- It doesn't execute downloaded installers, only calculates checksums
- All network requests use HTTPS
- No sensitive data is stored or transmitted

## 🤝 Contributing

If you find issues with the automation:

1. Check the error logs in GitHub Actions
2. Test the manual script locally
3. Open an issue with relevant error messages
4. Submit a PR with fixes if you identify the problem

## 📝 Customization

### For Other Packages

You can adapt this automation for other software packages by:

1. Modifying the version detection logic in the scripts
2. Updating the URL patterns for downloads
3. Adjusting the manifest templates
4. Changing the package identifier and metadata

### Extended Monitoring

You can extend the automation to:

- Check multiple software packages
- Send notifications to Slack/Discord
- Integrate with package testing
- Add more sophisticated version comparison

## 🏷️ Version History

- **v1.0** - Initial automation for Bitwig Studio
- Supports automatic version detection
- Creates complete winget manifests
- GitHub Actions integration
- Manual script execution

---

**Note**: This automation is community-maintained and not officially supported by Bitwig GmbH or Microsoft.
