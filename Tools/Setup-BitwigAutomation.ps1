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

    if (-not (Test-Path "manifests\b\bitwig\bitwig")) {
        Write-ColorText "❌ Error: Not in winget-pkgs repository root" "Red"
        Write-ColorText "Please run this script from the root of your winget-pkgs fork." "Yellow"
        return $false
    }

    if (-not (Test-Path ".github\workflows")) {
        Write-ColorText "Creating .github/workflows directory..." "Yellow"
        New-Item -ItemType Directory -Path ".github\workflows" -Force | Out-Null
    }

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
        $gitStatus = git status 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-ColorText "❌ Error: Not in a git repository" "Red"
            return $false
        }

        $remotes = git remote -v 2>$null
        if (-not $remotes) {
            Write-ColorText "❌ Error: No git remotes configured" "Red"
            return $false
        }

        $originUrl = git remote get-url origin 2>$null
        if ($originUrl -match "microsoft/winget-pkgs") {
            Write-ColorText "⚠️  Warning: You're working on the main Microsoft repository" "Yellow"
            Write-ColorText "It's recommended to fork the repository and work from your fork." "Yellow"
            Write-ColorText "This automation is intended for a fork where you can review the generated PRs." "Yellow"
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

    if (-not (Test-Path $workflowFile)) {
        Write-ColorText "❌ Workflow file not found at $workflowFile" "Red"
        return
    }

    Write-ColorText "✅ GitHub Actions workflow is already in place at:" "Green"
    Write-ColorText $workflowFile "Cyan"
    Write-Host ""

    Write-ColorText "The workflow will:" "Yellow"
    Write-ColorText "• Check for new Bitwig releases daily at 10 AM UTC" "White"
    Write-ColorText "• Download and verify the available installers automatically" "White"
    Write-ColorText "• Create manifest files with proper checksums and ProductCodes when available" "White"
    Write-ColorText "• Validate the manifest folder with winget" "White"
    Write-ColorText "• Open a review PR in your fork" "White"
    Write-Host ""

    Write-ColorText "Important default-branch requirement:" "Yellow"
    Write-ColorText "• Scheduled GitHub Actions run from the repository's default branch" "White"
    Write-ColorText "• If you keep automation isolated on an 'automation' branch, make that branch the default branch in your fork" "White"
    Write-ColorText "• Clean upstream contribution branches should still be created separately" "White"
    Write-Host ""

    Write-ColorText "To enable the automation:" "Yellow"
    Write-ColorText "1. Commit and push these files to your fork" "White"
    Write-ColorText "2. Make the branch that contains the workflow your fork's default branch" "White"
    Write-ColorText "3. Trigger it manually from the GitHub Actions tab or wait for the daily schedule" "White"
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
    Write-ColorText "This performs a dry run and skips installer downloads." "White"
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
    Write-ColorText "3. Downloads the available Windows installers for the new version" "White"
    Write-ColorText "4. Calculates SHA256 checksums and reads MSI ProductCodes when available" "White"
    Write-ColorText "5. Creates all three required manifest files" "White"
    Write-ColorText "6. Validates the manifest folder with winget" "White"
    Write-ColorText "7. Opens a review PR in your fork" "White"
    Write-Host ""

    Write-ColorText "Manual usage examples:" "Yellow"
    Write-ColorText ".\Tools\Update-BitwigManifest.ps1                    # Check for latest" "Cyan"
    Write-ColorText ".\Tools\Update-BitwigManifest.ps1 -Version 5.3.14   # Specific version" "Cyan"
    Write-ColorText ".\Tools\Update-BitwigManifest.ps1 -Force             # Overwrite existing" "Cyan"
    Write-ColorText ".\Tools\Update-BitwigManifest.ps1 -SkipDownload      # Dry run without downloads" "Cyan"
    Write-Host ""

    Write-ColorText "GitHub Actions triggers:" "White"
    Write-ColorText "• Automatically runs daily at 10 AM UTC from the fork's default branch" "White"
    Write-ColorText "• Can be triggered manually from the GitHub Actions tab" "White"
    Write-ColorText "• Only opens a PR when a new version is found" "White"
}

try {
    Write-Header "Bitwig Studio Automation Setup"

    if (-not (Test-Prerequisites)) {
        exit 1
    }

    if (-not (Test-GitHubSetup)) {
        Write-ColorText "Please fix the GitHub setup issues before continuing." "Yellow"
        exit 1
    }

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
} catch {
    Write-ColorText "❌ Unexpected error: $_" "Red"
    exit 1
}
