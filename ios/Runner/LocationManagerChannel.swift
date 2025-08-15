import Flutter
import CoreLocation

@available(iOS 9.0, *)
public class LocationManagerChannel: NSObject, FlutterPlugin {
    private var locationManager: CLLocationManager?
    private var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pacebud/location_manager", binaryMessenger: registrar.messenger())
        let instance = LocationManagerChannel()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configureForFitness":
            configureForFitness(result: result)
        case "enableBackgroundLocation":
            enableBackgroundLocation(result: result)
        case "disableBackgroundLocation":
            disableBackgroundLocation(result: result)
        case "authorizationStatus":
            authorizationStatus(result: result)
        case "requestAlways":
            requestAlways(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func configureForFitness(result: @escaping FlutterResult) {
        locationManager = CLLocationManager()
        
        // Configure for fitness tracking - iOS specific settings
        locationManager?.activityType = .fitness
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 5.0 // 5 meters
        
        // Background location settings
        if #available(iOS 9.0, *) {
            locationManager?.allowsBackgroundLocationUpdates = true
            locationManager?.pausesLocationUpdatesAutomatically = false
        }
        
        // Show blue indicator in status bar when app is using location in background (iOS 11+)
        if #available(iOS 11.0, *) {
            locationManager?.showsBackgroundLocationIndicator = true
        }
        
        result(true)
    }
    
    private func enableBackgroundLocation(result: @escaping FlutterResult) {
        guard let manager = locationManager else {
            result(FlutterError(code: "NO_MANAGER", message: "Location manager not configured", details: nil))
            return
        }
        
        if #available(iOS 9.0, *) {
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = false
        }
        
        result(true)
    }
    
    private func disableBackgroundLocation(result: @escaping FlutterResult) {
        guard let manager = locationManager else {
            result(FlutterError(code: "NO_MANAGER", message: "Location manager not configured", details: nil))
            return
        }
        
        if #available(iOS 9.0, *) {
            manager.allowsBackgroundLocationUpdates = false
        }
        
        result(true)
    }
    
    private func authorizationStatus(result: @escaping FlutterResult) {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways: result("always")
        case .authorizedWhenInUse: result("whenInUse")
        case .denied: result("denied")
        case .restricted: result("restricted")
        case .notDetermined: result("notDetermined")
        @unknown default: result("unknown")
        }
    }
    
    private func requestAlways(result: @escaping FlutterResult) {
        if locationManager == nil { locationManager = CLLocationManager() }
        // iOS suele requerir WhenInUse primero; si ya lo tienes, esto muestra el 2º prompt
        locationManager?.requestAlwaysAuthorization()
        result(nil)
    }
}
