import Flutter
import UIKit
import CleverTapSDK
import clevertap_plugin
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: "app_store_overlay",
                                              binaryMessenger: controller.binaryMessenger)
    
    methodChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if (call.method == "showOverlay") {
          if let args = call.arguments as? [String: Any],
             let appId = args["appId"] as? String {
              self.showSKOverlay(appId: appId)
              result(true)
          } else {
              result(FlutterError(code: "INVALID_ARGUMENTS", message: "appId is required", details: nil))
          }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    CleverTap.autoIntegrate()
    CleverTapPlugin.sharedInstance()?.applicationDidLaunch(options: launchOptions)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func showSKOverlay(appId: String) {
      if #available(iOS 14.0, *) {
          let config = SKOverlay.AppConfiguration(appIdentifier: appId, position: .bottom)
          let overlay = SKOverlay(configuration: config)
          
          if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
              overlay.present(in: windowScene)
          }
      }
  }
}
