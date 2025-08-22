#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automated Bitwig Studio manifest updater for winget-pkgs

.DESCRIPTION
    This script automatically checks for new Bitwig Studio releases,
    downloads the installer, calculates checksums, and creates winget manifest files.
    
.PARAMETER Force
    Force update even if the version already exists

.PARAMETER SkipDownload
    Skip downloading the installer (useful for testing manifest generation)

.PARAMETER Version
    Specify a specific version to create manifests for

.EXAMPLE
    .\Update-BitwigManifest.ps1
    Check for latest version and create manifests if new version found

.EXAMPLE
    .\Update-BitwigManifest.ps1 -Version "5.3.14" -Force
    Create manifests for specific version, overwriting if exists

.NOTES
    Author: Auto-generated for winget-pkgs automation
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipDownload,
    [string]$Version
)

$ErrorActionPreference = "Stop"

# Configuration
$PackageIdentifier = "bitwig.bitwig"
$PublisherName = "Bitwig GmbH"
$PackageName = "Bitwig Studio"
$BaseUrl = "https://www.bitwig.com"

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Get-LatestBitwigVersion {
    Write-ColorText "Checking for latest Bitwig Studio version..." "Yellow"
    
    try {
        $downloadPage = Invoke-WebRequest -Uri "$BaseUrl/download/" -UseBasicParsing
        $versionPattern = 'Bitwig Studio ([\d\.]+)'
        $versionMatch = [regex]::Match($downloadPage.Content, $versionPattern)
        
        if ($versionMatch.Success) {
            $latestVersion = $versionMatch.Groups[1].Value
            Write-ColorText "Latest version found: $latestVersion" "Green"
            return $latestVersion
        } else {
            throw "Could not parse version from download page"
        }
    } catch {
        Write-ColorText "Error checking for latest version: $_" "Red"
        throw
    }
}

function Test-VersionExists {
    param([string]$Version)
    
    $manifestPath = "manifests\b\bitwig\bitwig\$Version"
    return Test-Path $manifestPath
}

function Get-InstallerInfo {
    param([string]$Version)
    
    if ($SkipDownload) {
        Write-ColorText "Skipping download as requested" "Yellow"
        return @{
            Url = "https://www.bitwig.com/dl/Bitwig%20Studio/$Version/installer_windows/"
            Checksum = "PLACEHOLDER_CHECKSUM_REPLACE_MANUALLY"
        }
    }
    
    $installerUrl = "https://www.bitwig.com/dl/Bitwig%20Studio/$Version/installer_windows/"
    Write-ColorText "Downloading installer from: $installerUrl" "Yellow"
    
    # Create temp directory
    $tempDir = New-Item -ItemType Directory -Path "temp_bitwig_$Version" -Force
    $installerPath = Join-Path $tempDir "bitwig_installer.msi"
    
    try {
        # Test if the URL is accessible
        $headRequest = Invoke-WebRequest -Uri $installerUrl -Method Head -UseBasicParsing
        Write-ColorText "Installer URL is accessible (Status: $($headRequest.StatusCode))" "Green"
        
        # Download the installer
        Write-ColorText "Downloading installer..." "Yellow"
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        
        # Calculate SHA256 checksum
        Write-ColorText "Calculating checksum..." "Yellow"
        $hash = Get-FileHash -Path $installerPath -Algorithm SHA256
        $checksum = $hash.Hash
        
        Write-ColorText "Download completed successfully" "Green"
        Write-ColorText "SHA256: $checksum" "Cyan"
        
        return @{
            Url = $installerUrl
            Checksum = $checksum
        }
    } catch {
        Write-ColorText "Error downloading installer: $_" "Red"
        throw
    } finally {
        # Clean up temp directory
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }
}

function New-ManifestFiles {
    param(
        [string]$Version,
        [hashtable]$InstallerInfo
    )
    
    Write-ColorText "Creating manifest files for version $Version..." "Yellow"
    
    # Create manifest directory
    $manifestDir = "manifests\b\bitwig\bitwig\$Version"
    if (Test-Path $manifestDir) {
        if (-not $Force) {
            Write-ColorText "Manifest directory already exists. Use -Force to overwrite." "Red"
            throw "Manifest already exists"
        } else {
            Write-ColorText "Removing existing manifest directory..." "Yellow"
            Remove-Item $manifestDir -Recurse -Force
        }
    }
    
    New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    
    $currentYear = (Get-Date).Year
    
    # Version manifest
    $versionManifest = @"
# Created with automated Bitwig updater
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.version.1.10.0.schema.json

PackageIdentifier: $PackageIdentifier
PackageVersion: $Version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.10.0
"@
    
    # Installer manifest
    $installerManifest = @"
# Created with automated Bitwig updater
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.1.10.0.schema.json

PackageIdentifier: $PackageIdentifier
PackageVersion: $Version
Platform:
- Windows.Desktop
MinimumOSVersion: 10.0.0.0
InstallerType: wix
Scope: machine
InstallModes:
- interactive
- silent
- silentWithProgress
UpgradeBehavior: uninstallPrevious
FileExtensions:
- bwproject
- bwtemplate
Installers:
- Architecture: x64
  InstallerUrl: $($InstallerInfo.Url)
  InstallerSha256: $($InstallerInfo.Checksum)
ManifestType: installer
ManifestVersion: 1.10.0
"@
    
    # Locale manifest
    $localeManifest = @"
# Created with automated Bitwig updater
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.defaultLocale.1.10.0.schema.json

PackageIdentifier: $PackageIdentifier
PackageVersion: $Version
PackageLocale: en-US
Publisher: $PublisherName
PublisherUrl: $BaseUrl/
PublisherSupportUrl: $BaseUrl/support/
PrivacyUrl: $BaseUrl/privacy_policy/
Author: $PublisherName
PackageName: $PackageName
PackageUrl: $BaseUrl/
License: Proprietary
LicenseUrl: https://shop.bitwig.com/order/terms_conditions.php
Copyright: Copyright (c) $currentYear $PublisherName
CopyrightUrl: $BaseUrl/copyright/
ShortDescription: Modern music production and performance for Windows, macOS, and Linux.
Moniker: bitwig
Tags:
- daw
- midi
- music
- vst
- vsti
ReleaseNotesUrl: $BaseUrl/dl/Bitwig%20Studio/$Version/release_notes/
ManifestType: defaultLocale
ManifestVersion: 1.10.0
"@
    
    # Write manifest files
    $versionManifest | Out-File -FilePath "$manifestDir\bitwig.bitwig.yaml" -Encoding UTF8 -NoNewline
    $installerManifest | Out-File -FilePath "$manifestDir\bitwig.bitwig.installer.yaml" -Encoding UTF8 -NoNewline
    $localeManifest | Out-File -FilePath "$manifestDir\bitwig.bitwig.locale.en-US.yaml" -Encoding UTF8 -NoNewline
    
    Write-ColorText "Manifest files created successfully!" "Green"
    Write-ColorText "Location: $manifestDir" "Cyan"
}

function Test-ManifestFiles {
    param([string]$Version)
    
    Write-ColorText "Validating manifest files..." "Yellow"
    
    $manifestDir = "manifests\b\bitwig\bitwig\$Version"
    $expectedFiles = @(
        "bitwig.bitwig.yaml",
        "bitwig.bitwig.installer.yaml",
        "bitwig.bitwig.locale.en-US.yaml"
    )
    
    foreach ($file in $expectedFiles) {
        $filePath = Join-Path $manifestDir $file
        if (-not (Test-Path $filePath)) {
            Write-ColorText "Error: $file not found" "Red"
            return $false
        }
        
        $content = Get-Content $filePath -Raw
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-ColorText "Error: $file is empty" "Red"
            return $false
        }
        
        # Basic YAML validation - check for required fields
        if ($file -eq "bitwig.bitwig.yaml" -and $content -notmatch "PackageIdentifier: $PackageIdentifier") {
            Write-ColorText "Error: Invalid version manifest" "Red"
            return $false
        }
        
        if ($file -eq "bitwig.bitwig.installer.yaml" -and $content -notmatch "InstallerSha256:") {
            Write-ColorText "Error: Invalid installer manifest" "Red"
            return $false
        }
    }
    
    Write-ColorText "All manifest files validated successfully!" "Green"
    return $true
}

# Main execution
try {
    Write-ColorText "=== Bitwig Studio Manifest Updater ===" "Cyan"
    Write-ColorText "Package: $PackageIdentifier" "White"
    
    # Determine version to process
    if ($Version) {
        $targetVersion = $Version
        Write-ColorText "Using specified version: $targetVersion" "Yellow"
    } else {
        $targetVersion = Get-LatestBitwigVersion
    }
    
    # Check if version already exists
    if (Test-VersionExists $targetVersion) {
        if (-not $Force) {
            Write-ColorText "Version $targetVersion already exists in manifests." "Yellow"
            Write-ColorText "Use -Force to overwrite existing manifests." "White"
            exit 0
        } else {
            Write-ColorText "Version $targetVersion exists, but Force flag is set." "Yellow"
        }
    }
    
    # Get installer information
    $installerInfo = Get-InstallerInfo $targetVersion
    
    # Create manifest files
    New-ManifestFiles -Version $targetVersion -InstallerInfo $installerInfo
    
    # Validate manifests
    if (Test-ManifestFiles $targetVersion) {
        Write-ColorText "✅ Successfully created manifests for Bitwig Studio $targetVersion" "Green"
        
        if (-not $SkipDownload) {
            Write-ColorText "" "White"
            Write-ColorText "Next steps:" "Yellow"
            Write-ColorText "1. Review the generated manifest files" "White"
            Write-ColorText "2. Test the installation using winget" "White"
            Write-ColorText "3. Commit and push the changes" "White"
            Write-ColorText "4. Create a pull request" "White"
        } else {
            Write-ColorText "" "White"
            Write-ColorText "⚠️  Note: Checksum is placeholder. Update manually before submitting." "Yellow"
        }
    } else {
        Write-ColorText "❌ Manifest validation failed" "Red"
        exit 1
    }
    
} catch {
    Write-ColorText "❌ Error: $_" "Red"
    exit 1
}
