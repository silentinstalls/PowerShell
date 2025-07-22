# Define the GitHub API URL for the app manifests in winget-pkgs.
$apiUrl = "https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/g/Google/ChromeRemoteDesktopHost"

# Fetch version folders then filter only version folders.
$header         = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" }
$versions       = Invoke-RestMethod -Uri $apiUrl -Headers $header
$versionFolders = $versions | Where-Object { $_.type -eq "dir" }

# Extract and sort version numbers to get the latest version.
$sortedVersions = $versionFolders | ForEach-Object { $_.name } | Sort-Object {[version]$_} -Descending -ErrorAction SilentlyContinue
$latestVersion  = $sortedVersions[0]

Write-Host "Latest Chrome Remote Desktop Host version: $latestVersion."

# Get contents of the latest version folder to find the .installer.yaml file.
$latestApiUrl  = "$apiUrl/$latestVersion"
$latestFiles   = Invoke-RestMethod -Uri $latestApiUrl -Headers $header
$installerFile = $latestFiles | Where-Object { $_.Name -like "*.installer.yaml" }

# Download and parse YAML content to get the Url of the latest installer file.
$yamlUrl        = $installerFile.download_url
$yamlContent    = Invoke-RestMethod -Uri $yamlUrl -Headers @{ 'User-Agent' = 'PowerShell' }
$null           = ($yamlContent -join "`n") -match "InstallerUrl:\s+(http.*)"
$installerUrl   = $Matches[1]

Write-Host "Downloading installer from: $installerUrl"

# Download the latest installer to the temp folder.
$webClient = [System.Net.WebClient]::new()
$webClient.DownloadFile($installerUrl, "$env:TEMP\ChromeRemoteDesktopHost-latest.msi")

# Start the install process.
Set-Location -Path $env:TEMP
Start-Process -FilePath msiexec.exe -ArgumentList '/i ChromeRemoteDesktopHost-latest.msi /qn' -Wait

# Delete the downloaded installer file.
Remove-Item -Path "$env:TEMP\ChromeRemoteDesktopHost-latest.msi" -Force -ErrorAction SilentlyContinue

Write-Host "Chrome Remote Desktop Host installation completed."
