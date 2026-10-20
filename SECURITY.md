# Security

Hisab holds people's income, spending and balance, so its security matters. This page says how
the app protects that data and how to report a problem.

## How the app protects your data

- **Local first.** Your records live only on your phone. There is no Hisab server and no account
  with the developer, so there is nothing for anyone to break into remotely.
- **Encrypted on the phone.** The database is encrypted (SQLite3 Multiple Ciphers, ChaCha20-Poly1305).
  The key is random, created on the phone, and wrapped by a key inside Android's hardware-backed
  Keystore, which cannot be read out. A copied data file is unreadable.
- **No Android auto-backup.** `allowBackup` is off, so neither Android's cloud backup, `adb backup`,
  nor phone-to-phone transfer can copy the data.
- **Optional app lock.** Fingerprint, face, PIN or pattern, using the phone's own prompt. The app's
  screens are hidden from screenshots and the recent-apps picture (on by default, can be turned off).
- **Optional Google backup** goes to a hidden folder in the person's own Google Drive that only
  Hisab can open (the `drive.appdata` permission). Hisab asks for nothing else from Google and
  cannot see any other file.
- **Hostile files are refused.** A backup file is untrusted input: its size and every value are
  checked before anything is restored, and a bad file changes nothing. Spreadsheet exports neutralise
  formula injection.
- **HTTPS only.** Cleartext traffic is disabled, and only the phone's own trusted certificate
  authorities are accepted.
- **No ads, analytics or tracking.** Nothing about use of the app is collected.
- **Signed, verifiable releases.** Releases are built by GitHub Actions from tagged source, with
  every action pinned to an exact commit and dependencies pinned by `pubspec.lock`. Each release
  lists the SHA-256 of `Hisab.apk` so a download can be checked.

## What is not covered

- A backup file or CSV that someone saves is **not encrypted**. Whoever has the file can read it,
  so it should be kept somewhere private.
- Someone who can unlock the phone and has the app lock off can open the app.
- A phone that is rooted or already compromised can defeat any app's protections.

## Reporting a vulnerability

Please report problems privately, not in a public issue:

1. Go to the repository's **Security** tab on GitHub and choose **Report a vulnerability**
   (https://github.com/jubayer2001/Hisab/security/advisories/new).
2. Describe what you found and how to reproduce it.

You will get a reply, and a fix will be released before details are made public. Please do not
include anyone's real financial data in a report.

## Supported versions

Only the latest release receives security fixes.
