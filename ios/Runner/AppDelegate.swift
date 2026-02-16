import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "nurai.widgets"
  private let methodSetPayload = "setNextPrayerPayload"
  private let methodRefreshWidgets = "refreshWidgets"
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
}
