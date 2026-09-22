import AppKit
import ServiceManagement
import UniformTypeIdentifiers
import WebKit

let popoverWidth: CGFloat = 320
let initialContentHeight: CGFloat = 120
let maxContentHeight: CGFloat = 560
let siteRoot = Bundle.main.resourceURL!.appendingPathComponent("site")
let floatingWindowFrameName = "JustTodoWindow"
let todosFile = URL.applicationSupportDirectory.appending(path: "JustTodo/todos.json")

func readTodosFile() -> String {
    guard let saved = try? String(contentsOf: todosFile, encoding: .utf8) else { return "[]" }
    return saved
}

let todosWriter = DispatchQueue(label: "dev.szymon.justtodo.writer")

func writeTodosFile(_ todosAsJson: String) {
    todosWriter.async {
        try! FileManager.default.createDirectory(
            at: todosFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try! todosAsJson.write(to: todosFile, atomically: true, encoding: .utf8)
    }
}

final class SiteHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        let requested = task.request.url!
        let file = siteRoot.appendingPathComponent(requested.path)
        guard file.path.hasPrefix(siteRoot.path), let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let mimeType = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType
        let response = URLResponse(
            url: requested,
            mimeType: mimeType ?? "application/octet-stream",
            expectedContentLength: data.count,
            textEncodingName: nil
        )
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var popoverWebView: WKWebView!
    private var windowWebView: WKWebView?

    private lazy var floatingWindow: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: popoverWidth, height: initialContentHeight),
            styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.backgroundColor = .black
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.setFrameAutosaveName(floatingWindowFrameName)
        return panel
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        popoverWebView = makeWebView(query: "")
        popover.behavior = .transient
        popover.animates = false
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentSize = NSSize(width: popoverWidth, height: initialContentHeight)
        popover.contentViewController = NSViewController()
        popover.contentViewController!.view = makeClippingContainer(for: popoverWebView)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let button = statusItem.button!
        button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "JustTodo")
        button.target = self
        button.action = #selector(statusItemClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func makeWebView(query: String) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "height")
        configuration.userContentController.add(self, name: "openWindow")
        configuration.userContentController.add(self, name: "save")
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: "window.__todos = \(readTodosFile());",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        configuration.setURLSchemeHandler(SiteHandler(), forURLScheme: "justtodo")

        let webView = WKWebView(
            frame: NSRect(x: 0, y: 0, width: popoverWidth, height: maxContentHeight),
            configuration: configuration
        )
        webView.underPageBackgroundColor = .black
        webView.autoresizingMask = [.minYMargin]
        webView.load(URLRequest(url: URL(string: "justtodo://site/index.html" + query)!))
        return webView
    }

    private func makeClippingContainer(for webView: WKWebView) -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: popoverWidth, height: maxContentHeight))
        container.wantsLayer = true
        container.layer!.backgroundColor = NSColor.black.cgColor
        container.clipsToBounds = true
        container.addSubview(webView)
        return container
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusMenu()
            return
        }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        showPopover()
    }

    private func showPopover() {
        let button = statusItem.button!
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        focusLastRow(in: popoverWebView)
    }

    private func focusLastRow(in webView: WKWebView) {
        webView.window?.makeFirstResponder(webView)
        webView.evaluateJavaScript("document.querySelector('li:last-child input').focus()")
    }

    private func showStatusMenu() {
        let menu = NSMenu()
        let openAtLogin = menu.addItem(
            withTitle: "Open at Login",
            action: #selector(toggleOpenAtLogin),
            keyEquivalent: ""
        )
        openAtLogin.target = self
        openAtLogin.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit JustTodo",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        statusItem.menu = menu
        statusItem.button!.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleOpenAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func applicationShouldHandleReopen(_ app: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showPopover()
        return true
    }

    private func showFloatingWindow() {
        popover.performClose(nil)
        if windowWebView == nil {
            let webView = makeWebView(query: "?floating")
            windowWebView = webView
            floatingWindow.contentView = makeClippingContainer(for: webView)
            let icon = statusItem.button!.window!.frame
            floatingWindow.setFrameTopLeftPoint(NSPoint(x: icon.minX - 40, y: icon.minY - 6))
            floatingWindow.setFrameUsingName(floatingWindowFrameName)
        }
        floatingWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        focusLastRow(in: windowWebView!)
    }

    func userContentController(
        _ controller: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        switch message.name {
        case "openWindow":
            showFloatingWindow()
        case "save":
            let todosAsJson = message.body as! String
            writeTodosFile(todosAsJson)
            sendTodos(todosAsJson, skipping: message.webView!)
        case "height":
            resize(message.webView!, to: message.body as! Double)
        default:
            fatalError("unknown message from the web view: \(message.name)")
        }
    }

    private func resize(_ webView: WKWebView, to reportedHeight: Double) {
        let contentHeight = min(reportedHeight, maxContentHeight).rounded(.up)
        if contentHeight == 0 { return }

        if webView !== windowWebView {
            popover.contentSize = NSSize(width: popoverWidth, height: contentHeight)
            return
        }

        let top = floatingWindow.frame.maxY
        floatingWindow.setContentSize(NSSize(width: popoverWidth, height: contentHeight))
        var frame = floatingWindow.frame
        frame.origin.y = top - frame.height
        floatingWindow.setFrame(frame, display: true)
    }

    private func sendTodos(_ todosAsJson: String, skipping sender: WKWebView) {
        for webView in [popoverWebView, windowWebView] {
            guard let webView, webView !== sender else { continue }
            webView.evaluateJavaScript("window.__receiveTodos?.(\(todosAsJson))")
        }
    }
}

func makeMainMenu() -> NSMenu {
    let edit = NSMenu()
    let items: [(String, Selector, String)] = [
        ("Undo", Selector(("undo:")), "z"),
        ("Redo", Selector(("redo:")), "Z"),
        ("Cut", #selector(NSText.cut(_:)), "x"),
        ("Copy", #selector(NSText.copy(_:)), "c"),
        ("Paste", #selector(NSText.paste(_:)), "v"),
        ("Select All", #selector(NSText.selectAll(_:)), "a"),
        ("Quit JustTodo", #selector(NSApplication.terminate(_:)), "q"),
    ]
    for (title, action, key) in items {
        edit.addItem(withTitle: title, action: action, keyEquivalent: key)
    }

    let editItem = NSMenuItem()
    editItem.submenu = edit
    let mainMenu = NSMenu()
    mainMenu.addItem(editItem)
    return mainMenu
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.mainMenu = makeMainMenu()
app.setActivationPolicy(.accessory)
app.run()
