//
//  PacebudActivityAttributes.swift
//  com.orzan.pacerunner.PacebudWidget
//
//  Created by Paco Orta Bazán on 8/14/25.
//

import ActivityKit
import Foundation

struct PacebudActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your running activity
        var distance: Double
        var distanceUnit: String
        var elapsedTime: String
        var pace: String
        var isRunning: Bool
        var goal: String?
        var predictedFinish: String?
        var differenceSeconds: Int?
    }

    // Fixed non-changing properties about your activity
    var activityName: String
}
