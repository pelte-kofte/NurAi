import AppIntents
import WidgetKit

enum DailyWidgetContentType: String, AppEnum {
  case verse
  case hadith
  case asma

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: LocalizedStringResource("content_type_param"))
  }

  static var caseDisplayRepresentations: [DailyWidgetContentType: DisplayRepresentation] {
    [
      .verse: DisplayRepresentation(title: LocalizedStringResource("content_type_verse")),
      .hadith: DisplayRepresentation(title: LocalizedStringResource("content_type_hadith")),
      .asma: DisplayRepresentation(title: LocalizedStringResource("content_type_asma")),
    ]
  }
}

struct DailyWidgetConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { LocalizedStringResource("widget_config_title") }
  static var description: IntentDescription {
    IntentDescription(LocalizedStringResource("widget_config_description"))
  }

  @Parameter(title: LocalizedStringResource("content_type_param"), default: .verse)
  var contentType: DailyWidgetContentType
}
