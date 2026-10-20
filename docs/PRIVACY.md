# Hisab privacy policy

Last updated: 21 October 2026

Hisab is a personal expense tracker for Android. It handles sensitive information: your income,
your spending and your balance. This page explains exactly what the app does with it. The short
version: **your data stays on your phone, it is encrypted there, and nobody else can see it.**

## What the app stores

Everything you enter: expenses, income, categories, budgets, monthly bills and income, savings
goals, dhar (money lent or borrowed), notes, and your name, profile colour and reminder settings.

All of it is stored **only on your phone**, in the app's private storage. The app works fully
without an internet connection and without any account. Hisab has no ads, no analytics and no
tracking, and collects nothing about how you use it.

## How it is protected on your phone

- **Encryption.** The database is encrypted. The key is random, created on your phone, and locked
  inside Android's hardware-backed secure storage (the Keystore), from which it cannot be read out.
  If someone copies the data file off the phone, it is unreadable.
- **Private to the app.** Other apps cannot read it, and Android's automatic cloud backup,
  `adb backup` and phone-to-phone transfer are turned off for Hisab, so the data cannot leave
  the phone that way.
- **Optional app lock.** You can require your fingerprint, face, PIN or pattern to open Hisab.
  Hisab never sees your fingerprint or PIN; the phone checks them and only says yes or no.
- **Hidden from screenshots.** By default the app's screens do not appear in screenshots, screen
  recordings or the recent-apps picture. You can turn this off in More, Privacy and security.
- **Safe backup files.** Files you import are checked thoroughly before anything is restored, and
  a damaged or tampered file is refused without changing your data.

## Optional: Sign in with Google

If you choose to sign in with Google, Hisab keeps a **backup copy** of your data in your own Google
Drive, so you can get it back if you delete the app or change phones.

- Hisab asks for one Google permission: access to its **own hidden app folder** in your Drive
  (`drive.appdata`). It cannot see, open, change or delete any of your other Drive files, and no
  other app can open that folder.
- Hisab also receives your Google account's **email address**, only to show you which account is
  signed in. It is kept on your phone, not sent to the developer or any other party.
- The backup is sent directly from your phone to your Google Drive over a secure (HTTPS)
  connection. It does not pass through any server owned by the developer, because there is none.
  Google stores it under its own privacy policy and security.
- Signing in is optional. If you never sign in, nothing is ever sent from your phone.

## Backup files and spreadsheets

If you save a backup file or export a spreadsheet (CSV), that file is **not encrypted** and can be
read by anyone who gets it. Keep it somewhere private. Hisab never uploads these files anywhere.

## Who can see your data

Only you. The developer cannot see your data, your backup or your Google account. Your data is not
sold, shared, rented or used for advertising or profiling, and it is not used to train anything.

## Permissions the app asks for

| Permission | Why |
|---|---|
| Notifications, exact alarms, run at startup | Your daily reminder, at the minute you choose, and again after the phone restarts |
| Internet | Only for the optional Google backup, only to Google, only over HTTPS |
| Biometrics / screen lock | Only to check it is you when the app lock is turned on |

## Keeping and deleting your data

- **One entry or item:** every list has a delete button, with Undo.
- **Everything:** More, then Account, then **Erase all data**. For 7 days Hisab keeps a safety copy
  on your phone (inside the same encrypted database) so you can undo a mistake, then it is deleted
  for good. If you are signed in with Google, you choose whether the Drive copy is deleted too.
- **On your phone:** uninstalling Hisab deletes all data stored on the phone.
- **In Google Drive:** open Google Drive in a browser, go to Settings, then Manage apps, find Hisab,
  and choose "Delete hidden app data". You can also remove Hisab's access at
  myaccount.google.com/connections. Signing out inside Hisab stops backups but does not delete
  the existing copy.

## Children

Hisab is not directed at children and collects no personal information from anyone.

## Changes

If this policy changes, the new version will be published here with a new date.

## Questions and security reports

Questions: open an issue at https://github.com/jubayer2001/Hisab/issues

Security problems: please report them privately, see [SECURITY.md](../SECURITY.md).
