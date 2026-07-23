#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automated Bitwig Studio manifest updater for winget-pkgs.

.DESCRIPTION
    Checks for new Bitwig Studio releases, downloads the available Windows installers,
    computes their SHA256 hashes, generates a current-style winget manifest set, and
    validates it with winget.

.PARAMETER Force
    Force regeneration even if the version already exists.

.PARAMETER SkipDownload
    Skip downloading installers. This is intended for local dry runs only and does not
    produce submission-ready manifests.

.PARAMETER Version
    Create manifests for a specific version instead of discovering the latest release.

.PARAMETER OutputPath
    Optional GitHub Actions output file path. When provided, the script writes the
    current version, new version, manifest directory, and update decision to it.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipDownload,
    [string]$Version,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$PackageIdentifier = 'bitwig.bitwig'
$PublisherName = 'Bitwig GmbH'
$PackageName = 'Bitwig Studio'
$BaseUrl = 'https://www.bitwig.com'
$ManifestSchemaVersion = '1.12.0'
$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ManifestRoot = Join-Path $RepositoryRoot 'manifests\b\bitwig\bitwig'

function Write-ColorText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [string]$Color = 'White'
    )

    Write-Host $Text -ForegroundColor $Color
}

function Set-ActionOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [AllowEmptyString()]
        [string]$Value
    )

    if (-not $OutputPath) {
        return
    }

    Add-Content -Path $OutputPath -Value ("{0}={1}" -f $Name, $Value)
}

function Get-ExistingVersions {
    Get-ChildItem -Path $ManifestRoot -Directory |
        Sort-Object -Property { [version]$_.Name } -Descending
}

function Get-CurrentVersion {
    $currentVersion = Get-ExistingVersions | Select-Object -First 1 -ExpandProperty Name
    if (-not $currentVersion) {
        throw 'No existing Bitwig manifest versions were found.'
    }

    return $currentVersion
}

function Get-LatestBitwigVersion {
    Write-ColorText 'Checking for the latest Bitwig Studio version...' 'Yellow'

    $downloadPage = Invoke-WebRequest -Uri "$BaseUrl/download/" -UseBasicParsing
    $versionMatch = [regex]::Match($downloadPage.Content, 'Bitwig Studio ([\d\.]+)')

    if (-not $versionMatch.Success) {
        throw 'Could not parse a Bitwig Studio version from the download page.'
    }

    $latestVersion = $versionMatch.Groups[1].Value
    Write-ColorText "Latest version found: $latestVersion" 'Green'
    return $latestVersion
}

function Test-VersionExists {
    param([Parameter(Mandatory = $true)][string]$TargetVersion)

    return Test-Path (Join-Path $ManifestRoot $TargetVersion)
}

function Get-MsiProductCode {
    param([Parameter(Mandatory = $true)][string]$InstallerPath)

    $windowsInstaller = $null
    $database = $null
    $view = $null
    $record = $null

    try {
        $windowsInstaller = New-Object -ComObject WindowsInstaller.Installer
        $database = $windowsInstaller.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $windowsInstaller, @($InstallerPath, 0))
        $view = $database.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $database, ("SELECT `Value` FROM `Property` WHERE `Property` = 'ProductCode'"))
        $null = $view.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $view, $null)
        $record = $view.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $view, $null)

        if ($null -eq $record) {
            return $null
        }

        return $record.GetType().InvokeMember('StringData', 'GetProperty', $null, $record, 1)
    } catch {
        Write-ColorText "Warning: unable to read ProductCode from $InstallerPath. $_" 'Yellow'
        return $null
    } finally {
        foreach ($object in @($record, $view, $database, $windowsInstaller)) {
            if ($null -ne $object -and [System.Runtime.InteropServices.Marshal]::IsComObject($object)) {
                [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($object)
            }
        }

        [gc]::Collect()
        [gc]::WaitForPendingFinalizers()
    }
}

function Get-InstallerInfo {
    param([Parameter(Mandatory = $true)][string]$TargetVersion)

    if ($SkipDownload) {
        Write-ColorText 'Skipping downloads; generated manifests will not be submission-ready.' 'Yellow'
        return @(
            [pscustomobject]@{
                Architecture = 'x64'
                Url = "$BaseUrl/dl/Bitwig%20Studio/$TargetVersion/installer_windows/"
                Checksum = 'PLACEHOLDER_CHECKSUM_REPLACE_MANUALLY'
                ProductCode = $null
            }
        )
    }

    $installerCandidates = @(
        [pscustomobject]@{
            Architecture = 'x64'
            Url = "$BaseUrl/dl/Bitwig%20Studio/$TargetVersion/installer_windows/"
            FileName = 'bitwig-x64.msi'
            Required = $true
        },
        [pscustomobject]@{
            Architecture = 'arm64'
            Url = "$BaseUrl/dl/Bitwig%20Studio/$TargetVersion/installer_windowsarm/"
            FileName = 'bitwig-arm64.msi'
            Required = $false
        }
    )

    $tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("bitwig-{0}" -f ([guid]::NewGuid().ToString('N')))
    $null = New-Item -ItemType Directory -Path $tempDirectory -Force

    try {
        $installerInfo = [System.Collections.Generic.List[object]]::new()

        foreach ($candidate in $installerCandidates) {
            $installerPath = Join-Path $tempDirectory $candidate.FileName
            Write-ColorText "Downloading $($candidate.Architecture) installer from $($candidate.Url)" 'Yellow'

            try {
                Invoke-WebRequest -Uri $candidate.Url -OutFile $installerPath -UseBasicParsing
            } catch {
                if ($candidate.Required) {
                    throw
                }

                Write-ColorText "Skipping unavailable $($candidate.Architecture) installer. $_" 'Yellow'
                continue
            }

            $checksum = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash
            $productCode = Get-MsiProductCode -InstallerPath $installerPath

            $installerInfo.Add([pscustomobject]@{
                Architecture = $candidate.Architecture
                Url = $candidate.Url
                Checksum = $checksum
                ProductCode = $productCode
            })
        }

        if ($installerInfo.Count -eq 0) {
            throw 'No downloadable Bitwig installers were found.'
        }

        return $installerInfo
    } finally {
        if (Test-Path $tempDirectory) {
            Remove-Item -Path $tempDirectory -Recurse -Force
        }
    }
}

function New-VersionManifest {
    param([Parameter(Mandatory = $true)][string]$TargetVersion)

@"
# Created with automated Bitwig updater
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.version.$ManifestSchemaVersion.schema.json

PackageIdentifier: $PackageIdentifier
PackageVersion: $TargetVersion
DefaultLocale: en-US
ManifestType: version
ManifestVersion: $ManifestSchemaVersion
"@
}

function New-InstallerManifest {
    param(
        [Parameter(Mandatory = $true)][string]$TargetVersion,
        [Parameter(Mandatory = $true)][System.Collections.IEnumerable]$InstallerInfo
    )

    $installerBlock = foreach ($installer in $InstallerInfo) {
        "- Architecture: $($installer.Architecture)"
        "  InstallerUrl: $($installer.Url)"
        "  InstallerSha256: $($installer.Checksum)"

        if ($installer.ProductCode) {
            "  ProductCode: '$($installer.ProductCode)'"
        }
    }

@"
# Created with automated Bitwig updater
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.$ManifestSchemaVersion.schema.json

PackageIdentifier: $PackageIdentifier
PackageVersion: $TargetVersion
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
$($installerBlock -join "`n")
ManifestType: installer
ManifestVersion: $ManifestSchemaVersion
"@
}

function New-LocaleManifest {
    param([Parameter(Mandatory = $true)][string]$TargetVersion)

    $currentYear = (Get-Date).Year

@"
# Created with automated Bitwig updater
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.defaultLocale.$ManifestSchemaVersion.schema.json

PackageIdentifier: $PackageIdentifier
PackageVersion: $TargetVersion
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
ManifestType: defaultLocale
ManifestVersion: $ManifestSchemaVersion
"@
}

function New-ManifestFiles {
    param(
        [Parameter(Mandatory = $true)][string]$TargetVersion,
        [Parameter(Mandatory = $true)][System.Collections.IEnumerable]$InstallerInfo
    )

    $manifestDirectory = Join-Path $ManifestRoot $TargetVersion

    if (Test-Path $manifestDirectory) {
        if (-not $Force) {
            throw "Manifest directory already exists: $manifestDirectory"
        }

        Remove-Item -Path $manifestDirectory -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $manifestDirectory -Force

    Set-Content -Path (Join-Path $manifestDirectory 'bitwig.bitwig.yaml') -Value (New-VersionManifest -TargetVersion $TargetVersion) -Encoding utf8
    Set-Content -Path (Join-Path $manifestDirectory 'bitwig.bitwig.installer.yaml') -Value (New-InstallerManifest -TargetVersion $TargetVersion -InstallerInfo $InstallerInfo) -Encoding utf8
    Set-Content -Path (Join-Path $manifestDirectory 'bitwig.bitwig.locale.en-US.yaml') -Value (New-LocaleManifest -TargetVersion $TargetVersion) -Encoding utf8

    Write-ColorText "Manifest files created in $manifestDirectory" 'Green'
    return $manifestDirectory
}

function Test-ManifestFiles {
    param([Parameter(Mandatory = $true)][string]$ManifestDirectory)

    if ($SkipDownload) {
        Write-ColorText 'Skipping winget validation because downloads were skipped.' 'Yellow'
        return
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget is required to validate generated manifests.'
    }

    Write-ColorText 'Validating manifests with winget...' 'Yellow'
    & winget validate --manifest $ManifestDirectory

    # winget uses a distinct exit code (APPINSTALLER_CLI_ERROR_MANIFEST_VALIDATION_WARNING,
    # 0x8A150028 / -1978335192) to signal that validation succeeded but produced non-fatal
    # warnings. Only treat other non-zero exit codes as real validation failures.
    $manifestValidationWarningExitCode = -1978335192
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $manifestValidationWarningExitCode) {
        throw 'winget validate reported manifest errors.'
    }

    Write-ColorText 'winget validation completed successfully.' 'Green'
}

try {
    Write-ColorText '=== Bitwig Studio Manifest Updater ===' 'Cyan'
    Write-ColorText "Package: $PackageIdentifier" 'White'

    $currentVersion = Get-CurrentVersion
    Set-ActionOutput -Name 'current-version' -Value $currentVersion

    $targetVersion = if ($Version) { $Version } else { Get-LatestBitwigVersion }
    $relativeManifestDirectory = "manifests/b/bitwig/bitwig/$targetVersion"
    Set-ActionOutput -Name 'new-version' -Value $targetVersion
    Set-ActionOutput -Name 'manifest-dir' -Value $relativeManifestDirectory

    if ((Test-VersionExists -TargetVersion $targetVersion) -and -not $Force) {
        Write-ColorText "Version $targetVersion already exists in manifests." 'Yellow'
        Set-ActionOutput -Name 'needs-update' -Value 'false'
        exit 0
    }

    $installerInfo = Get-InstallerInfo -TargetVersion $targetVersion
    $manifestDirectory = New-ManifestFiles -TargetVersion $targetVersion -InstallerInfo $installerInfo
    Test-ManifestFiles -ManifestDirectory $manifestDirectory

    Set-ActionOutput -Name 'needs-update' -Value 'true'
    Write-ColorText "✅ Successfully prepared manifests for Bitwig Studio $targetVersion" 'Green'

    if ($SkipDownload) {
        Write-ColorText '⚠️ Update the placeholder checksum and rerun without -SkipDownload before submitting.' 'Yellow'
    }
} catch {
    Write-ColorText "❌ Error: $_" 'Red'
    throw
}
