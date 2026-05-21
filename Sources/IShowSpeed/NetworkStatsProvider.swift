import Foundation

#if os(macOS)
import Darwin

struct NetworkStatsProvider: NetworkStatsProviding {
    func currentStats() throws -> NetworkStats {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let firstInterface = interfaces else {
            throw NetworkStatsError.unavailable
        }
        defer { freeifaddrs(interfaces) }

        var downloadBytes: UInt64 = 0
        var uploadBytes: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = firstInterface

        while let interface = cursor {
            defer { cursor = interface.pointee.ifa_next }

            let flags = Int32(interface.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_LOOPBACK == 0 else {
                continue
            }

            guard let address = interface.pointee.ifa_addr, address.pointee.sa_family == UInt8(AF_LINK) else {
                continue
            }

            guard let data = interface.pointee.ifa_data else {
                continue
            }

            let stats = data.assumingMemoryBound(to: if_data.self).pointee
            downloadBytes += UInt64(stats.ifi_ibytes)
            uploadBytes += UInt64(stats.ifi_obytes)
        }

        return NetworkStats(downloadBytes: downloadBytes, uploadBytes: uploadBytes)
    }
}
#endif
