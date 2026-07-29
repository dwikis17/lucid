import Foundation

enum AppRoute: Identifiable, Hashable {
  case realityCheck(source: RealityCheckEvent.Source)

  var id: String {
    switch self {
    case let .realityCheck(source):
      "reality-check-\(source.rawValue)"
    }
  }
}
