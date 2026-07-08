import ActivityKit
import BackgroundTasks
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
  private let methodEndAllIftarActivities = "endAllIftarActivities"
  private let methodScheduleIftarBackgroundTasks = "scheduleIftarLiveActivityBackgroundTasks"
  private let methodCancelIftarBackgroundTasks = "cancelIftarLiveActivityBackgroundTasks"
  private let defaultAppGroupId = "group.com.nilico.duaya"
  private let payloadKey = "next_prayer_widget_payload"
  private let dailyContentPayloadKey = "daily_content_payload"
  private let iftarLiveActivityPayloadKey = "iftar_live_activity_payload"
  private let nextPrayerWidgetKind = "NextPrayerWidget"
  private let dailyContentWidgetKind = "NurAiWidgets"
  private let iftarStartTaskIdentifier = "com.nilico.duaya.iftarLiveActivityStart"
  private let iftarEndTaskIdentifier = "com.nilico.duaya.iftarLiveActivityEnd"
  private let iftarRefreshInterval: TimeInterval = 300
  
  private func debugLog(_ message: String) {
    #if DEBUG
      print(message)
    #endif
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    debugLog("[AppDelegate] didFinishLaunching start")
    registerBackgroundTasks()
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    guard let registrar = registrar(forPlugin: channelName) else {
      debugLog("[AppDelegate] registrar unavailable for \(channelName)")
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
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

      case self.methodEndAllIftarActivities:
        self.endAllIftarActivities(result: result)

      case self.methodScheduleIftarBackgroundTasks:
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "invalid_args", message: "Missing payload", details: nil))
          return
        }
        self.scheduleIftarBackgroundTasks(with: args, result: result)

      case self.methodCancelIftarBackgroundTasks:
        self.cancelIftarBackgroundTasks(result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
    housekeepingIftarActivitiesIfNeeded()
    debugLog("[AppDelegate] didFinishLaunching ready")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    housekeepingIftarActivitiesIfNeeded()
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    debugLog("[Notifications] willPresent foreground notification with sound")
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  private func writePayload(_ payload: String, key: String) {
    debugLog("[AppDelegate] write_payload key=\(key) length=\(payload.count)")
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
      debugLog("[AppDelegate] refresh_widgets trigger=manual_reload")
      WidgetCenter.shared.reloadAllTimelines()
      WidgetCenter.shared.reloadTimelines(ofKind: nextPrayerWidgetKind)
      WidgetCenter.shared.reloadTimelines(ofKind: dailyContentWidgetKind)
    }
  }

  private func registerBackgroundTasks() {
    guard #available(iOS 13.0, *) else {
      return
    }

    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: iftarStartTaskIdentifier,
      using: nil
    ) { [weak self] task in
      guard let self = self, let refreshTask = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      self.handleIftarStartTask(refreshTask)
    }

    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: iftarEndTaskIdentifier,
      using: nil
    ) { [weak self] task in
      guard let self = self, let refreshTask = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      self.handleIftarEndTask(refreshTask)
    }
  }

  @available(iOS 16.1, *)
  private func firstIftarActivity() -> Activity<IftarAttributes>? {
    Activity<IftarAttributes>.activities.first
  }

  @available(iOS 16.1, *)
  private func parseIftarState(_ args: [String: Any]) -> IftarAttributes.ContentState {
    let title = (args["title"] as? String) ?? "İftara"
    let subtitle = (args["subtitle"] as? String) ?? "Kalan süre"
    let lang = (args["lang"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let mode = (args["mode"] as? String) ?? "countdown"
    let postMessage = (args["postMessage"] as? String) ?? ""
    let phase = (args["phase"] as? String) ?? "countdown"
    let iftarEpochMs =
      (args["iftarEpochMs"] as? NSNumber)?.int64Value
      ?? (args["targetEpochMs"] as? NSNumber)?.int64Value
      ?? Int64(Date().addingTimeInterval(1).timeIntervalSince1970 * 1000)
    let endEpochMs =
      (args["endEpochMs"] as? NSNumber)?.int64Value
      ?? (args["postEndsAtEpochMs"] as? NSNumber)?.int64Value
      ?? (iftarEpochMs + 600_000)
    let iftarDate = Date(timeIntervalSince1970: TimeInterval(iftarEpochMs) / 1000.0)
    let endDate = Date(timeIntervalSince1970: TimeInterval(endEpochMs) / 1000.0)
    let remainingSeconds = max(0, Int(iftarDate.timeIntervalSinceNow))
    debugLog(
      "[IftarLiveActivity] parse state mode=\(mode) phase=\(phase) remainingSeconds=\(remainingSeconds) iftarEpochMs=\(iftarEpochMs) endEpochMs=\(endEpochMs) iftarIsFuture=\(iftarDate > Date())"
    )

    return IftarAttributes.ContentState(
      title: title,
      subtitle: subtitle,
      iftarDate: iftarDate,
      endDate: endDate,
      lang: lang,
      mode: mode,
      postMessage: postMessage,
      phase: phase
    )
  }

  private func storeIftarPayload(_ args: [String: Any]) {
    guard let sharedDefaults = resolveSharedDefaults() else {
      return
    }
    sharedDefaults.set(args, forKey: iftarLiveActivityPayloadKey)
    sharedDefaults.synchronize()
  }

  private func clearStoredIftarPayload() {
    guard let sharedDefaults = resolveSharedDefaults() else {
      return
    }
    sharedDefaults.removeObject(forKey: iftarLiveActivityPayloadKey)
    sharedDefaults.synchronize()
  }

  private func storedIftarPayload() -> [String: Any]? {
    guard let sharedDefaults = resolveSharedDefaults() else {
      return nil
    }
    return sharedDefaults.dictionary(forKey: iftarLiveActivityPayloadKey)
  }

  private func housekeepingIftarActivitiesIfNeeded() {
    guard #available(iOS 16.1, *) else {
      return
    }
    guard let payload = storedIftarPayload() else {
      return
    }

    let state = parseIftarState(payload)
    if Date() < state.endDate {
      return
    }

    debugLog("[IftarLiveActivity] housekeeping_end nowPastEnd=true")
    Task { [weak self] in
      guard let self = self else { return }
      await self.endAllIftarActivitiesNow()
      self.cancelIftarBackgroundTasks()
    }
  }

  private func scheduleIftarBackgroundTasks(with args: [String: Any], result: @escaping FlutterResult) {
    guard #available(iOS 13.0, *) else {
      result(nil)
      return
    }
    guard let payload = args["payload"] as? [String: Any] else {
      result(FlutterError(code: "invalid_args", message: "Missing payload", details: nil))
      return
    }
    let startEpochMs =
      (args["startEpochMs"] as? NSNumber)?.int64Value
      ?? (payload["iftarEpochMs"] as? NSNumber)?.int64Value
      ?? Int64(Date().addingTimeInterval(1).timeIntervalSince1970 * 1000)
    let endEpochMs =
      (args["endEpochMs"] as? NSNumber)?.int64Value
      ?? (payload["endEpochMs"] as? NSNumber)?.int64Value
      ?? (startEpochMs + 600_000)
    storeIftarPayload(payload)
    do {
      try submitIftarBackgroundTasks(
        payload: payload,
        startDate: Date(timeIntervalSince1970: TimeInterval(startEpochMs) / 1000.0),
        endDate: Date(timeIntervalSince1970: TimeInterval(endEpochMs) / 1000.0)
      )
      result(nil)
    } catch {
      debugLog("[IftarLiveActivity] bg_schedule_failed error=\(error.localizedDescription)")
      result(
        FlutterError(
          code: "bg_schedule_failed",
          message: "Failed to schedule iftar live activity background tasks",
          details: error.localizedDescription
        )
      )
    }
  }

  private func cancelIftarBackgroundTasks(result: @escaping FlutterResult) {
    cancelIftarBackgroundTasks()
    result(nil)
  }

  private func cancelIftarBackgroundTasks() {
    guard #available(iOS 13.0, *) else {
      clearStoredIftarPayload()
      return
    }
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: iftarStartTaskIdentifier)
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: iftarEndTaskIdentifier)
    clearStoredIftarPayload()
    debugLog("[IftarLiveActivity] bg_cancelled identifiers=\(iftarStartTaskIdentifier),\(iftarEndTaskIdentifier)")
  }

  @available(iOS 13.0, *)
  private func submitIftarBackgroundTasks(
    payload: [String: Any],
    startDate: Date,
    endDate: Date
  ) throws {
    storeIftarPayload(payload)
    try submitIftarStartTask(at: startDate)
    try submitIftarEndTask(at: endDate)
  }

  @available(iOS 13.0, *)
  private func submitIftarStartTask(at startDate: Date) throws {
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: iftarStartTaskIdentifier)
    let request = BGAppRefreshTaskRequest(identifier: iftarStartTaskIdentifier)
    request.earliestBeginDate = max(Date().addingTimeInterval(1), startDate)
    try BGTaskScheduler.shared.submit(request)
    debugLog("[IftarLiveActivity] bg_scheduled start earliest=\(String(describing: request.earliestBeginDate))")
  }

  @available(iOS 13.0, *)
  private func submitIftarEndTask(at endDate: Date) throws {
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: iftarEndTaskIdentifier)
    let request = BGAppRefreshTaskRequest(identifier: iftarEndTaskIdentifier)
    request.earliestBeginDate = max(Date().addingTimeInterval(1), endDate)
    try BGTaskScheduler.shared.submit(request)
    debugLog("[IftarLiveActivity] bg_scheduled end earliest=\(String(describing: request.earliestBeginDate))")
  }

  private func scheduleIftarEndTaskIfNeeded(from args: [String: Any]) {
    guard #available(iOS 13.0, *) else {
      return
    }
    let endEpochMs =
      (args["endEpochMs"] as? NSNumber)?.int64Value
      ?? (args["postEndsAtEpochMs"] as? NSNumber)?.int64Value
    guard let resolvedEndEpochMs = endEpochMs else {
      return
    }

    do {
      try submitIftarEndTask(
        at: Date(timeIntervalSince1970: TimeInterval(resolvedEndEpochMs) / 1000.0)
      )
    } catch {
      debugLog("[IftarLiveActivity] bg_end_schedule_failed error=\(error.localizedDescription)")
    }
  }

  @available(iOS 13.0, *)
  private func handleIftarStartTask(_ task: BGAppRefreshTask) {
    debugLog("[IftarLiveActivity] bg_executed start")
    task.expirationHandler = { [weak self] in
      self?.debugLog("[IftarLiveActivity] bg_expired start")
      task.setTaskCompleted(success: false)
    }

    guard let payload = storedIftarPayload() else {
      debugLog("[IftarLiveActivity] bg_start_missing_payload")
      task.setTaskCompleted(success: false)
      return
    }

    guard #available(iOS 16.1, *) else {
      task.setTaskCompleted(success: true)
      return
    }

    let state = parseIftarState(payload)
    Task { [weak self] in
      guard let self = self else {
        task.setTaskCompleted(success: false)
        return
      }

      let now = Date()
      if now >= state.endDate {
        await self.endAllIftarActivitiesNow()
        self.cancelIftarBackgroundTasks()
        task.setTaskCompleted(success: true)
        return
      }

      // Switch to completed phase once iftar time is reached
      var activePayload = payload
      if now >= state.iftarDate {
        activePayload["phase"] = "completed"
      }

      do {
        try await self.upsertIftarLiveActivity(with: activePayload)
        self.refreshWidgets()
        if now < state.iftarDate {
          let nextRefresh = min(state.iftarDate, now.addingTimeInterval(self.iftarRefreshInterval))
          do {
            try self.submitIftarBackgroundTasks(
              payload: payload,
              startDate: nextRefresh,
              endDate: state.endDate
            )
          } catch {
            self.debugLog("[IftarLiveActivity] bg_refresh_reschedule_failed error=\(error.localizedDescription)")
          }
        } else {
          do {
            try self.submitIftarEndTask(at: state.endDate)
          } catch {
            self.debugLog("[IftarLiveActivity] bg_end_reschedule_failed error=\(error.localizedDescription)")
          }
        }
        task.setTaskCompleted(success: true)
      } catch {
        self.debugLog("[IftarLiveActivity] bg_start_failed error=\(error.localizedDescription)")
        task.setTaskCompleted(success: false)
      }
    }
  }

  @available(iOS 13.0, *)
  private func handleIftarEndTask(_ task: BGAppRefreshTask) {
    debugLog("[IftarLiveActivity] bg_executed end")
    task.expirationHandler = { [weak self] in
      self?.debugLog("[IftarLiveActivity] bg_expired end")
      task.setTaskCompleted(success: false)
    }

    guard #available(iOS 16.1, *) else {
      cancelIftarBackgroundTasks()
      task.setTaskCompleted(success: true)
      return
    }

    Task { [weak self] in
      guard let self = self else {
        task.setTaskCompleted(success: false)
        return
      }
      await self.endAllIftarActivitiesNow()
      self.cancelIftarBackgroundTasks()
      task.setTaskCompleted(success: true)
    }
  }

  @available(iOS 16.1, *)
  private func upsertIftarLiveActivity(with args: [String: Any]) async throws {
    let areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    let state = parseIftarState(args)
    storeIftarPayload(args)
    debugLog(
      "[IftarLiveActivity] upsert areActivitiesEnabled=\(areActivitiesEnabled) iftarIsFuture=\(state.iftarDate > Date()) activityCount=\(Activity<IftarAttributes>.activities.count)"
    )
    logIftarState("upsert", state: state)
    if let existing = firstIftarActivity() {
      logIftarState("upsert->updateExisting", state: state)
      await existing.update(using: state)
      refreshWidgets()
      return
    }

    let attributes = IftarAttributes(name: "Iftar")
    _ = try Activity<IftarAttributes>.request(
      attributes: attributes,
      contentState: state,
      pushType: nil
    )
    logIftarState("upsert->requested", state: state)
    refreshWidgets()
  }

  private func startIftarLiveActivity(with args: [String: Any], result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }
    scheduleIftarEndTaskIfNeeded(from: args)
    let state = parseIftarState(args)
    debugLog(
      "[IftarLiveActivity] start requested areActivitiesEnabled=\(ActivityAuthorizationInfo().areActivitiesEnabled) iftarIsFuture=\(state.iftarDate > Date())"
    )
    Task {
      do {
        try await self.upsertIftarLiveActivity(with: args)
        result(nil)
      } catch {
        self.debugLog(
          "[IftarLiveActivity] activity_start_failed areActivitiesEnabled=\(ActivityAuthorizationInfo().areActivitiesEnabled) error=\(error.localizedDescription)"
        )
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
    storeIftarPayload(args)
    scheduleIftarEndTaskIfNeeded(from: args)
    logIftarState("update", state: state)
    Task {
      if let existing = firstIftarActivity() {
        logIftarState("update->existing", state: state)
        await existing.update(using: state)
      }
      self.refreshWidgets()
      result(nil)
    }
  }

  private func endIftarLiveActivity(result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      cancelIftarBackgroundTasks()
      result(nil)
      return
    }
    Task {
      await self.endAllIftarActivitiesNow()
      self.cancelIftarBackgroundTasks()
      result(nil)
    }
  }

  private func endAllIftarActivities(result: @escaping FlutterResult) {
    endIftarLiveActivity(result: result)
  }

  @available(iOS 16.1, *)
  private func endAllIftarActivitiesNow() async {
    for activity in Activity<IftarAttributes>.activities {
      logIftarState("end", state: activity.contentState)
      await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
    }
  }

  @available(iOS 16.1, *)
  private func logIftarState(_ event: String, state: IftarAttributes.ContentState) {
    let remainingSeconds = max(0, Int(state.iftarDate.timeIntervalSinceNow))
    debugLog(
      "[IftarLiveActivity] \(event) mode=\(state.mode) phase=\(state.phase) remainingSeconds=\(remainingSeconds) iftarDate=\(state.iftarDate) endDate=\(state.endDate)"
    )
  }
}

@available(iOS 16.1, *)
struct IftarAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var title: String
    var subtitle: String
    var iftarDate: Date
    var endDate: Date
    var lang: String?
    var mode: String
    var postMessage: String
    var phase: String

    enum CodingKeys: String, CodingKey {
      case title
      case subtitle
      case iftarEpochMs
      case iftarDate
      case endDate
      case endEpochMs
      case lang
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
      lang: String?,
      mode: String,
      postMessage: String,
      phase: String
    ) {
      self.title = title
      self.subtitle = subtitle
      self.iftarDate = iftarDate
      self.endDate = endDate
      self.lang = lang
      self.mode = mode
      self.postMessage = postMessage
      self.phase = phase
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      title = try container.decodeIfPresent(String.self, forKey: .title) ?? "İftara"
      subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? "Kalan süre"
      if let epochMs = try container.decodeIfPresent(Int64.self, forKey: .iftarEpochMs) {
        iftarDate = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000.0)
      } else if let value = try container.decodeIfPresent(Date.self, forKey: .iftarDate) {
        iftarDate = value
      } else if let legacyValue = try container.decodeIfPresent(Date.self, forKey: .endDate) {
        iftarDate = legacyValue
      } else {
        iftarDate = Date()
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
      lang = try container.decodeIfPresent(String.self, forKey: .lang)
      postMessage = try container.decodeIfPresent(String.self, forKey: .postMessage) ?? ""
      phase = try container.decodeIfPresent(String.self, forKey: .phase) ?? "countdown"
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(title, forKey: .title)
      try container.encode(subtitle, forKey: .subtitle)
      try container.encode(Int64(iftarDate.timeIntervalSince1970 * 1000), forKey: .iftarEpochMs)
      try container.encode(endDate, forKey: .endDate)
      try container.encodeIfPresent(lang, forKey: .lang)
      try container.encode(mode, forKey: .mode)
      try container.encode(postMessage, forKey: .postMessage)
      try container.encode(phase, forKey: .phase)
    }
  }

  var name: String
}
