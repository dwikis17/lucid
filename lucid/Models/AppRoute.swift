import Foundation

enum AppRoute: Identifiable, Hashable {
  case realityCheck(source: RealityCheckEvent.Source)
  case dreamEntry(id: UUID)
  case wbtb

  var id: String {
    switch self {
    case let .realityCheck(source):
      "reality-check-\(source.rawValue)"
    case let .dreamEntry(id):
      "dream-entry-\(id.uuidString)"
    case .wbtb:
      "wbtb"
    }
  }
}
