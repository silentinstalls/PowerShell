# Define the GitHub API URL for the app manifests in winget-pkgs.
$apiUrl = "https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/w/WinSCP/WinSCP"

# Fetch version folders then filter only version folders.
$versions = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" }
$versionFolders = $versions | Where-Object { $_.type -eq "dir" }

# Extract and sort version numbers to get the latest version.
$sortedVersions = $versionFolders | ForEach-Object { $_.name } | Sort-Object {[version]$_} -Descending -ErrorAction SilentlyContinue
$latestVersion = $sortedVersions[0]

Write-Host "Latest WinSCP version: $latestVersion"

# Get contents of the latest version folder to find the .installer.yaml file.
$latestApiUrl = "$apiUrl/$latestVersion"
$latestFiles = Invoke-RestMethod -Uri $latestApiUrl -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" }
$installerFile = $latestFiles | Where-Object { $_.name -like "*.installer.yaml" }

# Download and parse YAML content to get the Url of the latest installer file.
$yamlUrl = $installerFile.download_url
$yamlContent = Invoke-RestMethod -Uri $yamlUrl -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" }
$yamlString = $yamlContent -join "`n"
$installerUrls = [regex]::Matches($yamlString, "InstallerUrl:\s+(http[^\s]+)") | ForEach-Object { $_.Groups[1].Value }
$installerUrl = $installerUrls[1]

Write-Host "Downloading installer from: $installerUrl"

# Download the latest installer to the temp folder.
Invoke-WebRequest -UserAgent "Wget" -Uri $installerUrl -OutFile "$env:TEMP\WinSCP-latest.exe" 

# Start the install process.
Start-Process -FilePath "$env:TEMP\WinSCP-latest.exe" -ArgumentList '/SP- /SILENT /SUPPRESSMSGBOXES /NORESTART /ALLUSERS' -Wait

# Delete the downloaded installer file.
Remove-Item -Path "$env:TEMP\WinSCP-latest.exe" -Force -ErrorAction SilentlyContinue

Write-Host "WinSCP installation completed."
