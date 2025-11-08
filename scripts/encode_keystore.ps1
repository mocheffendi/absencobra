Param(
  [Parameter(Mandatory=$true)] [string]$KeystorePath,
  [Parameter(Mandatory=$true)] [string]$OutputBase64File = "keystore.base64.txt",
  [string]$KeyAlias = "absencobra_key",
  [string]$StoreFileRelative = "app/keystore.jks",
  [string]$KeyPassword = "",
  [string]$StorePassword = ""
)

if (-not (Test-Path $KeystorePath)) {
  Write-Error "Keystore not found: $KeystorePath"
  exit 1
}

# Encode keystore to base64 and write to file
try {
  $bytes = [IO.File]::ReadAllBytes($KeystorePath)
  $b64 = [Convert]::ToBase64String($bytes)
  $b64 | Out-File -Encoding ascii $OutputBase64File
  Write-Host "Keystore encoded to base64: $OutputBase64File"
} catch {
  Write-Error "Failed to encode keystore: $_"
  exit 1
}

# Optional: create android/key.properties (local only)
if ($StorePassword -ne "" -and $KeyPassword -ne "") {
  $kpPath = Join-Path -Path (Resolve-Path ..\android).Path -ChildPath "key.properties"
  $content = @"
storePassword=$StorePassword
keyPassword=$KeyPassword
keyAlias=$KeyAlias
storeFile=$StoreFileRelative
"@
  $content | Out-File -Encoding ascii $kpPath
  Write-Host "Created android/key.properties at: $kpPath"
  Write-Host "Remember to add android/key.properties and android/app/keystore.jks to .gitignore"
} else {
  Write-Host "Skipping creation of android/key.properties (no passwords provided)."
  Write-Host "Use the generated base64 file to create a GitHub secret named KEYSTORE_BASE64."
}
