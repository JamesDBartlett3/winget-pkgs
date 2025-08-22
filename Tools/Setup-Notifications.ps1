#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Setup notifications for Bitwig Studio automation

.DESCRIPTION
    This script helps configure different notification methods for when new Bitwig Studio
    versions are ready for submission. Choose from email, Discord, GitHub issues, or combinations.

.PARAMETER NotificationType
    The type of notification to configure: email, discord, github-issues, all

.EXAMPLE
    .\Setup-Notifications.ps1 -NotificationType github-issues
    Set up GitHub issue notifications only

.EXAMPLE
    .\Setup-Notifications.ps1 -NotificationType all
    Configure all notification types
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("email", "discord", "github-issues", "all", "help")]
    [string]$NotificationType = "help"
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

function Show-Help {
    Write-Header "Bitwig Studio Automation - Notification Setup"
    
    Write-ColorText "This script helps you configure notifications for when new Bitwig Studio versions are ready." "White"
    Write-Host ""
    
    Write-ColorText "Available Notification Types:" "Yellow"
    Write-ColorText "🐙 github-issues  - Creates GitHub issues in your repo (Recommended)" "Green"
    Write-ColorText "📧 email          - Sends email notifications" "White"
    Write-ColorText "💬 discord        - Sends Discord webhook messages" "White"
    Write-ColorText "🎯 all            - Configure all notification types" "Cyan"
    Write-Host ""
    
    Write-ColorText "Quick Start (Recommended):" "Yellow"
    Write-ColorText ".\Setup-Notifications.ps1 -NotificationType github-issues" "Cyan"
    Write-Host ""
    
    Write-ColorText "GitHub Issues Benefits:" "Green"
    Write-ColorText "• No additional setup required" "White"
    Write-ColorText "• Creates trackable tasks in your repo" "White"
    Write-ColorText "• Includes direct links and commands" "White"
    Write-ColorText "• Can be closed when submitted to upstream" "White"
    Write-Host ""
    
    Write-ColorText "Usage Examples:" "Yellow"
    Write-ColorText ".\Setup-Notifications.ps1 -NotificationType github-issues" "Cyan"
    Write-ColorText ".\Setup-Notifications.ps1 -NotificationType email" "Cyan"
    Write-ColorText ".\Setup-Notifications.ps1 -NotificationType discord" "Cyan"
}

function Setup-GitHubIssues {
    Write-Header "Setting Up GitHub Issues Notifications"
    
    Write-ColorText "GitHub Issues are already configured! 🎉" "Green"
    Write-Host ""
    
    Write-ColorText "When a new Bitwig version is found, the automation will:" "Yellow"
    Write-ColorText "✅ Create a GitHub issue in your repository" "White"
    Write-ColorText "✅ Include all version details and checksums" "White"
    Write-ColorText "✅ Provide step-by-step commands for submission" "White"
    Write-ColorText "✅ Add helpful labels for organization" "White"
    Write-Host ""
    
    Write-ColorText "Example issue title: '🎵 Bitwig Studio 5.3.14 Ready for Submission'" "Cyan"
    Write-Host ""
    
    Write-ColorText "No additional configuration needed! ✨" "Green"
}

function Setup-Email {
    Write-Header "Setting Up Email Notifications"
    
    Write-ColorText "To enable email notifications, you need to configure these GitHub Secrets:" "Yellow"
    Write-Host ""
    
    Write-ColorText "Required Secrets:" "White"
    Write-ColorText "• EMAIL_USERNAME - Your Gmail address (e.g., yourname@gmail.com)" "Cyan"
    Write-ColorText "• EMAIL_PASSWORD - Gmail App Password (not your regular password)" "Cyan"
    Write-ColorText "• EMAIL_TO       - Email address to receive notifications" "Cyan"
    Write-Host ""
    
    Write-ColorText "Setup Steps:" "Yellow"
    Write-ColorText "1. Create Gmail App Password:" "White"
    Write-ColorText "   - Go to Google Account settings" "Gray"
    Write-ColorText "   - Security → 2-Step Verification → App passwords" "Gray"
    Write-ColorText "   - Generate password for 'Mail'" "Gray"
    Write-Host ""
    
    Write-ColorText "2. Add GitHub Secrets:" "White"
    Write-ColorText "   - Go to your repository → Settings → Secrets and variables → Actions" "Gray"
    Write-ColorText "   - Add the three secrets listed above" "Gray"
    Write-Host ""
    
    Write-ColorText "3. Test the setup:" "White"
    Write-ColorText "   - Trigger the workflow manually from GitHub Actions" "Gray"
    Write-Host ""
    
    $setupEmail = Read-Host "Do you want to open the GitHub secrets page to configure this? (y/N)"
    if ($setupEmail -eq "y") {
        $repoUrl = git remote get-url origin
        $repoUrl = $repoUrl -replace "\.git$", ""
        $secretsUrl = "$repoUrl/settings/secrets/actions"
        
        Write-ColorText "Opening: $secretsUrl" "Cyan"
        Start-Process $secretsUrl
    }
}

function Setup-Discord {
    Write-Header "Setting Up Discord Notifications"
    
    Write-ColorText "To enable Discord notifications, you need a webhook URL:" "Yellow"
    Write-Host ""
    
    Write-ColorText "Setup Steps:" "White"
    Write-ColorText "1. Create Discord Webhook:" "Yellow"
    Write-ColorText "   - Go to your Discord server" "Gray"
    Write-ColorText "   - Server Settings → Integrations → Webhooks" "Gray"
    Write-ColorText "   - Create New Webhook" "Gray"
    Write-ColorText "   - Choose channel and copy webhook URL" "Gray"
    Write-Host ""
    
    Write-ColorText "2. Add GitHub Secret:" "White"
    Write-ColorText "   - Go to your repository → Settings → Secrets and variables → Actions" "Gray"
    Write-ColorText "   - Add secret: DISCORD_WEBHOOK = your webhook URL" "Gray"
    Write-Host ""
    
    Write-ColorText "3. Test the notification:" "White"
    Write-ColorText "   - Trigger the workflow manually from GitHub Actions" "Gray"
    Write-Host ""
    
    $setupDiscord = Read-Host "Do you want to open the GitHub secrets page to configure this? (y/N)"
    if ($setupDiscord -eq "y") {
        $repoUrl = git remote get-url origin
        $repoUrl = $repoUrl -replace "\.git$", ""
        $secretsUrl = "$repoUrl/settings/secrets/actions"
        
        Write-ColorText "Opening: $secretsUrl" "Cyan"
        Start-Process $secretsUrl
    }
}

function Show-Summary {
    Write-Header "Notification Setup Summary"
    
    Write-ColorText "Your automation is now configured to notify you when new Bitwig versions are ready!" "Green"
    Write-Host ""
    
    Write-ColorText "What happens next:" "Yellow"
    Write-ColorText "1. 🔍 Automation runs daily at 10 AM UTC" "White"
    Write-ColorText "2. 📦 Detects new Bitwig Studio releases" "White"
    Write-ColorText "3. ⬇️ Downloads and verifies installers" "White"
    Write-ColorText "4. 📝 Creates complete manifest files" "White"
    Write-ColorText "5. 🔄 Creates PR in your fork (automation branch)" "White"
    Write-ColorText "6. 📱 Sends you notifications (based on your setup)" "Green"
    Write-Host ""
    
    Write-ColorText "When you receive a notification:" "Yellow"
    Write-ColorText "1. 👀 Review the automated PR in your fork" "White"
    Write-ColorText "2. 🧪 Optionally test the installation locally" "White"
    Write-ColorText "3. 🚀 Use the workflow management script to create upstream PR" "White"
    Write-ColorText "4. 📤 Submit to Microsoft's winget-pkgs repository" "White"
    Write-Host ""
    
    Write-ColorText "Quick commands for submission:" "Cyan"
    Write-ColorText ".\Tools\Manage-ForkWorkflow.ps1 -Action create-pr" "White"
    Write-Host ""
    
    Write-ColorText "🎉 You now have a semi-automated workflow!" "Green"
    Write-ColorText "The automation does the heavy lifting, you control the submission timing." "White"
}

# Main execution
try {
    switch ($NotificationType) {
        "help" { 
            Show-Help 
        }
        "github-issues" { 
            Setup-GitHubIssues 
            Show-Summary
        }
        "email" { 
            Setup-Email 
            Show-Summary
        }
        "discord" { 
            Setup-Discord 
            Show-Summary
        }
        "all" {
            Setup-GitHubIssues
            Write-Host ""
            Setup-Email  
            Write-Host ""
            Setup-Discord
            Show-Summary
        }
    }

} catch {
    Write-ColorText "❌ Error: $_" "Red"
    exit 1
}
