# GitHub API URL for the app manifest.
$apiUrl = "https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/a/Adobe/CreativeCloud"

# Fetch version folders then filter only version folders.
$versions = Invoke-RestMethod -Uri $apiUrl -Headers @{ 'User-Agent' = 'PowerShell' }
$versionFolders = $versions | Where-Object { $_.type -eq "dir" }

# Extract and sort version numbers to get the latest version.
$sortedVersions = $versionFolders | ForEach-Object { $_.name } | Sort-Object { [version]$_ } -Descending -ErrorAction SilentlyContinue
$latestVersion = $sortedVersions

Write-Host "Latest Adobe Creative Cloud version: $latestVersion"

# Get contents of the latest version folder to find the .installer.yaml file.
$latestApiUrl = "$apiUrl/$latestVersion"
$latestFiles = Invoke-RestMethod -Uri $latestApiUrl -Headers @{ 'User-Agent' = 'PowerShell' }
$installerFile = $latestFiles | Where-Object { $_.name -like "*.installer.yaml" }

# Download and parse YAML content to get the Url of the latest installer file.
$yamlUrl = $installerFile.download_url
$yamlContent = Invoke-RestMethod -Uri $yamlUrl -Headers @{ 'User-Agent' = 'PowerShell' }
$null = ($yamlContent -join "`n") -match "InstallerUrl:\s+(http.*)"
$installerUrl = $Matches[1]

Write-Host "Downloading installer from: $installerUrl"

# Download the latest installer 
Invoke-WebRequest -Uri $installerUrl -OutFile "$env:TEMP\AdobeCreativeCloud-latest.exe"

# Start the install or update process.
Start-Process -FilePath "$env:TEMP\AdobeCreativeCloud-latest.exe" -ArgumentList '--mode=stub' -Wait

# Cleanup.
Remove-Item -Path "$env:TEMP\AdobeCreativeCloud-latest.exe" -Force -ErrorAction SilentlyContinue

Write-Host "Adobe Creative Cloud installation completed."
