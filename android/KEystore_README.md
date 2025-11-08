# Keystore helper

This repository includes a small helper script to encode your Android keystore to Base64 and optionally generate a local `android/key.properties` file.

PowerShell script:

- `scripts/encode_keystore.ps1`

Usage examples (PowerShell):

1. Encode keystore to base64 file

```powershell
.\scripts\encode_keystore.ps1 -KeystorePath "C:\path\to\android\app\keystore.jks" -OutputBase64File "keystore.base64.txt"
```

2. Encode keystore and create a local `android/key.properties` (not committed)

```powershell
.\scripts\encode_keystore.ps1 -KeystorePath "C:\path\to\android\app\keystore.jks" -OutputBase64File "keystore.base64.txt" -StorePassword "YOUR_STORE_PASSWORD" -KeyPassword "YOUR_KEY_PASSWORD" -KeyAlias "absencobra_key"
```

What to do next:

- Copy the contents of `keystore.base64.txt` and store it as a GitHub secret named `KEYSTORE_BASE64` (or use CI secret manager of your choice).
- Add the following secrets to GitHub repo settings:
  - `KEYSTORE_BASE64` (base64 of the `.jks` file)
  - `KEYSTORE_PASSWORD` (storePassword)
  - `KEY_PASSWORD` (keyPassword)
  - `KEY_ALIAS` (keyAlias)

The included GitHub Actions workflow `.github/workflows/android-release.yml` will decode the base64 secret and create `android/key.properties` at runtime.

Security notes:

- Never commit your keystore or passwords to the repository.
- Keep backups of your keystore in a secure location. Losing the keystore may prevent you from updating your app on the Play Store.

## Generate a strong password (examples)

Don't use simple or common passwords for your release keystore. Below are a few commands you can run locally to generate a strong password.

PowerShell (Windows) — generate a 24-character random password and copy to clipboard:

```powershell
[System.Web.Security.Membership]::GeneratePassword(24,6) | Set-Clipboard
Write-Host "Password copied to clipboard (24 chars). Paste into android/key.properties when creating the file locally."
```

OpenSSL (Linux / macOS) — generate a 24-character base64-like password:

```bash
openssl rand -base64 18
```

Alternatively, use this PowerShell one-liner to produce a more cryptographically-random string (alphanumeric + punctuation):

```powershell
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create(); $bytes = New-Object byte[] 18; $rng.GetBytes($bytes); [Convert]::ToBase64String($bytes) | Set-Clipboard; Write-Host "Random password copied to clipboard";
```

Example (do NOT commit this):

```
Xt9$eP4rQv1#bM7sZk2J8LwQ
```

Notes & workflow:

- Generate the password locally and store it in a password manager or as GitHub Secrets (`KEYSTORE_PASSWORD`, `KEY_PASSWORD`).
- Do NOT paste real passwords into committed files. Use `android/key.properties` locally only and add it to `.gitignore`.
- If you use CI, encode the `.jks` file to base64 and store it in `KEYSTORE_BASE64` secret (see `scripts/encode_keystore.ps1`).

If you'd like, I can add a short example snippet in the repo root README showing the exact sequence to create the keystore, generate the password, and push a release via GitHub Actions.
