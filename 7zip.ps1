# Define the GitHub API URL for the app manifests in winget-pkgs.
$apiUrl = "https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/7/7zip/7zip"

# Fetch version folders then filter only version folders.
$versions = Invoke-RestMethod -Uri $apiUrl -Headers @{ 'User-Agent' = 'PowerShell' }
$versionFolders = $versions | Where-Object { $_.type -eq "dir" }

# Extract and sort version numbers to get the latest version.
$sortedVersions = $versionFolders | ForEach-Object { $_.name } | Sort-Object {[version]$_} -Descending -ErrorAction SilentlyContinue
$latestVersion = $sortedVersions[0]

Write-Host "Latest 7-Zip version: $latestVersion"

# Get contents of the latest version folder to find the .installer.yaml file.
$latestApiUrl = "$apiUrl/$latestVersion"
$latestFiles = Invoke-RestMethod -Uri $latestApiUrl -Headers @{ 'User-Agent' = 'PowerShell' }
$installerFile = $latestFiles | Where-Object { $_.name -like "*.installer.yaml" }

# Download and parse YAML content to get the Url of the latest installer file.
$yamlUrl = $installerFile.download_url
$yamlContent = Invoke-RestMethod -Uri $yamlUrl -Headers @{ 'User-Agent' = 'PowerShell' }
$yamlString = $yamlContent -join "`n"
$installerUrls = [regex]::Matches($yamlString, "InstallerUrl:\s+(http[^\s]+)") | ForEach-Object { $_.Groups[1].Value }
$installerUrl = $installerUrls[1]

Write-Host "Downloading installer from: $installerUrl"

# Download the latest installer to the temp folder.
$webClient = [System.Net.WebClient]::new()
$webClient.DownloadFile($installerUrl, "$env:TEMP\7-Zip-latest.exe")

# Start the install process.
Start-Process -FilePath "$env:TEMP\7-Zip-latest.exe" -ArgumentList '/S' -Wait

# Delete the downloaded installer file.
Remove-Item -Path "$env:TEMP\7-Zip-latest.exe" -Force -ErrorAction SilentlyContinue

Write-Host "7-Zip installation completed."
