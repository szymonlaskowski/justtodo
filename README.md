# just todo.

![JustTodo in the menu bar](docs/menubar.png)

A todo list that lives in the menu bar.

Enter makes a line. Backspace on an empty line takes it away. Click the box to cross it off.

That is the entire app. There are no projects, no tags, no due dates, no priorities, no sync, no account, no subscription, no onboarding, no settings screen. Nothing to learn and nothing to maintain.

![The same list in its own window](docs/window.png)

## What it is made of

One Swift file and one React page. The Swift file draws the menu bar item, the popover and the detached window, then hands each of them a web view. The web page draws the list.

No Electron, no Tauri, no Xcode project, no runtime dependencies. The web view is the one already in macOS. The finished app is 616 KB.

```
main.swift   menu bar item, popover, window, storage        273 lines
build.sh     bun build, swiftc, iconutil, ad-hoc signature   50 lines
web/src/App.tsx    the list and its two keys               154 lines
web/src/native.ts  everything that only works in the app     55 lines
```

## Build it

Needs macOS 14 or newer, [bun](https://bun.sh) and the Xcode command line tools (`xcode-select --install`).

```sh
./build.sh            # JustTodo.app, next to the sources
./build.sh --install  # the same, copied to /Applications and launched
```

## Your todos

They sit in `~/Library/Application Support/JustTodo/todos.json` as plain JSON, written by Swift, never by the web view. Read it, edit it, back it up, delete it to start over. It is your file.

## A downloaded build

The app is signed ad hoc, so macOS quarantines it when it arrives from the internet. Clear the flag once:

```sh
xattr -dr com.apple.quarantine /Applications/JustTodo.app
```

Building it yourself avoids this entirely.

## License

MIT
