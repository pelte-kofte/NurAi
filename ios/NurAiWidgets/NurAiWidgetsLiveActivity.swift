import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

private struct LiveActivityAvatarView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if hasAvatarAsset {
                Image("LiveActivityAvatar", bundle: .main)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "moon.stars.fill")
                .renderingMode(.original)
                .resizable()
                    .scaledToFit()
                    .padding(size * 0.22)
                    .foregroundStyle(.white)
                    .background(Color(red: 0.12, green: 0.22, blue: 0.27))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
        .accessibilityHidden(true)
    }

    private var hasAvatarAsset: Bool {
        UIImage(named: "LiveActivityAvatar", in: .main, compatibleWith: nil) != nil
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
    private let lockScreenBackgroundTint = Color(red: 0.10, green: 0.14, blue: 0.21)
    private let lockScreenActionTint = Color(red: 0.93, green: 0.96, blue: 0.97)
    private let lockPrimaryText = Color(red: 0.97, green: 0.98, blue: 0.99)
    private let lockSecondaryText = Color(red: 0.85, green: 0.90, blue: 0.92)
    private let accentEarth = Color(red: 0.71, green: 0.48, blue: 0.35) // #B57A5A
    private let islandText = Color.white
    private let islandKeylineTint = Color(red: 0.71, green: 0.48, blue: 0.35)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IftarAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    LiveActivityAvatarView(size: 30)
                    Text(context.state.title.isEmpty ? "Iftara kalan" : context.state.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(lockPrimaryText)
                        .lineLimit(1)
                }

                countdownLabel(iftarDate: context.state.iftarDate, large: true)

                Text(context.state.subtitle.isEmpty ? "Ramazan bereketi" : context.state.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(lockSecondaryText)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            .tint(accentEarth)
            .activityBackgroundTint(lockScreenBackgroundTint)
            .activitySystemActionForegroundColor(lockScreenActionTint)
            .widgetURL(URL(string: "duaya://ramadan"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityAvatarView(size: 30)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdownLabel(iftarDate: context.state.iftarDate, large: false)
                        .foregroundStyle(islandText)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.title.isEmpty ? "Iftara kalan" : context.state.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(islandText)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Text(context.state.title.isEmpty ? "Iftara kalan" : context.state.title)
                            .foregroundStyle(accentEarth)
                        countdownLabel(iftarDate: context.state.iftarDate, large: false)
                            .foregroundStyle(islandText)
                    }
                }
            } compactLeading: {
                LiveActivityAvatarView(size: 22)
            } compactTrailing: {
                countdownLabel(iftarDate: context.state.iftarDate, large: false)
                    .foregroundStyle(islandText)
            } minimal: {
                LiveActivityAvatarView(size: 20)
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
                .foregroundStyle(lockPrimaryText)
        } else {
            Text("--:--")
                .font(
                    large
                        ? .system(size: 24, weight: .bold, design: .rounded)
                        : .system(size: 13, weight: .semibold, design: .rounded)
                )
                .monospacedDigit()
                .foregroundStyle(lockPrimaryText)
        }
    }

    private func isFutureDate(_ date: Date) -> Bool {
        date.timeIntervalSinceNow > 0
    }
}
