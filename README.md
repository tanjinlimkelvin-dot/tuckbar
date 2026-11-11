# Tuckbar

A tiny macOS menu bar app that tucks away the menu bar icons you don't need all the time, so the ones you do aren't lost behind the notch.

## How it works

Tuckbar adds an arrow (‹ ›) and a thin divider (│) to the right side of the menu bar.

- Icons to the **left of the divider** are hidden. Click the arrow or press **⌃⌥⌘B** to show or hide them.
- To keep an icon always visible, hold **⌘** and drag it to the right of the arrow.
- To hide an icon, hold **⌘** and drag it to the left of the divider.
- Right-click the arrow for options: how soon icons hide again (default 10 seconds), hiding at launch, and launch at login.
- Opening Tuckbar again from Applications or Spotlight shows the icons.

On first launch the arrow and divider start at the far right, so every existing icon begins on the hidden side.

Hiding works by stretching the divider until everything to its left is pushed off the screen, which is the same trick other open-source menu bar managers use. It needs no permissions and no private APIs.

## Build

Requires macOS 14 or later and the Xcode Command Line Tools (`xcode-select --install`). Full Xcode isn't needed.

```bash
git clone https://github.com/tanjinlimkelvin-dot/tuckbar.git
cd tuckbar
./build.sh            # builds build/Tuckbar.app
./build.sh install    # also copies it to /Applications and launches it
```

## License

MIT. See [LICENSE](LICENSE).
