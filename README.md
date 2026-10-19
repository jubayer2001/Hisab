# Hisab

A calm, offline expense tracker for Bangladesh. Track expenses, income and savings in Taka (৳), get a reminder at 10 PM, and see where your money went by day, month and year.

**[Download the latest APK](https://github.com/jubayer2001/Hisab/releases/latest/download/Hisab.apk)** · [All releases](https://github.com/jubayer2001/Hisab/releases)

> Status: early test versions (v0.x). Version 1.0 is in progress.

## Install on your Android phone

1. Open the download link above in Chrome on your phone.
2. Open the downloaded `Hisab.apk`.
3. If asked, allow **Install unknown apps** for Chrome or your file manager.
4. If Play Protect warns about an unknown developer, tap **More details → Install anyway**.

To update, download the new APK and install it over the old one. Your data stays.

**Xiaomi / Redmi / POCO:** to make sure the daily reminder arrives, open Settings → Apps → Hisab and turn on **Autostart**, set **Battery saver** to **No restrictions**, and allow **Notifications**.

Works on Android 7.0 and newer.

## Features (planned for 1.0)

- Add an expense in three taps: amount, category, save
- Income, balance and savings
- Reports by day, week, month and year
- Monthly and per-category budgets with a warning at 80%
- Recurring bills (rent, Wi-Fi, recharge)
- Savings goals
- Lend and borrow (dhar) tracker
- Daily 10 PM reminder and logging streak
- Backup, restore and CSV export
- Light and dark mode
- No ads, no account, all data stays on your phone

## Development

Built with Flutter (stable 3.47), Riverpod, go_router and Material 3.

```bash
flutter pub get
flutter test
flutter run            # with a phone connected over USB
```

Releases are built by GitHub Actions when a tag like `v0.1.0` is pushed. Signing uses repository secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD`.

Font: [Hind Siliguri](https://fonts.google.com/specimen/Hind+Siliguri), SIL Open Font License (see `assets/fonts/OFL.txt`).
