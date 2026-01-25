import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    private let appGroupId = "group.com.somine.app"
    private let userDefaultsKey = "sharedElements"
    private let urlScheme = "ShareMedia"
    
    override func isContentValid() -> Bool {
        return true
    }
    
    override func didSelectPost() {
        handleSharedItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleSharedItems()
    }
    
    private func handleSharedItems() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }
        
        let group = DispatchGroup()
        var sharedItems: [[String: Any]] = []
        
        for attachment in attachments {
            group.enter()
            
            // Handle URLs
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, error in
                    defer { group.leave() }
                    if let url = item as? URL {
                        sharedItems.append([
                            "path": url.absoluteString,
                            "type": "url"
                        ])
                    }
                }
            }
            // Handle Text
            else if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.text.identifier) { [weak self] item, error in
                    defer { group.leave() }
                    if let text = item as? String {
                        sharedItems.append([
                            "path": text,
                            "type": "text"
                        ])
                    }
                }
            }
            // Handle Images
            else if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] item, error in
                    defer { group.leave() }
                    guard let self = self else { return }
                    
                    if let url = item as? URL {
                        if let savedPath = self.saveToAppGroup(url: url) {
                            sharedItems.append([
                                "path": savedPath,
                                "type": "image"
                            ])
                        }
                    } else if let image = item as? UIImage {
                        if let savedPath = self.saveImageToAppGroup(image: image) {
                            sharedItems.append([
                                "path": savedPath,
                                "type": "image"
                            ])
                        }
                    }
                }
            }
            else {
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.saveAndRedirect(items: sharedItems)
        }
    }
    
    private func saveToAppGroup(url: URL) -> String? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }
        
        let fileName = url.lastPathComponent
        let destinationURL = containerURL.appendingPathComponent(fileName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return destinationURL.absoluteString
        } catch {
            print("Error copying file: \(error)")
            return nil
        }
    }
    
    private func saveImageToAppGroup(image: UIImage) -> String? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId),
              let imageData = image.pngData() else {
            return nil
        }
        
        let fileName = UUID().uuidString + ".png"
        let destinationURL = containerURL.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: destinationURL)
            return destinationURL.absoluteString
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    private func saveAndRedirect(items: [[String: Any]]) {
        // Save to UserDefaults for the app to read
        let userDefaults = UserDefaults(suiteName: appGroupId)
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: items, options: []) {
            userDefaults?.set(jsonData, forKey: userDefaultsKey)
            userDefaults?.synchronize()
        }
        
        // Open main app
        openMainApp()
        
        completeRequest()
    }
    
    private func openMainApp() {
        let urlString = "\(self.urlScheme)://data"
        guard let url = URL(string: urlString) else { return }
        
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    override func configurationItems() -> [Any]! {
        return []
    }
}
