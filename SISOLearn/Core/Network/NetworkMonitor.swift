import Network
import SwiftUI
import Observation

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi, cellular, unknown
    }

    @ObservationIgnored
    private let monitor = NWPathMonitor()
    @ObservationIgnored
    private let queue = DispatchQueue(label: "com.sisolearn.networkmonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else {
                    self?.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
