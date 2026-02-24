import ActivityKit
import SwiftUI
import WidgetKit

private struct LiveActivityAvatar: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Image(systemName: "moon.stars.fill")
                .resizable()
                .scaledToFit()
                .padding(size * 0.22)
                .frame(width: size, height: size)
                .foregroundStyle(.primary)

            Image("LiveActivityAvatar")
                .renderingMode(.original)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

private func debugLog(_ message: String) {
    #if DEBUG
        print(message)
    #endif
}

@available(iOSApplicationExtension 16.1, *)
struct IftarAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var iftarDate: Date
        var phase: String

        enum CodingKeys: String, CodingKey {
            case title
            case subtitle
            case iftarDate
            case endDate
            case phase
        }

        init(title: String, subtitle: String, iftarDate: Date, phase: String) {
            self.title = title
            self.subtitle = subtitle
            self.iftarDate = iftarDate
            self.phase = phase
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Iftara kalan"
            subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? "Ramazan bereketi"
            phase = try container.decodeIfPresent(String.self, forKey: .phase) ?? "countdown"

            let decodedIftarDate = try container.decodeIfPresent(Date.self, forKey: .iftarDate)
            let decodedLegacyDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
            let source: String
            if let value = decodedIftarDate {
                iftarDate = value
                source = "iftarDate"
            } else if let legacyValue = decodedLegacyDate {
                iftarDate = legacyValue
                source = "endDate"
            } else {
                iftarDate = Date()
                source = "fallbackNow"
            }

            let remainingSeconds = max(0, Int(iftarDate.timeIntervalSinceNow))
            debugLog(
                "[NurAiWidgetsLiveActivity] decode source=\(source) remainingSeconds=\(remainingSeconds)"
            )
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(title, forKey: .title)
            try container.encode(subtitle, forKey: .subtitle)
            try container.encode(iftarDate, forKey: .iftarDate)
            try container.encode(phase, forKey: .phase)
        }
    }

    var name: String
}

@available(iOSApplicationExtension 16.1, *)
struct NurAiWidgetsLiveActivity: Widget {
    private let lockScreenBackgroundTint = Color(red: 0.96, green: 0.93, blue: 0.88)
    private let lockScreenActionTint = Color(red: 0.30, green: 0.24, blue: 0.18)
    private let islandKeylineTint = Color(red: 0.89, green: 0.61, blue: 0.28)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IftarAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    LiveActivityAvatar(size: 30)
                    Text("Iftara kalan")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                countdownLabel(iftarDate: context.state.iftarDate, large: true)

                Text(context.state.subtitle.isEmpty ? "Ramazan bereketi" : context.state.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
            .activityBackgroundTint(lockScreenBackgroundTint)
            .activitySystemActionForegroundColor(lockScreenActionTint)
            .widgetURL(URL(string: "duaya://ramadan"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityAvatar(size: 30)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdownLabel(iftarDate: context.state.iftarDate, large: false)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Iftara kalan")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Text("Iftara kalan")
                            .foregroundStyle(.primary)
                        countdownLabel(iftarDate: context.state.iftarDate, large: false)
                    }
                }
            } compactLeading: {
                LiveActivityAvatar(size: 22)
            } compactTrailing: {
                countdownLabel(iftarDate: context.state.iftarDate, large: false)
            } minimal: {
                LiveActivityAvatar(size: 20)
            }
            .widgetURL(URL(string: "duaya://ramadan"))
            .keylineTint(islandKeylineTint)
        }
    }

    @ViewBuilder
    private func countdownLabel(iftarDate: Date, large: Bool) -> some View {
        if isFutureDate(iftarDate) {
            Text(timerInterval: Date()...iftarDate, countsDown: true)
                .font(
                    large
                        ? .system(size: 24, weight: .bold, design: .rounded)
                        : .system(size: 13, weight: .semibold, design: .rounded)
                )
                .monospacedDigit()
                .foregroundStyle(.primary)
        } else {
            Text("--:--")
                .font(
                    large
                        ? .system(size: 24, weight: .bold, design: .rounded)
                        : .system(size: 13, weight: .semibold, design: .rounded)
                )
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }

    private func isFutureDate(_ date: Date) -> Bool {
        date.timeIntervalSinceNow > 0
    }
}
