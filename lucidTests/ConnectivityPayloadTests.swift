import Foundation
import Testing
@testable import lucid

struct ConnectivityPayloadTests {
  @Test
  func payloadRoundTripsThroughJSON() throws {
    let payload = ConnectivityPayload(
      settings: .defaultValue,
      updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    let data = try JSONEncoder().encode(payload)
    let decoded = try JSONDecoder().decode(ConnectivityPayload.self, from: data)

    #expect(decoded == payload)
  }

  @Test
  func eventRoundTripsWithStableIdentifier() throws {
    let event = RealityCheckEvent(
      id: UUID(),
      timestamp: Date(timeIntervalSince1970: 1_800_000_000),
      source: .watchManual,
      result: .completed,
      cueWord: "Dream"
    )

    let data = try JSONEncoder().encode(event)
    let decoded = try JSONDecoder().decode(RealityCheckEvent.self, from: data)

    #expect(decoded == event)
    #expect(decoded.id == event.id)
  }
}
