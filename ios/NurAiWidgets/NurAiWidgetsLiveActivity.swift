import ActivityKit
import Foundation
import SwiftUI
import UIKit
import WidgetKit

private final class NurAiWidgetsBundleMarker {}

private var widgetBundle: Bundle {
    Bundle(for: NurAiWidgetsBundleMarker.self)
}

private func liveAvatarImage() -> Image {
    Image("LiveActivityAvatar", bundle: widgetBundle)
        .renderingMode(.original)
}

private struct LiveActivityAvatarView: View {
    let size: CGFloat

    var body: some View {
        Group {
            #if DEBUG
                if UIImage(named: "LiveActivityAvatar", in: widgetBundle, compatibleWith: nil) == nil {
                    Image(systemName: "person.crop.circle.fill")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.12)
                        .foregroundStyle(.white)
                        .background(Color.red.opacity(0.75))
                        .onAppear {
                            debugLog("[NurAiWidgetsLiveActivity] missing asset name=LiveActivityAvatar bundle=\(widgetBundle.bundlePath)")
                        }
                } else {
                    liveAvatarImage()
                        .resizable()
                        .scaledToFill()
                }
            #else
                liveAvatarImage()
                    .resizable()
                    .scaledToFill()
            #endif
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
        var iftarDate: Date
        var endDate: Date
        var mode: String
        var postMessage: String
        var phase: String

        enum CodingKeys: String, CodingKey {
            case title
            case subtitle
            case iftarDate
            case iftarEpochMs
            case endDate
            case endEpochMs
            case mode
            case postMessage
            case postEndsAtDate
            case postEndsAtEpochMs
            case phase
        }

        init(
            title: String,
            subtitle: String,
            iftarDate: Date,
            endDate: Date,
            mode: String,
            postMessage: String,
            phase: String
        ) {
            self.title = title
            self.subtitle = subtitle
            self.iftarDate = iftarDate
            self.endDate = endDate
            self.mode = mode
            self.postMessage = postMessage
            self.phase = phase
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? "İftara"
            subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? "Kalan süre"
            let decodedIftarDate: Date?
            if let value = try container.decodeIfPresent(Date.self, forKey: .iftarDate) {
                decodedIftarDate = value
            } else if let epochMs = try container.decodeIfPresent(Int64.self, forKey: .iftarEpochMs) {
                decodedIftarDate = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000.0)
            } else {
                decodedIftarDate = nil
            }
            let decodedLegacyDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
            let source: String
            if let value = decodedIftarDate {
                iftarDate = value
                source = "iftarDate"
            } else if let legacyValue = decodedLegacyDate {
                iftarDate = legacyValue
                source = "legacyEndDate"
            } else {
                iftarDate = Date()
                source = "fallbackNow"
            }
            if let value = try container.decodeIfPresent(Date.self, forKey: .endDate) {
                endDate = value
            } else if let epochMs = try container.decodeIfPresent(Int64.self, forKey: .endEpochMs) {
                endDate = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000.0)
            } else if let value = try container.decodeIfPresent(Date.self, forKey: .postEndsAtDate) {
                endDate = value
            } else if let epochMs = try container.decodeIfPresent(Int64.self, forKey: .postEndsAtEpochMs) {
                endDate = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000.0)
            } else {
                endDate = iftarDate.addingTimeInterval(600)
            }
            mode = try container.decodeIfPresent(String.self, forKey: .mode) ?? "countdown"
            postMessage = try container.decodeIfPresent(String.self, forKey: .postMessage) ?? ""
            phase = try container.decodeIfPresent(String.self, forKey: .phase) ?? "countdown"

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
            try container.encode(endDate, forKey: .endDate)
            try container.encode(mode, forKey: .mode)
            try container.encode(postMessage, forKey: .postMessage)
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
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    LiveActivityAvatarView(size: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(primaryLine(for: context.state, phase: phase))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(phase == .completed ? 2 : 1)
                        Text(secondaryLine(for: context.state, phase: phase))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    lockScreenTrailing(for: context.state, phase: phase)
                }
                if phase == .countdown {
                    progressBar(for: context.state, darkMode: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .tint(.primary)
            .activityBackgroundTint(lockScreenBackgroundTint)
            .activitySystemActionForegroundColor(lockScreenActionTint)
            .widgetURL(URL(string: "duaya://ramadan"))
        } dynamicIsland: { context in
            let phase = displayPhase(for: context.state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityAvatarView(size: 28)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(for: context.state, phase: phase)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(primaryLine(for: context.state, phase: phase))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(islandText)
                            .lineLimit(phase == .completed ? 2 : 1)
                        Text(secondaryLine(for: context.state, phase: phase))
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            LiveActivityAvatarView(size: 20)
                            Text(localizedTitle())
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            if phase == .countdown {
                                Text(context.state.iftarDate, style: .time)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if phase == .countdown {
                            progressBar(for: context.state, darkMode: true)
                        } else if phase == .completed {
                            Text(completionMessage(for: context.state))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(islandText)
                                .lineLimit(2)
                        }
                    }
                }
            } compactLeading: {
                LiveActivityAvatarView(size: 22)
            } compactTrailing: {
                compactTrailing(for: context.state, phase: phase)
            } minimal: {
                LiveActivityAvatarView(size: 20)
            }
            .widgetURL(URL(string: "duaya://ramadan"))
            .keylineTint(islandKeylineTint)
        }
    }

    private var isTurkish: Bool {
        Locale.current.languageCode?.lowercased() == "tr"
    }

    private func localizedTitle() -> String {
        isTurkish ? "İftara" : "To iftar"
    }

    private func localizedSubtitle() -> String {
        isTurkish ? "Kalan süre" : "Time remaining"
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
            countdownLabel(targetDate: state.iftarDate, large: large, darkMode: darkMode)
        case .completed:
            completionLabel(message: completionMessage(for: state), large: large, darkMode: darkMode)
        case .ended:
            EmptyView()
        }
    }

    @ViewBuilder
    private func countdownLabel(targetDate: Date, large: Bool, darkMode: Bool) -> some View {
        Text(targetDate, style: .timer)
            .font(timerFont(large: large))
            .monospacedDigit()
            .foregroundStyle(darkMode ? islandText : .primary)
    }

    @ViewBuilder
    private func completionLabel(
        message: String,
        large: Bool,
        darkMode: Bool
    ) -> some View {
        if large {
            Text(message)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(darkMode ? islandText : .primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        } else {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(darkMode ? islandText : .primary)
        }
    }

    @ViewBuilder
    private func lockScreenTrailing(for state: IftarAttributes.ContentState, phase: DisplayPhase) -> some View {
        switch phase {
        case .countdown:
            countdownLabel(targetDate: state.iftarDate, large: true, darkMode: false)
        case .completed:
            Text("0:00")
                .font(timerFont(large: false))
                .monospacedDigit()
                .foregroundStyle(.primary)
        case .ended:
            EmptyView()
        }
    }

    @ViewBuilder
    private func expandedTrailing(for state: IftarAttributes.ContentState, phase: DisplayPhase) -> some View {
        switch phase {
        case .countdown:
            countdownLabel(targetDate: state.iftarDate, large: false, darkMode: true)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(islandText)
        case .ended:
            EmptyView()
        }
    }

    @ViewBuilder
    private func compactTrailing(for state: IftarAttributes.ContentState, phase: DisplayPhase) -> some View {
        switch phase {
        case .countdown:
            Text(compactCountdownText(to: state.iftarDate))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(islandText)
                .lineLimit(1)
        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(islandText)
        case .ended:
            EmptyView()
        }
    }

    @ViewBuilder
    private func progressBar(for state: IftarAttributes.ContentState, darkMode: Bool) -> some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width)
            let fillWidth = width * countdownProgress(for: state)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill((darkMode ? Color.white : Color.primary).opacity(darkMode ? 0.14 : 0.08))
                Capsule()
                    .fill(progressFill(darkMode: darkMode))
                    .frame(width: fillWidth)
            }
        }
        .frame(height: 5)
    }

    private func progressFill(darkMode: Bool) -> Color {
        darkMode ? Color.white.opacity(0.7) : Color.primary.opacity(0.5)
    }

    private func countdownProgress(for state: IftarAttributes.ContentState, now: Date = Date()) -> CGFloat {
        let remaining = max(0, state.iftarDate.timeIntervalSince(now))
        let totalWindow: TimeInterval = 3600
        let progress = 1.0 - min(1.0, remaining / totalWindow)
        return CGFloat(max(0, min(1, progress)))
    }

    private func compactCountdownText(to targetDate: Date, now: Date = Date()) -> String {
        let remaining = max(0, Int(targetDate.timeIntervalSince(now)))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60

        if hours > 0 {
            return "\(hours)h\(String(format: "%02d", minutes))"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "0m"
    }

    private func timerFont(large: Bool) -> Font {
        large
            ? .system(size: 24, weight: .bold, design: .rounded)
            : .system(size: 13, weight: .semibold, design: .rounded)
    }

    private func displayPhase(for state: IftarAttributes.ContentState, now: Date = Date()) -> DisplayPhase {
        if now >= state.endDate {
            return .ended
        }
        if now >= state.iftarDate && now < state.endDate {
            return .completed
        }
        return .countdown
    }

    private func completionMessage(for state: IftarAttributes.ContentState) -> String {
        let trimmed = state.postMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        if isTurkish {
            return "Allah kabul etsin"
        }
        return "May Allah accept it"
    }

    private func postIftarSubtitle() -> String {
        isTurkish ? "İftar vakti" : "Iftar time"
    }

    private func primaryLine(for state: IftarAttributes.ContentState, phase: DisplayPhase) -> String {
        switch phase {
        case .completed:
            return completionMessage(for: state)
        case .countdown, .ended:
            return localizedTitle()
        }
    }

    private func secondaryLine(for state: IftarAttributes.ContentState, phase: DisplayPhase) -> String {
        switch phase {
        case .completed:
            return postIftarSubtitle()
        case .countdown, .ended:
            return localizedSubtitle()
        }
    }
}
