import ActivityKit
import WidgetKit
import SwiftUI

struct NurAiWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var targetEpochMs: Int64
        var phase: String
    }

    var name: String
}

struct NurAiWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NurAiWidgetsAttributes.self) { context in
            VStack(alignment: .leading, spacing: 6) {
                if context.state.phase == "done" {
                    Text("Allah kabul etsin")
                        .font(.system(size: 20, weight: .bold))
                    Text("İftar vakti.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                } else {
                    Text("İftara")
                        .font(.system(size: 16, weight: .semibold))
                    Text(Date(timeIntervalSince1970: Double(context.state.targetEpochMs) / 1000), style: .timer)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(context.state.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .activityBackgroundTint(Color.black.opacity(0.12))
            .activitySystemActionForegroundColor(Color.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("İftara")
                        .font(.system(size: 13, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.phase == "done" {
                        Text("Vakit")
                            .font(.system(size: 13, weight: .semibold))
                    } else {
                        Text(Date(timeIntervalSince1970: Double(context.state.targetEpochMs) / 1000), style: .timer)
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
                    Text(Date(timeIntervalSince1970: Double(context.state.targetEpochMs) / 1000), style: .timer)
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
