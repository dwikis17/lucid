import Foundation
import SwiftData

@Model
final class StoredRealityCheckEvent {
  var id: UUID = UUID()
  var timestamp: Date = Date.now
  var sourceRawValue: String = RealityCheckEvent.Source.iPhoneManual.rawValue
  var resultRawValue: String = RealityCheckEvent.Result.skipped.rawValue
  var cueWord: String = ""

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
