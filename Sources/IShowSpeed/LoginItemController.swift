import Foundation

#if os(macOS)
import ServiceManagement

enum LoginItemController {
    static func setEnabled(_ isEnabled: Bool) throws {
        if #available(macOS 13.0, *) {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        }
    }

    static var isSupported: Bool {
        if #available(macOS 13.0, *) {
            return Bundle.main.bundleIdentifier != nil
        }
        return false
    }
}
#endif
