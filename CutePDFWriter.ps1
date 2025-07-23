# Define the GitHub API URL for the app manifests in winget-pkgs.
$apiUrl = "https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/a/AcroSoftware/CutePDFWriter"

# Fetch version folders then filter only version folders.
$header         = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" }
$versions       = Invoke-RestMethod -Uri $apiUrl -Headers $header
$versionFolders = $versions | Where-Object { $_.type -eq "dir" }

# Extract and sort version numbers to get the latest version.
$sortedVersions = $versionFolders | ForEach-Object { $_.name } | Sort-Object {[version]$_} -Descending -ErrorAction SilentlyContinue
$latestVersion  = $sortedVersions

Write-Host "Latest CutePDFWriter version: $latestVersion."

# Get contents of the latest version folder to find the .installer.yaml file.
$latestApiUrl  = "$apiUrl/$latestVersion"
$latestFiles   = Invoke-RestMethod -Uri $latestApiUrl -Headers $header
$installerFile = $latestFiles | Where-Object { $_.Name -like "*.installer.yaml" }

# Download and parse YAML content to get the Url of the latest installer file.
$yamlUrl        = $installerFile.download_url
$yamlContent    = Invoke-RestMethod -Uri $yamlUrl -Headers $header
$yamlString     = $yamlContent -join "`n"
$installerUrls  = [regex]::Matches($yamlString, "InstallerUrl:\s+(http[^\s]+)") | ForEach-Object { $_.Groups[1].Value }
$installerUrl   = $installerUrls[1]

Write-Host "Downloading installer from: $installerUrl"

# Download the latest installer to the temp folder.
$webClient = [System.Net.WebClient]::new()
$webClient.DownloadFile($installerUrl, "$env:TEMP\CutePDFWriter-latest.zip")
Expand-Archive -Path "$env:TEMP\CutePDFWriter-latest.zip" -DestinationPath "$env:TEMP\CutePDFWriter" -Force

# Start the install process.
Start-Process -FilePath "$env:TEMP\CutePDFWriter\CuteWriter.exe" -ArgumentList '/SP- /SILENT /SUPPRESSMSGBOXES /NORESTART'

# Delete the downloaded installer file.
Remove-Item -Path "$env:TEMP\CutePDFWriter-latest.zip" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\CutePDFWriter" -Recurse  -Force -ErrorAction SilentlyContinue

Write-Host "CutePDFWriter installation completed."
