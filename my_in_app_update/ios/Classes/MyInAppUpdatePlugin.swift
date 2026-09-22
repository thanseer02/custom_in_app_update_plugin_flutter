import Flutter
import UIKit

public class MyInAppUpdatePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "my_in_app_update", binaryMessenger: registrar.messenger())
    let instance = MyInAppUpdatePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getAppInfo":
      let bundle = Bundle.main
      let bundleId = bundle.bundleIdentifier ?? ""
      let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
      let buildNumber = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "1"
      let appName = bundle.infoDictionary?["CFBundleDisplayName"] as? String ?? bundle.infoDictionary?["CFBundleName"] as? String ?? ""

      let info: [String: Any] = [
        "bundleId": bundleId,
        "currentVersion": version,
        "buildNumber": buildNumber,
        "appName": appName
      ]
      result(info)
    case "openAppStore":
      guard let args = call.arguments as? [String: Any],
            let urlString = args["url"] as? String,
            let url = URL(string: urlString) else {
        result(FlutterError(code: "INVALID_URL", message: "Invalid App Store URL", details: nil))
        return
      }
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
      } else {
        result(FlutterError(code: "CANNOT_OPEN_URL", message: "Cannot open URL: \(urlString)", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
