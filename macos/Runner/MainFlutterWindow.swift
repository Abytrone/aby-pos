import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FolderAccess.register(with: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}

/// Keeps the right to write to a folder the user picked after the app
/// restarts (the sandbox forgets it): a security-scoped bookmark is made
/// when it is picked, and opened again on the next run.
enum FolderAccess {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "aby/folder_access", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "bookmark":
        guard let path = call.arguments as? String,
              let data = try? URL(fileURLWithPath: path, isDirectory: true).bookmarkData(
                options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        else { return result(nil) }
        result(FlutterStandardTypedData(bytes: data))
      case "open":
        var stale = false
        guard let bookmark = call.arguments as? FlutterStandardTypedData,
              let url = try? URL(
                resolvingBookmarkData: bookmark.data, options: .withSecurityScope,
                relativeTo: nil, bookmarkDataIsStale: &stale),
              url.startAccessingSecurityScopedResource()
        else { return result(nil) }
        // Open for the rest of the run, so it is never stopped.
        result(url.path)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
