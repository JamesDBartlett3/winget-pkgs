#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Setup script for Bitwig Studio automation

.DESCRIPTION
    This script helps set up the automated Bitwig Studio manifest updater.
    It will guide you through the setup process and test the automation.

.EXAMPLE
    .\Setup-BitwigAutomation.ps1
#>

$ErrorActionPreference = "Stop"

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host ""
}

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check if we're in the right repository
    if (-not (Test-Path "manifests\b\bitwig\bitwig")) {
        Write-ColorText "❌ Error: Not in winget-pkgs repository root" "Red"
        Write-ColorText "Please run this script from the root of your winget-pkgs fork." "Yellow"
        return $false
    }
    
    # Check if .github/workflows directory exists
    if (-not (Test-Path ".github\workflows")) {
        Write-ColorText "Creating .github/workflows directory..." "Yellow"
        New-Item -ItemType Directory -Path ".github\workflows" -Force | Out-Null
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-ColorText "❌ Error: PowerShell 5.0 or later required" "Red"
        return $false
    }
    
    Write-ColorText "✅ Prerequisites check passed" "Green"
    return $true
}

function Test-GitHubSetup {
    Write-Header "Checking GitHub Setup"
    
    try {
        # Check if we're in a git repository
        $gitStatus = git status 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-ColorText "❌ Error: Not in a git repository" "Red"
            return $false
        }
        
        # Check if we have a remote
        $remotes = git remote -v 2>$null
        if (-not $remotes) {
            Write-ColorText "❌ Error: No git remotes configured" "Red"
            return $false
        }
        
        # Check if we're on a fork
        $originUrl = git remote get-url origin 2>$null
        if ($originUrl -match "microsoft/winget-pkgs") {
            Write-ColorText "⚠️  Warning: You're working on the main Microsoft repository" "Yellow"
            Write-ColorText "It's recommended to fork the repository and work from your fork." "Yellow"
            Write-ColorText "This automation will work, but PRs should come from forks." "Yellow"
        }
        
        Write-ColorText "✅ Git setup looks good" "Green"
        return $true
    } catch {
        Write-ColorText "❌ Error checking git setup: $_" "Red"
        return $false
    }
}

function Show-AutomationOptions {
    Write-Header "Automation Setup Options"
    
    Write-ColorText "Choose your automation setup:" "Yellow"
    Write-ColorText "1. 🤖 Full GitHub Actions automation (recommended)" "White"
    Write-ColorText "2. 📋 Manual script execution only" "White"
    Write-ColorText "3. 🧪 Test current setup" "White"
    Write-ColorText "4. ℹ️  Show information about automation" "White"
    Write-Host ""
    
    do {
        $choice = Read-Host "Enter your choice (1-4)"
    } while ($choice -notin @("1", "2", "3", "4"))
    
    return $choice
}

function Setup-GitHubActions {
    Write-Header "Setting up GitHub Actions Automation"
    
    $workflowFile = ".github\workflows\bitwig-auto-update.yml"
    
    if (Test-Path $workflowFile) {
        Write-ColorText "GitHub Actions workflow already exists." "Yellow"
        $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
        if ($overwrite -ne "y") {
            Write-ColorText "Skipping GitHub Actions setup." "Yellow"
            return
        }
    }
    
    Write-ColorText "✅ GitHub Actions workflow is already in place at:" "Green"
    Write-ColorText $workflowFile "Cyan"
    Write-Host ""
    
    Write-ColorText "The workflow will:" "Yellow"
    Write-ColorText "• Check for new Bitwig releases daily at 10 AM UTC" "White"
    Write-ColorText "• Download and verify installers automatically" "White"
    Write-ColorText "• Create manifest files with proper checksums" "White"
    Write-ColorText "• Open a pull request with the new version" "White"
    Write-Host ""
    
    Write-ColorText "To enable the automation:" "Yellow"
    Write-ColorText "1. Commit and push these changes to your repository" "White"
    Write-ColorText "2. The workflow will run automatically on schedule" "White"
    Write-ColorText "3. You can also trigger it manually from GitHub Actions tab" "White"
    Write-Host ""
    
    Write-ColorText "Commands to commit and push:" "Yellow"
    Write-ColorText "git add .github/workflows/bitwig-auto-update.yml Tools/Update-BitwigManifest.ps1" "Cyan"
    Write-ColorText "git commit -m `"Add Bitwig Studio automation`"" "Cyan"
    Write-ColorText "git push" "Cyan"
}

function Test-ManualScript {
    Write-Header "Testing Manual Script"
    
    $scriptPath = "Tools\Update-BitwigManifest.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-ColorText "❌ Error: Update script not found at $scriptPath" "Red"
        return
    }
    
    Write-ColorText "Testing the manual update script..." "Yellow"
    Write-ColorText "This will check for the latest Bitwig version without downloading." "White"
    Write-Host ""
    
    try {
        & $scriptPath -SkipDownload
        Write-Host ""
        Write-ColorText "✅ Manual script test completed successfully!" "Green"
    } catch {
        Write-ColorText "❌ Error testing script: $_" "Red"
    }
}

function Show-Information {
    Write-Header "Automation Information"
    
    Write-ColorText "📋 About this automation:" "Yellow"
    Write-Host ""
    
    Write-ColorText "Files created:" "White"
    Write-ColorText "• .github/workflows/bitwig-auto-update.yml - GitHub Actions workflow" "Cyan"
    Write-ColorText "• Tools/Update-BitwigManifest.ps1 - Standalone update script" "Cyan"
    Write-Host ""
    
    Write-ColorText "How it works:" "White"
    Write-ColorText "1. Checks Bitwig's download page for version information" "White"
    Write-ColorText "2. Compares against existing manifests in your repository" "White"
    Write-ColorText "3. Downloads the Windows installer if new version found" "White"
    Write-ColorText "4. Calculates SHA256 checksum automatically" "White"
    Write-ColorText "5. Creates all three required manifest files" "White"
    Write-ColorText "6. Opens a pull request with the changes" "White"
    Write-Host ""
    
    Write-ColorText "Manual usage examples:" "Yellow"
    Write-ColorText ".\Tools\Update-BitwigManifest.ps1                    # Check for latest" "Cyan"
    Write-ColorText ".\Tools\Update-BitwigManifest.ps1 -Version 5.3.14   # Specific version" "Cyan"
    Write-ColorText ".\Tools\Update-BitwigManifest.ps1 -Force             # Overwrite existing" "Cyan"
    Write-ColorText ".\Tools\Update-BitwigManifest.ps1 -SkipDownload      # Test without download" "Cyan"
    Write-Host ""
    
    Write-ColorText "GitHub Actions triggers:" "White"
    Write-ColorText "• Automatically runs daily at 10 AM UTC" "White"
    Write-ColorText "• Can be triggered manually from GitHub Actions tab" "White"
    Write-ColorText "• Only creates PR if new version is found" "White"
}

# Main execution
try {
    Write-Header "Bitwig Studio Automation Setup"
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Check GitHub setup
    if (-not (Test-GitHubSetup)) {
        Write-ColorText "Please fix the GitHub setup issues before continuing." "Yellow"
        exit 1
    }
    
    # Show options and get user choice
    $choice = Show-AutomationOptions
    
    switch ($choice) {
        "1" { Setup-GitHubActions }
        "2" { 
            Write-ColorText "Manual script is available at: Tools\Update-BitwigManifest.ps1" "Green"
            Write-ColorText "Run .\Tools\Update-BitwigManifest.ps1 -help for usage information" "Cyan"
        }
        "3" { Test-ManualScript }
        "4" { Show-Information }
    }
    
    Write-Host ""
    Write-ColorText "🎉 Setup completed!" "Green"
    Write-ColorText "Check the files created and commit them to enable automation." "Yellow"
    
} catch {
    Write-ColorText "❌ Setup failed: $_" "Red"
    exit 1
}
