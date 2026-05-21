import Foundation
import Testing
@testable import IShowSpeed

@Suite("AppSettings")
struct AppSettingsTests {
    @Test func usesDefaultsWhenNoValuesExist() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)

        #expect(settings.refreshInterval == .oneSecond)
        #expect(settings.unitMode == .auto)
        #expect(settings.launchAtLogin == false)
    }

    @Test func persistsValues() {
        let defaults = makeDefaults()
        let settings = AppSettings(defaults: defaults)

        settings.refreshInterval = .halfSecond
        settings.unitMode = .megabytes
        settings.launchAtLogin = true

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.refreshInterval == .halfSecond)
        #expect(reloaded.unitMode == .megabytes)
        #expect(reloaded.launchAtLogin == true)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "IShowSpeedTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
