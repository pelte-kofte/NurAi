import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 16.1, *)
struct IftarAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var endDate: Date
        var phase: String
    }

    var name: String
}

@available(iOSApplicationExtension 16.1, *)
struct NurAiWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IftarAttributes.self) { context in
            VStack(alignment: .leading, spacing: 6) {
                if context.state.phase == "done" {
                    Text("Allah kabul etsin")
                        .font(.system(size: 20, weight: .bold))
                    Text("Iftar vakti.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.secondary)
                } else {
                    Text(context.state.title.isEmpty ? "Iftara" : context.state.title)
                        .font(.system(size: 16, weight: .semibold))
                    countdownLabel(endDate: context.state.endDate, large: true)
                    Text(context.state.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.vertical, 4)
            .activityBackgroundTint(Color.black.opacity(0.12))
            .activitySystemActionForegroundColor(Color.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.title.isEmpty ? "Iftara" : context.state.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.phase == "done" {
                        Text("Vakit")
                            .font(.system(size: 13, weight: .semibold))
                    } else {
                        countdownLabel(endDate: context.state.endDate, large: false)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.phase == "done" {
                        Text("Allah kabul etsin")
                            .font(.system(size: 16, weight: .bold))
                    } else {
                        Text(context.state.subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Text("I")
            } compactTrailing: {
                if context.state.phase == "done" {
                    Text("OK")
                } else {
                    countdownLabel(endDate: context.state.endDate, large: false)
                }
            } minimal: {
                if context.state.phase == "done" {
                    Text("OK")
                } else {
                    Image(systemName: "moon.stars.fill")
                }
            }
            .widgetURL(URL(string: "nurai://ramadan"))
            .keylineTint(Color.orange)
        }
    }

    @ViewBuilder
    private func countdownLabel(endDate: Date, large: Bool) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let text = Self.formatRemaining(now: timeline.date, endDate: endDate)
            Text(text)
                .font(
                    large
                        ? .system(size: 24, weight: .bold, design: .rounded)
                        : .system(size: 13, weight: .semibold, design: .rounded)
                )
                .monospacedDigit()
        }
    }

    private static func formatRemaining(now: Date, endDate: Date) -> String {
        let remaining = max(0, Int(endDate.timeIntervalSince(now)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
