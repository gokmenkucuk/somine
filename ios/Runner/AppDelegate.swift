import Flutter
import UIKit
import Foundation
import flutter_local_notifications

class Logger {
    static let shared = Logger()
    private let fileManager = FileManager.default
    private let appGroupId = "group.com.somine.app"
    private let logFileName = "somine_debug.log"
    
    private var logFileURL: URL? {
        guard let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("Logger Error: Could not get App Group container.")
            return nil
        }
        return container.appendingPathComponent(logFileName)
    }
    
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let logMessage = "[\(timestamp)] [APP] \(message)\n"
        print("SOMINE_APP: \(message)") 
        
        guard let fileURL = logFileURL else { return }
        
        if !fileManager.fileExists(atPath: fileURL.path) {
            try? logMessage.write(to: fileURL, atomically: true, encoding: .utf8)
        } else {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                if let data = logMessage.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        }
    }
    
    func readLogs() -> String {
        guard let fileURL = logFileURL,
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return "No logs found."
        }
        return content
    }
    
    func clearLogs() {
        guard let fileURL = logFileURL else { return }
        try? fileManager.removeItem(at: fileURL)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    Logger.shared.log("AppDelegate: didFinishLaunchingWithOptions started. LaunchOptions: \(String(describing: launchOptions))")
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let debugChannel = FlutterMethodChannel(name: "com.somine.app/debug",
                                              binaryMessenger: controller.binaryMessenger)
    debugChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getNativeLogs" {
          let logs = Logger.shared.readLogs()
          result(logs)
      } else if call.method == "clearNativeLogs" {
          Logger.shared.clearLogs()
          result(nil)
      } else if call.method == "getSharedData" {
          let userDefaults = UserDefaults(suiteName: "group.com.somine.app")
          if let data = userDefaults?.data(forKey: "ShareKey"),
             let jsonString = String(data: data, encoding: .utf8) {
              result(jsonString)
          } else {
              result(nil)
          }
      } else if call.method == "clearSharedData" {
          let userDefaults = UserDefaults(suiteName: "group.com.somine.app")
          userDefaults?.removeObject(forKey: "ShareKey")
          userDefaults?.synchronize()
          result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    // Set notification delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)
    
    Logger.shared.log("AppDelegate: GeneratedPluginRegistrant registered")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    Logger.shared.log("AppDelegate: Open URL called: \(url.absoluteString)")
    
    // SAFE WAKE UP PATTERN:
    // If this is our Share Extension waking up the app, we consume the event here.
    // We Do NOT call super, preventing 'receive_sharing_intent' or other plugins
    // from trying to process this URL while Flutter engine is cold-starting.
    // The data is already in UserDefaults (App Group), and Flutter will fetch it manually.
    if let scheme = url.scheme, scheme.hasPrefix("ShareMedia") {
        Logger.shared.log("AppDelegate: Intercepted ShareMedia URL. Consuming event to prevent crash.")
        return true
    }
    
    return super.application(app, open: url, options: options)
  }
}

