import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import Foundation

// Custom ShareViewController - No "Post" UI, Manual Data Saving, Safe Redirect
class ShareViewController: UIViewController {
    
    private let appGroupId = "group.com.somine.app"
    private let userDefaultsKey = "ShareKey"
    private let urlScheme = "ShareMedia-com.somine.app"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Transparent background
        view.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Logger.shared.log("ShareViewController: viewDidAppear - Starting process")
        handleSharedItems()
    }
    
    private func handleSharedItems() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            Logger.shared.log("ShareViewController: No attachments found")
            completeRequest()
            return
        }
        
        Logger.shared.log("ShareViewController: Found \(attachments.count) attachments")
        
        let group = DispatchGroup()
        var sharedItems: [[String: Any]] = []
        let sharedItemsQueue = DispatchQueue(label: "com.somine.share.items")
        
        for attachment in attachments {
            Logger.shared.log("ShareViewController: Attachment types: \(attachment.registeredTypeIdentifiers.joined(separator: ", "))")
            group.enter()

            loadSharedItem(from: attachment) { item in
                if let item = item {
                    sharedItemsQueue.async {
                        sharedItems.append(item)
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            Logger.shared.log("ShareViewController: All items processed. Saving...")
            self?.saveAndRedirect(items: sharedItems)
        }
    }

    private func loadSharedItem(from attachment: NSItemProvider, completion: @escaping ([String: Any]?) -> Void) {
        let candidateTypes = [
            UTType.url.identifier,
            UTType.plainText.identifier,
            UTType.text.identifier,
            "public.url",
            "public.plain-text",
            "public.text"
        ].removingDuplicates()

        func loadNext(_ index: Int) {
            guard index < candidateTypes.count else {
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    Logger.shared.log("ShareViewController: Image found but no URL/text representation was available")
                } else {
                    Logger.shared.log("ShareViewController: No usable URL/text representation found")
                }
                completion(nil)
                return
            }

            let typeIdentifier = candidateTypes[index]
            guard attachment.hasItemConformingToTypeIdentifier(typeIdentifier) else {
                loadNext(index + 1)
                return
            }

            attachment.loadItem(forTypeIdentifier: typeIdentifier) { item, error in
                if let error = error {
                    Logger.shared.log("ShareViewController: Failed to load \(typeIdentifier): \(error.localizedDescription)")
                    loadNext(index + 1)
                    return
                }

                guard let value = self.stringValue(from: item)?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !value.isEmpty else {
                    Logger.shared.log("ShareViewController: Empty or unsupported item for \(typeIdentifier): \(String(describing: item))")
                    loadNext(index + 1)
                    return
                }

                let itemType = typeIdentifier == UTType.url.identifier || typeIdentifier == "public.url" ? "url" : "text"
                Logger.shared.log("ShareViewController: Found \(itemType): \(value)")
                completion([
                    "path": value,
                    "type": itemType,
                    "mimeType": "text/plain"
                ])
            }
        }

        loadNext(0)
    }

    private func stringValue(from item: NSSecureCoding?) -> String? {
        if let url = item as? URL {
            return url.absoluteString
        }

        if let url = item as? NSURL {
            return url.absoluteString
        }

        if let text = item as? String {
            return text
        }

        if let attributedText = item as? NSAttributedString {
            return attributedText.string
        }

        if let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }
    
    private func saveAndRedirect(items: [[String: Any]]) {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: items, options: []) {
             if let jsonString = String(data: jsonData, encoding: .utf8) {
                 Logger.shared.log("ShareViewController: Saving JSON: \(jsonString)")
             }
             
             userDefaults?.removeObject(forKey: userDefaultsKey)
             userDefaults?.set(jsonData, forKey: userDefaultsKey)
             userDefaults?.synchronize()
        } else {
             Logger.shared.log("ShareViewController: Failed to serialize items")
        }
        
        // Safe Redirect
        Logger.shared.log("ShareViewController: Attempting Safe Redirect")
        openMainApp()
    }
    
    private func openMainApp() {
        let urlString = "\(urlScheme)://data"
        guard let url = URL(string: urlString) else { return }
        
        var responder: UIResponder? = self
        var found = false
        
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: { success in
                    Logger.shared.log("ShareViewController: OpenURL success: \(success)")
                    self.completeRequest()
                })
                found = true
                break
            }
            responder = responder?.next
        }
        
        if !found {
            let selector = NSSelectorFromString("openURL:")
            responder = self
            while responder != nil {
                if responder!.responds(to: selector) {
                    responder!.perform(selector, with: url)
                    self.completeRequest()
                    return
                }
                responder = responder?.next
            }
            self.completeRequest()
        }
    }
    
    private func completeRequest() {
        Logger.shared.log("ShareViewController: Completing Request")
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// Logger class definition for debugging
class Logger {
    static let shared = Logger()
    private let fileManager = FileManager.default
    private let appGroupId = "group.com.somine.app"
    private let logFileName = "somine_debug.log"
    
    private var logFileURL: URL? {
        guard let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }
        return container.appendingPathComponent(logFileName)
    }
    
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let logMessage = "[\(timestamp)] [SHARE_EXT] \(message)\n"
        print("SOMINE_SHARE: \(message)")
        
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
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
