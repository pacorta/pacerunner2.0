import UIKit
import Flutter
import GoogleMaps
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Leer GoogleMapsApiKey desde Info.plist
    let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String ?? ""
    if !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    } else {
      NSLog("Google Maps API key missing. Check Info.plist 'GoogleMapsApiKey'.")
    }

    // Registrar tu canal nativo (coincide con tu MethodChannel en Dart)
    LocationManagerChannel.register(
      with: self.registrar(forPlugin: "pacebud/location_manager")!
    )

    // Register Live Activity channel
    if #available(iOS 16.2, *) {
      LiveActivityChannel.register(
        with: self.registrar(forPlugin: "pacebud/live_activity")!
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
}