import GoogleMaps
import Flutter
import UIKit
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    //GMSServices.provideAPIKey(Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String ?? "")
    GMSServices.provideAPIKey("GOOGLE_MAPS_API_KEY")
    //GMSServices.provideAPIKey(ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? "")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }

}
