import ActivityKit
import WidgetKit
import SwiftUI

@available(iOSApplicationExtension 16.1, *)
struct NurAiWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var targetEpochMs: Int64
        var phase: String
    }

    var name: String
}

@available(iOSApplicationExtension 16.1, *)
struct NurAiWidgetsLiveActivity: Widget {
    private func targetDate(from epochMs: Int64) -> Date {
        let seconds: TimeInterval = TimeInterval(epochMs) / 1000.0
        return Date(timeIntervalSince1970: seconds)
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NurAiWidgetsAttributes.self) { context in
            let liveTargetDate: Date = targetDate(from: context.state.targetEpochMs)
            VStack(alignment: .leading, spacing: 6) {
                if context.state.phase == "done" {
                    Text("Allah kabul etsin")
                        .font(.system(size: 20, weight: .bold))
                    Text("İftar vakti.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.secondary)
                } else {
                    Text("İftara")
                        .font(.system(size: 16, weight: .semibold))
                    Text(liveTargetDate, style: .timer)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(context.state.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.vertical, 4)
            .activityBackgroundTint(Color.black.opacity(0.12))
            .activitySystemActionForegroundColor(Color.primary)
        } dynamicIsland: { context in
            let islandTargetDate: Date = targetDate(from: context.state.targetEpochMs)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("İftara")
                        .font(.system(size: 13, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.phase == "done" {
                        Text("Vakit")
                            .font(.system(size: 13, weight: .semibold))
                    } else {
                        Text(islandTargetDate, style: .timer)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.phase == "done" {
                        Text("Allah kabul etsin")
                            .font(.system(size: 16, weight: .bold))
                    } else {
                        Text(context.state.subtitle)
                            .font(.system(size: 13, weight: .regular))
                    }
                }
            } compactLeading: {
                Text("İ")
            } compactTrailing: {
                if context.state.phase == "done" {
                    Text("✓")
                } else {
                    Text(islandTargetDate, style: .timer)
                        .monospacedDigit()
                }
            } minimal: {
                if context.state.phase == "done" {
                    Text("✓")
                } else {
                    Text("İ")
                }
            }
            .widgetURL(URL(string: "nurai://ramadan"))
            .keylineTint(Color.orange)
        }
    }
}
