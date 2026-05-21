import AppKit
import Foundation

@main
final class IShowSpeedApp: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    static func main() {
        let app = NSApplication.shared
        let delegate = IShowSpeedApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = AppSettings()
        let monitor = NetworkSpeedMonitor(provider: NetworkStatsProvider())
        let dormTrafficService = DormTrafficService(fetcher: DormTrafficClient())
        statusBarController = StatusBarController(
            monitor: monitor,
            dormTrafficService: dormTrafficService,
            settings: settings
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
