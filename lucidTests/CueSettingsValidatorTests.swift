import Testing
@testable import lucid

struct CueSettingsValidatorTests {
  @Test
  func defaultSettingsAreValid() {
    #expect(CueSettingsValidator.errors(for: .defaultValue).isEmpty)
  }

  @Test
  func invalidCueAndWindowReturnInlineErrors() {
    var settings = CueSettings.defaultValue
    settings.cueWord = " \n"
    settings.daytimeEndMinutes = settings.daytimeStartMinutes + 60

    let errors = CueSettingsValidator.errors(for: settings)

    #expect(errors.count == 3)
    #expect(errors.contains("Enter a cue word."))
    #expect(errors.contains("The cue word cannot contain a new line."))
    #expect(errors.contains("The daytime window must be at least 6 hours."))
  }
}
