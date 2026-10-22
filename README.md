<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Headroom icon">
</p>

<h1 align="center">Headroom</h1>

<p align="center">
  See how much of your Claude plan you have left, right from the menu bar.
</p>

<p align="center">
  <a href="https://github.com/ontckr/Headroom/releases/latest"><img src="https://img.shields.io/github/v/release/ontckr/Headroom" alt="Latest release"></a>
  <a href="https://github.com/ontckr/Headroom/actions/workflows/ci.yml"><img src="https://github.com/ontckr/Headroom/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14 or later">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/ontckr/Headroom" alt="MIT license"></a>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshot-dark.png">
    <img src="docs/screenshot-light.png" width="340" alt="Headroom showing 42% of the 5-hour limit and 18% of the weekly limit used">
  </picture>
</p>

## Features

- **Always visible.** Your 5-hour usage sits in the menu bar, like `✦ 42%`.
- **One click for the details.** Ring gauges for the 5-hour and weekly limits,
  plus extra usage if you have it turned on.
- **Color coded.** Green, then orange from 50%, then red from 80%.
- **Private by design.** No login, no network requests, no tokens used.
- **Starts with your Mac.** Turn "Open at login" on or off from the popover.

## Install

1. Download **Headroom.zip** from the
   [latest release](https://github.com/ontckr/Headroom/releases/latest).
2. Unzip it and drag `Headroom.app` into your Applications folder.
3. Open it. Look for **✦** in your menu bar.

Headroom is signed with a Developer ID and notarized by Apple, so it opens
like any other app you download.

<details>
<summary><strong>Prefer Terminal?</strong></summary>

```bash
curl -fsSL https://raw.githubusercontent.com/ontckr/Headroom/main/install.sh | bash
```

This downloads the latest release, moves it into Applications, and opens it.
You can read [the script](install.sh) first; it is about 20 lines. Run it again
any time to update.

</details>

### Requirements

- macOS 14 Sonoma or later, on Apple silicon or Intel
- The [Claude desktop app](https://claude.ai/download), signed in to a Pro or
  Max plan

## How it works

The Claude desktop app keeps a record of your plan usage on your Mac:

```
~/Library/Application Support/Claude/plan-usage-history.json
```

Headroom reads the newest entry and updates as soon as the file changes. It
never contacts Anthropic, never asks for your password, and never touches your
Claude login.

### Why is my number a little behind?

The Claude app adds a new entry every few minutes while you use it, and less
often when you don't, so Headroom can trail the number Claude shows by a few
points. The popover tells you when the data was last synced.

### Why does a gauge show "–"?

That usage window has reset since Claude last recorded your usage, so the old
number no longer applies. It fills in again the next time Claude records an
update.

## Build from source

You need Xcode 16 or later.

```bash
git clone https://github.com/ontckr/Headroom.git
cd Headroom
make install
```

| Command        | What it does                                    |
| -------------- | ----------------------------------------------- |
| `make test`    | Run the unit tests                              |
| `make build`   | Build a universal release app into `build/`     |
| `make run`     | Build and open it                               |
| `make install` | Build and copy it to `/Applications`            |
| `make zip`     | Build and package an unsigned `build/Headroom.zip` |
| `make clean`   | Remove build output                             |

Builds from source are signed for your Mac only, so they run without an Apple
Developer account.

### Publishing a release

Maintainers with a Developer ID certificate can produce a signed, notarized
build. Store your notary credentials once:

```bash
xcrun notarytool store-credentials headroom --apple-id <apple-id> --team-id <team-id>
```

Then build, notarize, and package `build/release/Headroom.zip`:

```bash
TEAM_ID=<team-id> make release
```

## Disclaimer

Headroom is an independent project. It is not affiliated with, endorsed by, or
supported by Anthropic. It reads a file the Claude app uses internally, which
may change in a future Claude update.

## License

[MIT](LICENSE)
