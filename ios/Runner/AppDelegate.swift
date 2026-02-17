import Flutter
import UIKit
import WidgetKit
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "nurai.widgets"
  private let methodSetPayload = "setNextPrayerPayload"
  private let methodRefreshWidgets = "refreshWidgets"
  private let methodIsIftarLiveActivitySupported = "isIftarLiveActivitySupported"
  private let methodStartIftarLiveActivity = "startIftarLiveActivity"
  private let methodUpdateIftarLiveActivity = "updateIftarLiveActivity"
  private let methodEndIftarLiveActivity = "endIftarLiveActivity"
  private let defaultAppGroupId = "group.com.nurai.app"
  private let payloadKey = "next_prayer_payload"

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
          result(FlutterError(code: "unavailable", message: "AppDelegate unavailable", details: nil))
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
          self.writePayload(payload)
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

  private func writePayload(_ payload: String) {
    if let sharedDefaults = resolveSharedDefaults() {
      sharedDefaults.set(payload, forKey: payloadKey)
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
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  @available(iOS 16.1, *)
  private func firstIftarActivity() -> Activity<NurAiWidgetsAttributes>? {
    Activity<NurAiWidgetsAttributes>.activities.first
  }

  @available(iOS 16.1, *)
  private func parseIftarState(_ args: [String: Any]) -> NurAiWidgetsAttributes.ContentState {
    let title = (args["title"] as? String) ?? "İftara"
    let subtitle = (args["subtitle"] as? String) ?? "Kalan süre"
    let phase = (args["phase"] as? String) ?? "countdown"
    let targetEpochMs = (args["targetEpochMs"] as? NSNumber)?.int64Value
      ?? Int64(Date().timeIntervalSince1970 * 1000)
    return NurAiWidgetsAttributes.ContentState(
      title: title,
      subtitle: subtitle,
      targetEpochMs: targetEpochMs,
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
      let attributes = NurAiWidgetsAttributes(name: "Iftar")
      do {
        _ = try Activity<NurAiWidgetsAttributes>.request(
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
      for activity in Activity<NurAiWidgetsAttributes>.activities {
        await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
      }
      result(nil)
    }
  }
}

@available(iOS 16.1, *)
struct NurAiWidgetsAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var title: String
    var subtitle: String
    var targetEpochMs: Int64
    var phase: String
  }

  var name: String
}
