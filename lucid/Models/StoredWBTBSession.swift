import Foundation
import SwiftData

@Model
final class StoredWBTBSession {
  var id: UUID
  var completedAt: Date
  var routineMinutes: Int

  init(id: UUID = UUID(), completedAt: Date = .now, routineMinutes: Int = 5) {
    self.id = id
    self.completedAt = completedAt
    self.routineMinutes = routineMinutes
  }
}
