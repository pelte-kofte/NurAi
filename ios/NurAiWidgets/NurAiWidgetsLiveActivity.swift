import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

private struct LiveActivityAvatarView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let avatar = UIImage(named: "LiveActivityAvatar", in: .main, compatibleWith: nil) {
                Image(uiImage: avatar)
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
        var endDate: Date
        var mode: String
        var postMessage: String
        var postEndsAtDate: Date
        var phase: String

        enum CodingKeys: String, CodingKey {
            case title
            case subtitle
            case endDate
            case iftarDate
            case mode
            case postMessage
            case postEndsAtDate
            case postEndsAtEpochMs
            case phase
        }

        init(
            title: String,
            subtitle: String,
            endDate: Date,
            mode: String,
            postMessage: String,
            postEndsAtDate: Date,
            phase: String
        ) {
            self.title = title
            self.subtitle = subtitle
            self.endDate = endDate
            self.mode = mode
            self.postMessage = postMessage
            self.postEndsAtDate = postEndsAtDate
            self.phase = phase
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Iftara kalan"
            subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? "Ramazan bereketi"
            let decodedLegacyDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
            let decodedIftarDate = try container.decodeIfPresent(Date.self, forKey: .iftarDate)
            let source: String
            if let value = decodedLegacyDate {
                endDate = value
                source = "endDate"
            } else if let legacyValue = decodedIftarDate {
                endDate = legacyValue
                source = "iftarDate"
            } else {
                endDate = Date()
                source = "fallbackNow"
            }
            mode = try container.decodeIfPresent(String.self, forKey: .mode) ?? "countdown"
            postMessage = try container.decodeIfPresent(String.self, forKey: .postMessage) ?? ""
            if let value = try container.decodeIfPresent(Date.self, forKey: .postEndsAtDate) {
                postEndsAtDate = value
            } else if let epochMs = try container.decodeIfPresent(Int64.self, forKey: .postEndsAtEpochMs) {
                postEndsAtDate = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000.0)
            } else {
                postEndsAtDate = endDate
            }
            phase = try container.decodeIfPresent(String.self, forKey: .phase) ?? "countdown"

            let remainingSeconds = max(0, Int(endDate.timeIntervalSinceNow))
            debugLog(
                "[NurAiWidgetsLiveActivity] decode source=\(source) remainingSeconds=\(remainingSeconds)"
            )
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(title, forKey: .title)
            try container.encode(subtitle, forKey: .subtitle)
            try container.encode(endDate, forKey: .endDate)
            try container.encode(mode, forKey: .mode)
            try container.encode(postMessage, forKey: .postMessage)
            try container.encode(postEndsAtDate, forKey: .postEndsAtDate)
            try container.encode(phase, forKey: .phase)
        }
    }

    var name: String
}

@available(iOSApplicationExtension 16.1, *)
struct NurAiWidgetsLiveActivity: Widget {
    private enum DisplayPhase {
        case countdown
        case completed
        case ended
    }

    private let lockScreenBackgroundTint = Color(red: 0.10, green: 0.14, blue: 0.21).opacity(0.85)
    private let lockScreenActionTint = Color.primary
    private let islandText = Color.white
    private let islandKeylineTint = Color.primary.opacity(0.35)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IftarAttributes.self) { context in
            let phase = displayPhase(for: context.state)
            HStack(alignment: .center, spacing: 12) {
                LiveActivityAvatarView(size: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(lockTitle(context.state))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    statusContent(for: context.state, phase: phase, large: true, darkMode: false)
                    Text(lockSubtitle(context.state))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .tint(.primary)
            .activityBackgroundTint(lockScreenBackgroundTint)
            .activitySystemActionForegroundColor(lockScreenActionTint)
            .widgetURL(URL(string: "duaya://ramadan"))
        } dynamicIsland: { context in
            let phase = displayPhase(for: context.state)
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityAvatarView(size: 30)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    statusContent(for: context.state, phase: phase, large: false, darkMode: true)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(lockTitle(context.state))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(islandText)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Text(lockSubtitle(context.state))
                            .foregroundStyle(.secondary)
                        if phase == .countdown {
                            statusContent(for: context.state, phase: phase, large: false, darkMode: true)
                        }
                    }
                }
            } compactLeading: {
                LiveActivityAvatarView(size: 22)
            } compactTrailing: {
                statusContent(for: context.state, phase: phase, large: false, darkMode: true)
            } minimal: {
                LiveActivityAvatarView(size: 20)
            }
            .widgetURL(URL(string: "duaya://ramadan"))
            .keylineTint(islandKeylineTint)
        }
    }

    private func lockTitle(_ state: IftarAttributes.ContentState) -> String {
        switch displayPhase(for: state) {
        case .completed:
            return state.title.isEmpty ? "Iftar" : state.title
        case .countdown, .ended:
            return state.title.isEmpty ? "Iftara kalan" : state.title
        }
    }

    private func lockSubtitle(_ state: IftarAttributes.ContentState) -> String {
        switch displayPhase(for: state) {
        case .completed:
            return completionMessage(for: state)
        case .countdown, .ended:
            return state.subtitle.isEmpty ? "Ramazan bereketi" : state.subtitle
        }
    }

    @ViewBuilder
    private func statusContent(
        for state: IftarAttributes.ContentState,
        phase: DisplayPhase,
        large: Bool,
        darkMode: Bool
    ) -> some View {
        switch phase {
        case .countdown:
            countdownLabel(targetDate: state.endDate, large: large, darkMode: darkMode)
        case .completed:
            completionLabel(message: completionMessage(for: state), large: large, darkMode: darkMode)
        case .ended:
            EmptyView()
        }
    }

    @ViewBuilder
    private func countdownLabel(targetDate: Date, large: Bool, darkMode: Bool) -> some View {
        Text(timerInterval: Date()...targetDate, countsDown: true)
            .font(
                large
                    ? .system(size: 24, weight: .bold, design: .rounded)
                    : .system(size: 13, weight: .semibold, design: .rounded)
            )
            .monospacedDigit()
            .foregroundStyle(darkMode ? islandText : .primary)
    }

    @ViewBuilder
    private func completionLabel(message: String, large: Bool, darkMode: Bool) -> some View {
        Text(message)
            .font(
                large
                    ? .system(size: 18, weight: .bold, design: .rounded)
                    : .system(size: 12, weight: .semibold, design: .rounded)
            )
            .foregroundStyle(darkMode ? islandText : .primary)
            .lineLimit(large ? 2 : 1)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func displayPhase(for state: IftarAttributes.ContentState, now: Date = Date()) -> DisplayPhase {
        let targetDate = state.endDate
        let graceEndDate = targetDate.addingTimeInterval(600)
        if now >= graceEndDate {
            return .ended
        }
        if now >= targetDate && now < graceEndDate {
            return .completed
        }
        return .countdown
    }

    private func completionMessage(for state: IftarAttributes.ContentState) -> String {
        let trimmed = state.postMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        if Locale.current.languageCode?.lowercased() == "tr" {
            return "Allah kabul etsin"
        }
        return "May Allah accept it"
    }
}
