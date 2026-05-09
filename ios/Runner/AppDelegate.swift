import Flutter
import UIKit
import GoogleMaps // 1. L'import doit rester ici

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 2. PLACE TA CLÉ ICI (AVANT LE RETURN)
    GMSServices.provideAPIKey("AIzaSyB1dGpwvymAX1Hs3BVlmbDKNZb3562Zcfk")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}