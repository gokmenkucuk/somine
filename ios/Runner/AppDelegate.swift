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
    // NATIVE GATEKEEPER: Controls which orientations are allowed
    // When FALSE: App is locked to portrait only (default)
    // When TRUE: App allows all orientations (for YouTube fullscreen)
    private var isLandscapeEnabled = false

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Logger.shared.log("AppDelegate: didFinishLaunchingWithOptions started.")

        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

        // DEBUG CHANNEL
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

        // ORIENTATION CHANNEL - Native Gatekeeper for YouTube Fullscreen
        let orientationChannel = FlutterMethodChannel(name: "com.somine.app/orientation",
                                                       binaryMessenger: controller.binaryMessenger)
        orientationChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate unavailable", details: nil))
                return
            }

            switch call.method {
            case "enableLandscape":
                // UNLOCK: Allow landscape for YouTube fullscreen
                self.isLandscapeEnabled = true
                Logger.shared.log("🔓 Orientation: Landscape UNLOCKED")
                self.notifyOrientationChange()
                result(nil)
                
            case "disableLandscape":
                // LOCK: Force portrait only
                self.isLandscapeEnabled = false
                Logger.shared.log("🔒 Orientation: Portrait LOCKED")
                self.notifyOrientationChange()
                result(nil)
                
            case "setOrientation":
                // Legacy support
                if let orientation = call.arguments as? String {
                    self.isLandscapeEnabled = (orientation == "landscape")
                    Logger.shared.log("Orientation set to: \(orientation)")
                    self.notifyOrientationChange()
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Orientation must be a string", details: nil))
                }
                
            default:
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
    
    // MARK: - Notify iOS about orientation change
    private func notifyOrientationChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if #available(iOS 16.0, *) {
                // iOS 16+ - First notify that orientations changed
                if let windowScene = self.window?.windowScene {
                    // Step 1: Tell rootVC to re-query supported orientations
                    if let rootVC = windowScene.keyWindow?.rootViewController {
                        rootVC.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                    
                    // Step 2: Request geometry update with the new orientation mask
                    let geometryPrefs = UIWindowScene.GeometryPreferences.iOS()
                    if self.isLandscapeEnabled {
                        geometryPrefs.interfaceOrientations = .allButUpsideDown
                    } else {
                        geometryPrefs.interfaceOrientations = .portrait
                    }
                    
                    windowScene.requestGeometryUpdate(geometryPrefs) { error in
                        Logger.shared.log("Geometry update error: \(error.localizedDescription)")
                    }
                }
            } else {
                // iOS 15 and earlier - use old method
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    // MARK: - THE GATEKEEPER
    // This method is called by iOS whenever it needs to know which orientations are allowed.
    // By returning different masks based on isLandscapeEnabled, we control when rotation is permitted.
    
    override func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if isLandscapeEnabled {
            // UNLOCKED: Allow all orientations (for YouTube fullscreen)
            Logger.shared.log("📱 Orientation mask: allButUpsideDown")
            return .allButUpsideDown
        } else {
            // LOCKED: Portrait only (normal app usage)
            Logger.shared.log("📱 Orientation mask: portrait")
            return .portrait
        }
    }

    // MARK: - URL Handling
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Logger.shared.log("AppDelegate: Open URL called: \(url.absoluteString)")

        if let scheme = url.scheme, scheme.hasPrefix("ShareMedia") {
            Logger.shared.log("AppDelegate: Intercepted ShareMedia URL.")
            return true
        }

        return super.application(app, open: url, options: options)
    }
}
