import AppKit
import Foundation

@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let monitor: NetworkSpeedMonitor
    private let dormTrafficService: DormTrafficService
    private let settings: AppSettings
    private let formatter = SpeedFormatter()
    private let statusFont = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)

    private var latestSpeed = NetworkSpeed.zero
    private var latestDormTraffic: DailyTrafficUsage?
    private var isDormTrafficRefreshInProgress = false
    private let downloadItem = NSMenuItem(title: "Download: 0.0 B/s", action: nil, keyEquivalent: "")
    private let uploadItem = NSMenuItem(title: "Upload: 0.0 B/s", action: nil, keyEquivalent: "")
    private let dormTrafficStatusItem = NSMenuItem(title: "Dorm Traffic: not loaded", action: nil, keyEquivalent: "")
    private let dormTrafficTotalItem = NSMenuItem(title: "Today Total: --", action: nil, keyEquivalent: "")
    private let dormTrafficDownloadItem = NSMenuItem(title: "Today Download: --", action: nil, keyEquivalent: "")
    private let dormTrafficUploadItem = NSMenuItem(title: "Today Upload: --", action: nil, keyEquivalent: "")
    private let dormTrafficUpdatedItem = NSMenuItem(title: "Updated: --", action: nil, keyEquivalent: "")
    private let dormTrafficRefreshItem = NSMenuItem(title: "Refresh Dorm Traffic", action: #selector(refreshDormTrafficManually), keyEquivalent: "r")
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
    }

    private func configureStatusItem() {
        statusItem.button?.alignment = .center
        statusItem.button?.lineBreakMode = .byClipping
        setStatusTitle(download: "0.0 B/s", upload: "0.0 B/s")
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
        setStatusTitle(download: download, upload: upload)
        downloadItem.title = "Download: \(download)"
        uploadItem.title = "Upload: \(upload)"
    }

    private func setStatusTitle(download: String, upload: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineHeightMultiple = 0.82
        paragraphStyle.maximumLineHeight = 10
        paragraphStyle.minimumLineHeight = 10

        statusItem.button?.attributedTitle = NSAttributedString(
            string: "↓ \(download)\n↑ \(upload)",
            attributes: [
                .font: statusFont,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle,
                .baselineOffset: -1
            ]
        )
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        downloadItem.isEnabled = false
        uploadItem.isEnabled = false
        menu.addItem(downloadItem)
        menu.addItem(uploadItem)
        menu.addItem(.separator())

        dormTrafficStatusItem.isEnabled = false
        dormTrafficTotalItem.isEnabled = false
        dormTrafficDownloadItem.isEnabled = false
        dormTrafficUploadItem.isEnabled = false
        dormTrafficUpdatedItem.isEnabled = false
        dormTrafficRefreshItem.target = self
        dormTrafficRefreshItem.isEnabled = !isDormTrafficRefreshInProgress
        menu.addItem(dormTrafficStatusItem)
        menu.addItem(dormTrafficTotalItem)
        menu.addItem(dormTrafficDownloadItem)
        menu.addItem(dormTrafficUploadItem)
        menu.addItem(dormTrafficUpdatedItem)
        menu.addItem(dormTrafficRefreshItem)
        menu.addItem(.separator())

        let intervalMenu = NSMenu()
        for interval in RefreshInterval.allCases {
            let item = NSMenuItem(title: interval.menuTitle, action: #selector(selectRefreshInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = interval.rawValue
            item.state = settings.refreshInterval == interval ? .on : .off
            intervalMenu.addItem(item)
        }
        let intervalItem = NSMenuItem(title: "Refresh Interval", action: nil, keyEquivalent: "")
        intervalItem.submenu = intervalMenu
        menu.addItem(intervalItem)

        let unitMenu = NSMenu()
        for mode in SpeedUnitMode.allCases {
            let item = NSMenuItem(title: mode.menuTitle, action: #selector(selectUnitMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = settings.unitMode == mode ? .on : .off
            unitMenu.addItem(item)
        }
        let unitItem = NSMenuItem(title: "Units", action: nil, keyEquivalent: "")
        unitItem.submenu = unitMenu
        menu.addItem(unitItem)

        menu.addItem(.separator())
        launchAtLoginItem.target = self
        launchAtLoginItem.state = settings.launchAtLogin ? .on : .off
        launchAtLoginItem.isEnabled = LoginItemController.isSupported
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit IShowSpeed", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        updateDisplayedSpeed()
        updateDormTrafficItems()
    }

    private func updateDormTrafficItems(status: String? = nil) {
        dormTrafficStatusItem.title = status ?? "Dorm Traffic: ready"
        dormTrafficRefreshItem.isEnabled = !isDormTrafficRefreshInProgress

        guard let latestDormTraffic else {
            dormTrafficTotalItem.title = "Today Total: --"
            dormTrafficDownloadItem.title = "Today Download: --"
            dormTrafficUploadItem.title = "Today Upload: --"
            dormTrafficUpdatedItem.title = "Updated: --"
            return
        }

        dormTrafficTotalItem.title = "Today Total: \(latestDormTraffic.total)"
        dormTrafficDownloadItem.title = "Today Download: \(latestDormTraffic.download)"
        dormTrafficUploadItem.title = "Today Upload: \(latestDormTraffic.upload)"
        dormTrafficUpdatedItem.title = "Updated: \(dormTrafficDateFormatter.string(from: latestDormTraffic.fetchedAt))"
    }

    private func refreshDormTraffic(forceRefresh: Bool) {
        guard !isDormTrafficRefreshInProgress else {
            return
        }

        isDormTrafficRefreshInProgress = true
        updateDormTrafficItems(status: latestDormTraffic == nil ? "Dorm Traffic: loading..." : "Dorm Traffic: refreshing...")

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let usage = try await dormTrafficService.usage(forceRefresh: forceRefresh)
                latestDormTraffic = usage
                isDormTrafficRefreshInProgress = false
                updateDormTrafficItems()
            } catch {
                isDormTrafficRefreshInProgress = false
                updateDormTrafficItems(status: "Dorm Traffic: unavailable")
            }
        }
    }

    @objc private func selectRefreshInterval(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? Double,
              let interval = RefreshInterval(rawValue: rawValue) else {
            return
        }

        settings.refreshInterval = interval
        monitor.updateInterval(interval.rawValue)
        rebuildMenu()
    }

    @objc private func selectUnitMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = SpeedUnitMode(rawValue: rawValue) else {
            return
        }

        settings.unitMode = mode
        rebuildMenu()
    }

    @objc private func refreshDormTrafficManually() {
        refreshDormTraffic(forceRefresh: true)
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
        monitor.stop()
        NSApplication.shared.terminate(nil)
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        refreshDormTraffic(forceRefresh: false)
    }
}
