# just todo.

![](docs/menubar.png)

Enter makes a line.
Backspace takes it away.
Click the box to cross it off.

Nothing else.

![](docs/window.png)

### Get it

[**JustTodo.zip**](https://github.com/szymonlaskowski/justtodo/releases/latest/download/JustTodo.zip) → Applications → once, in Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/JustTodo.app
```

288 KB. macOS 14. Apple Silicon and Intel. Signed ad hoc, hence the line above.

### Build it

```sh
./build.sh --install
```

Needs [bun](https://bun.sh) and `xcode-select --install`.

To publish a version, commit, then `./build.sh --release 1.1.0`. It tags, builds and creates the GitHub release. Needs [gh](https://cli.github.com).

### All of it

```
main.swift       menu bar, popover, window, storage   321
web/src/App.tsx  the list and its two keys            155
build.sh         bun, swiftc, lipo, iconutil           72
web/src/*        the rest of the page                  80
```

One Swift file around a system web view. No Electron, no Tauri, no Xcode project, no runtime dependencies.

Your todos are plain JSON in `~/Library/Application Support/JustTodo/todos.json`. Your file.

Once a day it asks GitHub for the latest release. If there is a newer one, right-click the icon for Update. That is its only network request.

MIT
