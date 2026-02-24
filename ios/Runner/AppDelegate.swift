import ActivityKit
import Flutter
import UIKit
import UserNotifications
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
  private let payloadKey = "next_prayer_widget_payload"
  private let dailyContentPayloadKey = "daily_content_payload"
  private let nextPrayerWidgetKind = "NextPrayerWidget"
  private let dailyContentWidgetKind = "NurAiWidgets"
  
  private func debugLog(_ message: String) {
    #if DEBUG
      print(message)
    #endif
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
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

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
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
      WidgetCenter.shared.reloadAllTimelines()
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
    let iftarDate = Date(timeIntervalSince1970: TimeInterval(targetEpochMs) / 1000.0)
    let remainingSeconds = max(0, Int(iftarDate.timeIntervalSinceNow))
    debugLog(
      "[IftarLiveActivity] parse state phase=\(phase) remainingSeconds=\(remainingSeconds)"
    )

    return IftarAttributes.ContentState(
      title: title,
      subtitle: subtitle,
      iftarDate: iftarDate,
      phase: phase
    )
  }

  private func startIftarLiveActivity(with args: [String: Any], result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }
    let state = parseIftarState(args)
    logIftarState("start", state: state)
    Task {
      if let existing = firstIftarActivity() {
        logIftarState("start->updateExisting", state: state)
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
        logIftarState("start->requested", state: state)
        result(nil)
      } catch {
        self.debugLog("[IftarLiveActivity] activity_start_failed error=\(error.localizedDescription)")
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
    logIftarState("update", state: state)
    Task {
      if let existing = firstIftarActivity() {
        logIftarState("update->existing", state: state)
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

  @available(iOS 16.1, *)
  private func logIftarState(_ event: String, state: IftarAttributes.ContentState) {
    let remainingSeconds = max(0, Int(state.iftarDate.timeIntervalSinceNow))
    debugLog(
      "[IftarLiveActivity] \(event) phase=\(state.phase) remainingSeconds=\(remainingSeconds)"
    )
  }
}

@available(iOS 16.1, *)
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
      title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Iftara"
      subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? "Kalan sure"
      phase = try container.decodeIfPresent(String.self, forKey: .phase) ?? "countdown"
      if let value = try container.decodeIfPresent(Date.self, forKey: .iftarDate) {
        iftarDate = value
      } else if let legacyValue = try container.decodeIfPresent(Date.self, forKey: .endDate) {
        iftarDate = legacyValue
      } else {
        iftarDate = Date()
      }
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
