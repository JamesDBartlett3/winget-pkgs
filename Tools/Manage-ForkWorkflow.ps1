#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Workflow management script for winget-pkgs fork with automation

.DESCRIPTION
    This script helps manage the workflow for a winget-pkgs fork that includes
    automation tools, ensuring automation files don't pollute upstream PRs.

.PARAMETER Action
    The action to perform: setup, sync, create-pr, status

.EXAMPLE
    .\Manage-ForkWorkflow.ps1 -Action setup
    Set up the branch structure

.EXAMPLE
    .\Manage-ForkWorkflow.ps1 -Action sync
    Sync with upstream and update automation

.EXAMPLE
    .\Manage-ForkWorkflow.ps1 -Action create-pr
    Create a clean PR branch for upstream contribution
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("setup", "sync", "create-pr", "status", "help")]
    [string]$Action
)

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
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Test-Prerequisites {
    # Check if we're in a git repository
    try {
        git status | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Not in a git repository"
        }
    } catch {
        Write-ColorText "❌ Error: Not in a git repository" "Red"
        return $false
    }

    # Check if upstream remote exists
    $upstreamUrl = git remote get-url upstream 2>$null
    if (-not $upstreamUrl) {
        Write-ColorText "❌ Error: No 'upstream' remote configured" "Red"
        Write-ColorText "Add upstream with: git remote add upstream https://github.com/microsoft/winget-pkgs.git" "Yellow"
        return $false
    }

    return $true
}

function Setup-BranchStructure {
    Write-Header "Setting Up Branch Structure"
    
    Write-ColorText "This will set up a clean workflow with separate branches:" "Yellow"
    Write-ColorText "• master        - Clean sync with upstream" "White"
    Write-ColorText "• automation    - Contains your automation tools" "White"
    Write-ColorText "• package-*     - Clean branches for individual PRs" "White"
    Write-Host ""

    # Ensure we're on master and it's clean
    Write-ColorText "Switching to master branch..." "Yellow"
    git checkout master

    # Sync with upstream
    Write-ColorText "Syncing with upstream..." "Yellow"
    git fetch upstream
    git merge upstream/master --ff-only

    # Push updated master
    Write-ColorText "Pushing updated master..." "Yellow"
    git push origin master

    # Check if automation branch exists
    $automationExists = git branch --list automation
    if (-not $automationExists) {
        Write-ColorText "Creating automation branch..." "Yellow"
        git checkout -b automation
        
        Write-ColorText "✅ Automation branch created" "Green"
        Write-ColorText "You can now add your automation files to this branch" "White"
    } else {
        Write-ColorText "✅ Automation branch already exists" "Green"
    }

    Write-ColorText "✅ Branch structure setup complete!" "Green"
}

function Sync-WithUpstream {
    Write-Header "Syncing with Upstream"
    
    Write-ColorText "Fetching latest changes from upstream..." "Yellow"
    git fetch upstream

    # Update master
    Write-ColorText "Updating master branch..." "Yellow"
    git checkout master
    git merge upstream/master --ff-only
    git push origin master

    # Update automation branch
    $currentBranch = git branch --show-current
    $automationExists = git branch --list automation
    
    if ($automationExists) {
        Write-ColorText "Updating automation branch..." "Yellow"
        git checkout automation
        git merge master --no-edit
        git push origin automation
        
        # Return to original branch
        if ($currentBranch -ne "automation") {
            git checkout $currentBranch
        }
    }

    Write-ColorText "✅ Sync complete!" "Green"
}

function Create-PRBranch {
    Write-Header "Creating Clean PR Branch"
    
    $packageName = Read-Host "Enter package name (e.g., 'bitwig.bitwig')"
    $version = Read-Host "Enter version (e.g., '5.3.14')"
    
    if (-not $packageName -or -not $version) {
        Write-ColorText "❌ Package name and version are required" "Red"
        return
    }

    $branchName = "$packageName-$version"
    Write-ColorText "Creating branch: $branchName" "Yellow"

    # Ensure master is up to date
    git checkout master
    git pull origin master

    # Create new branch from clean master
    git checkout -b $branchName

    Write-ColorText "✅ Created clean PR branch: $branchName" "Green"
    Write-ColorText "This branch contains no automation files and is ready for upstream PR" "White"
    Write-Host ""
    Write-ColorText "Next steps:" "Yellow"
    Write-ColorText "1. Add your package manifests to this branch" "White"
    Write-ColorText "2. Commit and push: git push -u origin $branchName" "White"
    Write-ColorText "3. Create PR to upstream from this branch" "White"
}

function Show-Status {
    Write-Header "Repository Status"
    
    $currentBranch = git branch --show-current
    Write-ColorText "Current branch: $currentBranch" "Cyan"
    
    # Show all branches
    Write-ColorText "`nLocal branches:" "Yellow"
    git branch
    
    # Show remote status
    Write-ColorText "`nRemote status:" "Yellow"
    git remote -v
    
    # Check for automation files in current branch
    Write-ColorText "`nAutomation files in current branch:" "Yellow"
    $automationFiles = @(
        ".github/workflows/bitwig-auto-update.yml",
        "Tools/Update-BitwigManifest.ps1",
        "Tools/Setup-BitwigAutomation.ps1"
    )
    
    foreach ($file in $automationFiles) {
        if (Test-Path $file) {
            Write-ColorText "✅ $file" "Green"
        } else {
            Write-ColorText "❌ $file" "Red"
        }
    }
    
    # Show uncommitted changes
    $status = git status --porcelain
    if ($status) {
        Write-ColorText "`nUncommitted changes:" "Yellow"
        git status --short
    } else {
        Write-ColorText "`n✅ No uncommitted changes" "Green"
    }
}

function Show-Help {
    Write-Header "Fork Workflow Management Help"
    
    Write-ColorText "This script helps manage a winget-pkgs fork with automation tools." "White"
    Write-Host ""
    
    Write-ColorText "Branch Strategy:" "Yellow"
    Write-ColorText "• master      - Clean sync with upstream (no automation files)" "White"
    Write-ColorText "• automation  - Contains your automation tools" "White"
    Write-ColorText "• package-*   - Clean branches for individual package PRs" "White"
    Write-Host ""
    
    Write-ColorText "Available Actions:" "Yellow"
    Write-ColorText "• setup       - Set up the branch structure" "White"
    Write-ColorText "• sync        - Sync all branches with upstream" "White"  
    Write-ColorText "• create-pr   - Create a clean branch for upstream PR" "White"
    Write-ColorText "• status      - Show current repository status" "White"
    Write-ColorText "• help        - Show this help message" "White"
    Write-Host ""
    
    Write-ColorText "Typical Workflow:" "Yellow"
    Write-ColorText "1. .\Manage-ForkWorkflow.ps1 -Action setup" "Cyan"
    Write-ColorText "2. Switch to automation branch and add automation files" "White"
    Write-ColorText "3. .\Manage-ForkWorkflow.ps1 -Action sync (periodically)" "Cyan"
    Write-ColorText "4. .\Manage-ForkWorkflow.ps1 -Action create-pr (when contributing)" "Cyan"
    Write-Host ""
    
    Write-ColorText "GitHub Actions Setup:" "Yellow"
    Write-ColorText "• Configure GitHub Actions to run only on 'automation' branch" "White"
    Write-ColorText "• This prevents automation from running on clean PR branches" "White"
}

# Main execution
try {
    if (-not (Test-Prerequisites)) {
        exit 1
    }

    switch ($Action) {
        "setup" { Setup-BranchStructure }
        "sync" { Sync-WithUpstream }
        "create-pr" { Create-PRBranch }
        "status" { Show-Status }
        "help" { Show-Help }
    }

} catch {
    Write-ColorText "❌ Error: $_" "Red"
    exit 1
}
