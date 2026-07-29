import Foundation

struct ConnectivityPayload: Codable, Equatable, Sendable {
  let settings: CueSettings
  let updatedAt: Date
}
