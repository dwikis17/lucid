import Foundation
import SwiftData

@Model
final class StoredWBTBSession {
  var id: UUID = UUID()
  var completedAt: Date = Date.now
  var routineMinutes: Int = 5

  init(id: UUID = UUID(), completedAt: Date = .now, routineMinutes: Int = 5) {
    self.id = id
    self.completedAt = completedAt
    self.routineMinutes = routineMinutes
  }
}
