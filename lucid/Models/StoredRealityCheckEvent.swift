import Foundation
import SwiftData

@Model
final class StoredRealityCheckEvent {
  @Attribute(.unique) var id: UUID
  var timestamp: Date
  var sourceRawValue: String
  var resultRawValue: String
  var cueWord: String

  init(event: RealityCheckEvent) {
    id = event.id
    timestamp = event.timestamp
    sourceRawValue = event.source.rawValue
    resultRawValue = event.result.rawValue
    cueWord = event.cueWord
  }

  var source: RealityCheckEvent.Source {
    RealityCheckEvent.Source(rawValue: sourceRawValue) ?? .iPhoneManual
  }

  var result: RealityCheckEvent.Result {
    RealityCheckEvent.Result(rawValue: resultRawValue) ?? .skipped
  }
}
