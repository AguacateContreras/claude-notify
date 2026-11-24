// ClaudeNotify: posts one macOS notification that stays in Notification Center.
// Usage: ClaudeNotify --title T --message M [--subtitle S] [--image /path.png] [--sound name|none]
import Foundation
import UserNotifications

func arg(_ name: String) -> String? {
    let a = CommandLine.arguments
    guard let i = a.firstIndex(of: name), i + 1 < a.count else { return nil }
    return a[i + 1]
}

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(1)
}

let center = UNUserNotificationCenter.current()
let done = DispatchSemaphore(value: 0)
var exitCode: Int32 = 0

center.requestAuthorization(options: [.alert, .sound]) { granted, error in
    guard granted else {
        FileHandle.standardError.write("ClaudeNotify: notifications not allowed (System Settings > Notifications > ClaudeNotify)\n".data(using: .utf8)!)
        exitCode = 2; done.signal(); return
    }
    if CommandLine.arguments.contains("--authorize") { done.signal(); return }

    let content = UNMutableNotificationContent()
    content.title = arg("--title") ?? "Claude Code"
    content.body = arg("--message") ?? "Listo"
    if let s = arg("--subtitle") { content.subtitle = s }
    switch arg("--sound") {
    case nil, "default": content.sound = .default
    case "none": content.sound = nil
    case let name?: content.sound = UNNotificationSound(named: UNNotificationSoundName(name))
    }
    if let img = arg("--image"), FileManager.default.fileExists(atPath: img) {
        // The system moves attachment files into its store, so hand it a copy.
        let src = URL(fileURLWithPath: img)
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(src.pathExtension)
        do {
            try FileManager.default.copyItem(at: src, to: tmp)
            content.attachments = [try UNNotificationAttachment(identifier: "image", url: tmp)]
        } catch {
            FileHandle.standardError.write("ClaudeNotify: image ignored (\(error.localizedDescription))\n".data(using: .utf8)!)
        }
    }
    let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    center.add(req) { err in
        if let err { FileHandle.standardError.write("ClaudeNotify: \(err.localizedDescription)\n".data(using: .utf8)!); exitCode = 3 }
        done.signal()
    }
}

if done.wait(timeout: .now() + 30) == .timedOut { fail("ClaudeNotify: timed out waiting for permission") }
exit(exitCode)
