import GoogleMaps
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyAw7Q29bqYbztG-QCz5EYiqinTw6lEsSHo")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
