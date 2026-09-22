# JustTodo

A menu bar todo list for macOS. Press Enter for a new line, Backspace on an empty line to delete it, click the box to cross it off. That is the whole app.

![JustTodo](screenshot.png)

No Electron, no Tauri, no Xcode project. The shell is one Swift file using AppKit and the system WebKit; the list is a React page rendered inside it. The finished app is 650 KB and has zero runtime dependencies.

## Build

Needs macOS 14+, [bun](https://bun.sh) and the Xcode command line tools (`xcode-select --install`).

```sh
./build.sh            # produces JustTodo.app next to the sources
./build.sh --install  # also copies it to /Applications and launches it
```

## Layout

```
main.swift   status item, popover, floating window, JSON storage
build.sh     bun build + swiftc + iconutil + ad-hoc codesign
icon.png     source for the generated .icns
web/         the React UI loaded through the justtodo:// scheme
  src/App.tsx    the list and its keyboard behaviour
  src/native.ts  the bridge to Swift
```

Todos live in `~/Library/Application Support/JustTodo/todos.json`, written by Swift, never by the web view. Delete the file to start over.

Both windows (popover and the detached one) render their own web view, so Swift broadcasts every save to the other view to keep them in sync.

## Installing a downloaded build

The app is signed ad hoc, so macOS quarantines it when it arrives from the internet. Clear the flag once:

```sh
xattr -dr com.apple.quarantine /Applications/JustTodo.app
```

Building it yourself avoids this entirely.

## License

MIT
