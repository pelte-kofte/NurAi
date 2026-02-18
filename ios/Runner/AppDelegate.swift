import ActivityKit
import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "nurai.widgets"
  private let methodSetPayload = "setNextPrayerPayload"
  private let methodSetDailyContentPayload = "setDailyContentPayload"
  private let methodRefreshWidgets = "refreshWidgets"
  private let methodIsIftarLiveActivitySupported = "isIftarLiveActivitySupported"
  private let methodStartIftarLiveActivity = "startIftarLiveActivity"
  private let methodUpdateIftarLiveActivity = "updateIftarLiveActivity"
  private let methodEndIftarLiveActivity = "endIftarLiveActivity"
  private let defaultAppGroupId = "group.com.nilico.duaya"
  private let payloadKey = "next_prayer_payload"
  private let dailyContentPayloadKey = "daily_content_payload"
  private let nextPrayerWidgetKind = "NextPrayerWidget"
  private let dailyContentWidgetKind = "NurAiWidgets"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(
            FlutterError(
              code: "unavailable",
              message: "AppDelegate unavailable",
              details: nil
            )
          )
          return
        }
        switch call.method {
        case self.methodSetPayload:
          guard
            let args = call.arguments as? [String: Any],
            let payload = args["payload"] as? String
          else {
            result(FlutterError(code: "invalid_args", message: "Missing payload", details: nil))
            return
          }
          self.writePayload(payload, key: self.payloadKey)
          self.refreshWidgets()
          result(nil)

        case self.methodSetDailyContentPayload:
          guard
            let args = call.arguments as? [String: Any],
            let payload = args["payload"] as? String
          else {
            result(FlutterError(code: "invalid_args", message: "Missing payload", details: nil))
            return
          }
          self.writePayload(payload, key: self.dailyContentPayloadKey)
          self.refreshWidgets()
          result(nil)

        case self.methodRefreshWidgets:
          self.refreshWidgets()
          result(nil)

        case self.methodIsIftarLiveActivitySupported:
          if #available(iOS 16.1, *) {
            result(ActivityAuthorizationInfo().areActivitiesEnabled)
          } else {
            result(false)
          }

        case self.methodStartIftarLiveActivity:
          guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "invalid_args", message: "Missing payload", details: nil))
            return
          }
          self.startIftarLiveActivity(with: args, result: result)

        case self.methodUpdateIftarLiveActivity:
          guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "invalid_args", message: "Missing payload", details: nil))
            return
          }
          self.updateIftarLiveActivity(with: args, result: result)

        case self.methodEndIftarLiveActivity:
          self.endIftarLiveActivity(result: result)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func writePayload(_ payload: String, key: String) {
    if let sharedDefaults = resolveSharedDefaults() {
      sharedDefaults.set(payload, forKey: key)
      sharedDefaults.synchronize()
    }
  }

  private func resolveSharedDefaults() -> UserDefaults? {
    var candidates = [defaultAppGroupId]
    if let bundleId = Bundle.main.bundleIdentifier {
      candidates.append("group.\(bundleId)")
    }
    for suite in candidates {
      if let defaults = UserDefaults(suiteName: suite) {
        return defaults
      }
    }
    return nil
  }

  private func refreshWidgets() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: nextPrayerWidgetKind)
      WidgetCenter.shared.reloadTimelines(ofKind: dailyContentWidgetKind)
    }
  }

  @available(iOS 16.1, *)
  private func firstIftarActivity() -> Activity<IftarAttributes>? {
    Activity<IftarAttributes>.activities.first
  }

  @available(iOS 16.1, *)
  private func parseIftarState(_ args: [String: Any]) -> IftarAttributes.ContentState {
    let title = (args["title"] as? String) ?? "Iftara"
    let subtitle = (args["subtitle"] as? String) ?? "Kalan sure"
    let phase = (args["phase"] as? String) ?? "countdown"
    let targetEpochMs =
      (args["endEpochMs"] as? NSNumber)?.int64Value
      ?? (args["targetEpochMs"] as? NSNumber)?.int64Value
      ?? Int64(Date().addingTimeInterval(1).timeIntervalSince1970 * 1000)
    let endDate = Date(timeIntervalSince1970: TimeInterval(targetEpochMs) / 1000.0)

    return IftarAttributes.ContentState(
      title: title,
      subtitle: subtitle,
      endDate: endDate,
      phase: phase
    )
  }

  private func startIftarLiveActivity(with args: [String: Any], result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }
    let state = parseIftarState(args)
    Task {
      if let existing = firstIftarActivity() {
        await existing.update(using: state)
        result(nil)
        return
      }
      let attributes = IftarAttributes(name: "Iftar")
      do {
        _ = try Activity<IftarAttributes>.request(
          attributes: attributes,
          contentState: state,
          pushType: nil
        )
        result(nil)
      } catch {
        result(
          FlutterError(
            code: "activity_start_failed",
            message: "Failed to start iftar live activity",
            details: error.localizedDescription
          )
        )
      }
    }
  }

  private func updateIftarLiveActivity(with args: [String: Any], result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }
    let state = parseIftarState(args)
    Task {
      if let existing = firstIftarActivity() {
        await existing.update(using: state)
      }
      result(nil)
    }
  }

  private func endIftarLiveActivity(result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }
    Task {
      for activity in Activity<IftarAttributes>.activities {
        await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
      }
      result(nil)
    }
  }
}

@available(iOS 16.1, *)
struct IftarAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var title: String
    var subtitle: String
    var endDate: Date
    var phase: String
  }

  var name: String
}
