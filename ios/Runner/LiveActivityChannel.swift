import Flutter
import ActivityKit
import UIKit

// Copiar las definiciones del widget aquí
struct PacebudActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var distance: Double
        var distanceUnit: String
        var elapsedTime: String
        var pace: String
        var isRunning: Bool
        var goal: String?
        var predictedFinish: String?
        var differenceSeconds: Int?
    }
    
    var activityName: String
}

@available(iOS 16.2, *)
public class LiveActivityChannel: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var currentActivity: Activity<PacebudActivityAttributes>?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pacebud/live_activity", binaryMessenger: registrar.messenger())
        let instance = LiveActivityChannel()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRunningActivity":
            startRunningActivity(result: result)
        case "updateRunningActivity":
            updateRunningActivity(call: call, result: result)
        case "endRunningActivity":
            endRunningActivity(result: result)
        case "areActivitiesAvailable":
            areActivitiesAvailable(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startRunningActivity(result: @escaping FlutterResult) {
        // Check if activities are available
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            result(FlutterError(code: "ACTIVITIES_DISABLED", message: "Live Activities are disabled", details: nil))
            return
        }
        
        // End any existing activity first
        if let activity = currentActivity {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        
        let attributes = PacebudActivityAttributes(activityName: "Running Session")
        let initialState = PacebudActivityAttributes.ContentState(
            distance: 0.0,
            distanceUnit: "km",
            elapsedTime: "00:00:00",
            pace: "---",
            isRunning: true,
            goal: nil,
            predictedFinish: nil,
            differenceSeconds: nil
        )
        
        do {
            let activity = try Activity<PacebudActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            currentActivity = activity
            print("LiveActivity: Started successfully with ID: \(activity.id)")
            result(true)
        } catch {
            print("LiveActivity: Error starting activity: \(error)")
            result(FlutterError(code: "START_FAILED", message: "Failed to start activity: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func updateRunningActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let activity = currentActivity else {
            result(FlutterError(code: "NO_ACTIVITY", message: "No active live activity", details: nil))
            return
        }
        
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let distance = args["distance"] as? Double ?? 0.0
        let distanceUnit = args["distanceUnit"] as? String ?? "km"
        let elapsedTime = args["elapsedTime"] as? String ?? "00:00:00"
        let pace = args["pace"] as? String ?? "---"
        let isRunning = args["isRunning"] as? Bool ?? true
        let goal = args["goal"] as? String
        let predictedFinish = args["predictedFinish"] as? String
        let differenceSeconds = args["differenceSeconds"] as? Int
        
        let newState = PacebudActivityAttributes.ContentState(
            distance: distance,
            distanceUnit: distanceUnit,
            elapsedTime: elapsedTime,
            pace: pace,
            isRunning: isRunning,
            goal: goal,
            predictedFinish: predictedFinish,
            differenceSeconds: differenceSeconds
        )
        
        Task {
            await activity.update(using: newState)
            print("LiveActivity: Updated with distance: \(distance) \(distanceUnit)")
        }
        
        result(true)
    }
    
    private func endRunningActivity(result: @escaping FlutterResult) {
        guard let activity = currentActivity else {
            result(true) // Already ended or never started
            return
        }
        
        Task {
            // Create final state for the activity
            let finalState = PacebudActivityAttributes.ContentState(
                distance: activity.contentState.distance,
                distanceUnit: activity.contentState.distanceUnit,
                elapsedTime: activity.contentState.elapsedTime,
                pace: activity.contentState.pace,
                isRunning: false,
                goal: activity.contentState.goal,
                predictedFinish: activity.contentState.predictedFinish,
                differenceSeconds: activity.contentState.differenceSeconds
            )
            
            await activity.end(using: finalState, dismissalPolicy: .immediate)
            print("LiveActivity: Ended successfully")
        }
        
        currentActivity = nil
        result(true)
    }
    
    private func areActivitiesAvailable(result: @escaping FlutterResult) {
        if #available(iOS 16.1, *) {
            result(ActivityAuthorizationInfo().areActivitiesEnabled)
        } else {
            result(false)
        }
    }
}
