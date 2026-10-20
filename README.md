# Hisab

A calm, offline expense tracker for Bangladesh. Track expenses, income and savings in Taka (৳), get a reminder at 10 PM, and see where your money went by day, month and year.

**[Download the latest APK](https://github.com/jubayer2001/Hisab/releases/latest/download/Hisab.apk)** · [All releases](https://github.com/jubayer2001/Hisab/releases)

> **Status: work in progress.** Everything except the final polish (v1.0) is built and tested on a phone. The download above is still v0.1.0, which is only the empty app shell. The first release you can use every day will be **1.0**, and it will replace that download. See the [roadmap](#roadmap).

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

## Roadmap

Test versions go straight to the developer's phone over USB. Only 1.0 is published as a download here.

| Version | What it adds | Status |
|---|---|---|
| **v0.1** | The look and navigation only: Teal Mist theme, light and dark mode, bottom bar. | Done, published |
| **v0.2** | Add, edit and delete expenses and income. Categories, History with search, a real Home screen with today and this month, the 10 PM reminder and a battery-settings guide for Redmi and similar phones. The first version you can use every day. | Done, tested on a phone |
| **v0.3** | Reports by day, week, month and year, with charts. Balance (income minus spending). Monthly and per-category budgets with an 80% warning. | Done, tested on a phone |
| **v0.4** | Recurring bills, savings goals, the dhar (lend and borrow) tracker and the logging streak. | Done, tested on a phone |
| **v1.0** | First-run welcome (name, monthly budget, reminder time). Backup and restore, CSV export, a proper app icon and splash screen, and screenshots here. Then about a week of real use on a phone before it is tagged 1.0. | Next |

If a version has bugs, a small fix release (for example v0.2.1) comes before the next one. Changes requested after trying a version are made before building on top of it, so the list can grow a little.

## Development

Built with Flutter (stable 3.47), Riverpod, go_router, drift (SQLite) and Material 3.

```bash
flutter pub get
flutter test
flutter run            # with a phone connected over USB
```

Releases are built by GitHub Actions when a tag like `v0.1.0` is pushed. Signing uses repository secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD`.

Font: [Hind Siliguri](https://fonts.google.com/specimen/Hind+Siliguri), SIL Open Font License (see `assets/fonts/OFL.txt`).
