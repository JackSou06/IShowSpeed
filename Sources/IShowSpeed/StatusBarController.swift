import AppKit
import Foundation

@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let monitor: NetworkSpeedMonitor
    private let dormTrafficService: DormTrafficService
    private let settings: AppSettings
    private let formatter = SpeedFormatter()
    private let titleFormatter = StatusTitleFormatter()
    private let statusFont = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)
    private let singleLineStatusFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    private var latestSpeed = NetworkSpeed.zero
    private var latestDormTraffic: DailyTrafficUsage?
    private var isDormTrafficUnavailable = false
    private var isDormTrafficRefreshInProgress = false
    private var dormAutoRefreshTimer: Timer?
    private let downloadItem = NSMenuItem(title: "Download: 0.0 B/s", action: nil, keyEquivalent: "")
    private let uploadItem = NSMenuItem(title: "Upload: 0.0 B/s", action: nil, keyEquivalent: "")
    private let dormTrafficStatusItem = NSMenuItem(title: "Dorm Usage", action: nil, keyEquivalent: "")
    private let dormTrafficTotalItem = NSMenuItem(title: "--", action: nil, keyEquivalent: "")
    private let dormTrafficUpdatedItem = NSMenuItem(title: "Updated: --", action: nil, keyEquivalent: "")
    private let dormTrafficRefreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshDormTrafficManually), keyEquivalent: "r")
    private let dormTrafficOpenPageItem = NSMenuItem(title: "Open Page", action: #selector(openDormTrafficPage), keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private lazy var dormTrafficDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    init(monitor: NetworkSpeedMonitor, dormTrafficService: DormTrafficService, settings: AppSettings) {
        self.monitor = monitor
        self.dormTrafficService = dormTrafficService
        self.settings = settings
        super.init()
        configureStatusItem()
        configureMonitor()
        rebuildMenu()
        monitor.start(interval: settings.refreshInterval.rawValue)
        configureDormAutoRefreshTimer()
    }

    private func configureStatusItem() {
        statusItem.button?.alignment = .center
        statusItem.button?.lineBreakMode = .byClipping
        updateStatusTitle()
        statusItem.menu = NSMenu()
    }

    private func configureMonitor() {
        monitor.onSpeedUpdate = { [weak self] speed in
            self?.latestSpeed = speed
            self?.updateDisplayedSpeed()
        }
    }

    private func updateDisplayedSpeed() {
        let download = formatter.string(from: latestSpeed.downloadBytesPerSecond, unitMode: settings.unitMode)
        let upload = formatter.string(from: latestSpeed.uploadBytesPerSecond, unitMode: settings.unitMode)
        updateStatusTitle()
        downloadItem.title = "Download: \(download)"
        uploadItem.title = "Upload: \(upload)"
    }

    private func updateStatusTitle() {
        let content = titleFormatter.content(
            displayMode: settings.displayMode,
            speed: latestSpeed,
            unitMode: settings.unitMode,
            dormTraffic: latestDormTraffic,
            dormTrafficUnavailable: isDormTrafficUnavailable
        )
        setStatusTitle(content)
    }

    private func setStatusTitle(_ content: StatusTitleContent) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        if content.isMultiline {
            paragraphStyle.lineHeightMultiple = 0.82
            paragraphStyle.maximumLineHeight = 10
            paragraphStyle.minimumLineHeight = 10
        }

        let font = content.isMultiline ? statusFont : singleLineStatusFont
        let attributedTitle = NSMutableAttributedString()

        for (index, line) in content.lines.enumerated() {
            if index > 0 {
                attributedTitle.append(NSAttributedString(string: "\n"))
            }

            if let symbolName = line.symbolName,
               let image = symbolImage(symbolName) {
                image.size = NSSize(width: 9, height: 9)
                let attachment = NSTextAttachment()
                attachment.image = image
                attachment.bounds = NSRect(x: 0, y: -1.5, width: 9, height: 9)
                attributedTitle.append(NSAttributedString(attachment: attachment))
                attributedTitle.append(NSAttributedString(string: " "))
            }

            attributedTitle.append(NSAttributedString(string: line.text))
        }

        attributedTitle.addAttributes(
            [
                .font: font,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle,
                .baselineOffset: content.isMultiline ? -1 : 0
            ],
            range: NSRange(location: 0, length: attributedTitle.length)
        )

        statusItem.button?.attributedTitle = attributedTitle
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        downloadItem.isEnabled = false
        downloadItem.image = symbolImage("arrow.down.circle")
        uploadItem.isEnabled = false
        uploadItem.image = symbolImage("arrow.up.circle")
        menu.addItem(downloadItem)
        menu.addItem(uploadItem)
        menu.addItem(.separator())

        dormTrafficStatusItem.isEnabled = false
        dormTrafficStatusItem.image = symbolImage("chart.bar")
        dormTrafficTotalItem.isEnabled = false
        dormTrafficUpdatedItem.isEnabled = false
        dormTrafficUpdatedItem.image = symbolImage("clock")
        dormTrafficRefreshItem.target = self
        dormTrafficRefreshItem.image = symbolImage("arrow.clockwise")
        dormTrafficRefreshItem.isEnabled = !isDormTrafficRefreshInProgress
        dormTrafficOpenPageItem.target = self
        dormTrafficOpenPageItem.image = symbolImage("arrow.up.right.square")
        menu.addItem(dormTrafficStatusItem)
        menu.addItem(dormTrafficTotalItem)
        menu.addItem(dormTrafficUpdatedItem)
        menu.addItem(dormTrafficRefreshItem)
        menu.addItem(dormTrafficOpenPageItem)
        menu.addItem(.separator())

        let displayModeMenu = NSMenu()
        for displayMode in DisplayMode.allCases {
            let item = NSMenuItem(title: displayMode.menuTitle, action: #selector(selectDisplayMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = displayMode.rawValue
            item.state = settings.displayMode == displayMode ? .on : .off
            displayModeMenu.addItem(item)
        }
        let displayModeItem = NSMenuItem(title: "Display Mode", action: nil, keyEquivalent: "")
        displayModeItem.image = symbolImage("rectangle.2.swap")
        displayModeItem.submenu = displayModeMenu
        menu.addItem(displayModeItem)

        menu.addItem(.separator())
        menu.addItem(settingsMenuItem())

        menu.addItem(.separator())
        let quitItem = makeMenuItem(title: "Quit IShowSpeed", action: #selector(quit), keyEquivalent: "q", symbolName: "power")
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateDisplayedSpeed()
        updateDormTrafficItems()
    }

    private func settingsMenuItem() -> NSMenuItem {
        let settingsMenu = NSMenu()

        let dormAutoRefreshMenu = NSMenu()
        for interval in DormAutoRefreshInterval.allCases {
            let item = NSMenuItem(title: interval.menuTitle, action: #selector(selectDormAutoRefreshInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = interval.rawValue
            item.state = settings.dormAutoRefreshInterval == interval ? .on : .off
            dormAutoRefreshMenu.addItem(item)
        }
        let dormAutoRefreshItem = NSMenuItem(title: "Dorm Auto Refresh", action: nil, keyEquivalent: "")
        dormAutoRefreshItem.image = symbolImage("timer")
        dormAutoRefreshItem.submenu = dormAutoRefreshMenu
        settingsMenu.addItem(dormAutoRefreshItem)

        let intervalMenu = NSMenu()
        for interval in RefreshInterval.allCases {
            let item = NSMenuItem(title: interval.menuTitle, action: #selector(selectRefreshInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = interval.rawValue
            item.state = settings.refreshInterval == interval ? .on : .off
            intervalMenu.addItem(item)
        }
        let intervalItem = NSMenuItem(title: "Refresh Interval", action: nil, keyEquivalent: "")
        intervalItem.image = symbolImage("speedometer")
        intervalItem.submenu = intervalMenu
        settingsMenu.addItem(intervalItem)

        let unitMenu = NSMenu()
        for mode in SpeedUnitMode.allCases {
            let item = NSMenuItem(title: mode.menuTitle, action: #selector(selectUnitMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = settings.unitMode == mode ? .on : .off
            unitMenu.addItem(item)
        }
        let unitItem = NSMenuItem(title: "Units", action: nil, keyEquivalent: "")
        unitItem.image = symbolImage("ruler")
        unitItem.submenu = unitMenu
        settingsMenu.addItem(unitItem)

        settingsMenu.addItem(.separator())
        launchAtLoginItem.target = self
        launchAtLoginItem.image = symbolImage("poweron")
        launchAtLoginItem.state = settings.launchAtLogin ? .on : .off
        launchAtLoginItem.isEnabled = LoginItemController.isSupported
        settingsMenu.addItem(launchAtLoginItem)

        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsItem.image = symbolImage("gearshape")
        settingsItem.submenu = settingsMenu
        return settingsItem
    }

    private func updateDormTrafficItems(status: String? = nil) {
        dormTrafficStatusItem.title = status ?? "Dorm Usage"
        dormTrafficRefreshItem.isEnabled = !isDormTrafficRefreshInProgress

        guard let latestDormTraffic else {
            dormTrafficTotalItem.title = "--"
            dormTrafficUpdatedItem.title = "Updated: --"
            return
        }

        dormTrafficTotalItem.title = latestDormTraffic.total
        dormTrafficUpdatedItem.title = "Updated: \(dormTrafficDateFormatter.string(from: latestDormTraffic.fetchedAt))"
    }

    private func refreshDormTraffic(forceRefresh: Bool) {
        guard !isDormTrafficRefreshInProgress else {
            return
        }

        isDormTrafficRefreshInProgress = true
        updateDormTrafficItems(status: latestDormTraffic == nil ? "Loading dorm usage..." : "Refreshing dorm usage...")

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let usage = try await dormTrafficService.usage(forceRefresh: forceRefresh)
                latestDormTraffic = usage
                isDormTrafficUnavailable = false
                isDormTrafficRefreshInProgress = false
                updateDormTrafficItems()
                updateStatusTitle()
            } catch {
                isDormTrafficUnavailable = latestDormTraffic == nil
                isDormTrafficRefreshInProgress = false
                updateDormTrafficItems(status: "Dorm usage unavailable")
                updateStatusTitle()
            }
        }
    }

    private func configureDormAutoRefreshTimer() {
        dormAutoRefreshTimer?.invalidate()
        dormAutoRefreshTimer = nil

        let interval = settings.dormAutoRefreshInterval
        guard interval != .off else {
            return
        }

        dormAutoRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval.rawValue, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDormTraffic(forceRefresh: true)
            }
        }
        dormAutoRefreshTimer?.tolerance = min(interval.rawValue * 0.1, 30)
    }

    @objc private func selectRefreshInterval(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? Double,
              let interval = RefreshInterval(rawValue: rawValue) else {
            return
        }

        settings.refreshInterval = interval
        monitor.updateInterval(interval.rawValue)
        updateMenuItemStates(in: sender.menu)
    }

    @objc private func selectUnitMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = SpeedUnitMode(rawValue: rawValue) else {
            return
        }

        settings.unitMode = mode
        updateMenuItemStates(in: sender.menu)
        updateStatusTitle()
    }

    @objc private func selectDisplayMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let displayMode = DisplayMode(rawValue: rawValue) else {
            return
        }

        settings.displayMode = displayMode
        updateMenuItemStates(in: sender.menu)
        updateStatusTitle()

        if displayMode == .dormDailyUsage {
            refreshDormTraffic(forceRefresh: false)
        }
    }

    @objc private func selectDormAutoRefreshInterval(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? Double,
              let interval = DormAutoRefreshInterval(rawValue: rawValue) else {
            return
        }

        settings.dormAutoRefreshInterval = interval
        configureDormAutoRefreshTimer()
        updateMenuItemStates(in: sender.menu)
    }

    private func updateMenuItemStates(in menu: NSMenu?) {
        guard let menu else {
            return
        }

        for item in menu.items {
            if let rawValue = item.representedObject as? Double,
               let interval = RefreshInterval(rawValue: rawValue) {
                item.state = settings.refreshInterval == interval ? .on : .off
            } else if let rawValue = item.representedObject as? Double,
                      let interval = DormAutoRefreshInterval(rawValue: rawValue) {
                item.state = settings.dormAutoRefreshInterval == interval ? .on : .off
            } else if let rawValue = item.representedObject as? String,
                      let mode = SpeedUnitMode(rawValue: rawValue) {
                item.state = settings.unitMode == mode ? .on : .off
            } else if let rawValue = item.representedObject as? String,
                      let displayMode = DisplayMode(rawValue: rawValue) {
                item.state = settings.displayMode == displayMode ? .on : .off
            }
        }
    }

    private func makeMenuItem(
        title: String,
        action: Selector?,
        keyEquivalent: String = "",
        symbolName: String? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        if let symbolName {
            item.image = symbolImage(symbolName)
        }
        return item
    }

    private func symbolImage(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }

    @objc private func refreshDormTrafficManually() {
        refreshDormTraffic(forceRefresh: true)
    }

    @objc private func openDormTrafficPage() {
        guard let url = URL(string: "https://dorm-long-1.cc.ntu.edu.tw/login_online_detail.php") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func toggleLaunchAtLogin() {
        let nextValue = !settings.launchAtLogin

        do {
            try LoginItemController.setEnabled(nextValue)
            settings.launchAtLogin = nextValue
        } catch {
            settings.launchAtLogin = false
            showLaunchAtLoginError(error)
        }

        rebuildMenu()
    }

    private func showLaunchAtLoginError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Launch at Login is unavailable"
        alert.informativeText = "macOS could not update the login item setting. Try using the packaged .app build."
        alert.alertStyle = .warning
        alert.runModal()
    }

    @objc private func quit() {
        dormAutoRefreshTimer?.invalidate()
        monitor.stop()
        NSApplication.shared.terminate(nil)
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        refreshDormTraffic(forceRefresh: false)
    }
}
