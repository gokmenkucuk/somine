import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    // shared group id must be same as main app
    // TODO: Update this with your actual App Group ID
    let hostAppBundleIdentifier = "group.com.somine.app"
    let sharedKey = "ShareKey"

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        guard let extensionContext = extensionContext else {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            return
        }
        
        guard let item = extensionContext.inputItems.first as? NSExtensionItem else {
             self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
             return
        }

        // Handle URL sharing
        if let attachments = item.attachments {
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (url, error) in
                        if let shareURL = url as? URL {
                            self.saveAndRedirect(url: shareURL.absoluteString)
                        } else if let shareText = url as? String {
                             // Sometimes URLs are passed as strings
                            self.saveAndRedirect(url: shareText)
                        }
                    }
                    return // Found a URL, stop processing
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (text, error) in
                        if let shareText = text as? String {
                            self.saveAndRedirect(url: shareText)
                        }
                    }
                    return // Found text, stop processing
                }
            }
        }
        
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func saveAndRedirect(url: String) {
        // Save to UserDefaults using App Group
        if let userDefaults = UserDefaults(suiteName: hostAppBundleIdentifier) {
            userDefaults.set(url, forKey: sharedKey)
            userDefaults.synchronize()
        }
        
        // Open the main app
        // The scheme must be defined in Info.plist of the main app
        let url = URL(string: "somine://share")
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url!, options: [:], completionHandler: nil)
                break
            }
            responder = responder?.next
        }
        
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}
