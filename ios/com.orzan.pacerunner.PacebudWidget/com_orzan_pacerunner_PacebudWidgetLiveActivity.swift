//
//  com_orzan_pacerunner_PacebudWidgetLiveActivity.swift
//  com.orzan.pacerunner.PacebudWidget
//
//  Created by Paco Orta Bazán on 8/14/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct com_orzan_pacerunner_PacebudWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PacebudActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🏃‍♂️ Pacebud")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        Text("\(String(format: "%.2f", context.state.distance)) \(context.state.distanceUnit)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(context.state.elapsedTime)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text(context.state.pace)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            if let goal = context.state.goal {
                                Text(goal)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            if let predicted = context.state.predictedFinish {
                                Text("pred: \(predicted)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(context.state.isRunning ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Distance")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.2f", context.state.distance)) \(context.state.distanceUnit)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Time")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.elapsedTime)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pace: \(context.state.pace)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let goal = context.state.goal {
                                Text(goal)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if let predicted = context.state.predictedFinish {
                                Text("pred: \(predicted)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(context.state.isRunning ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(context.state.isRunning ? "Running" : "Paused")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Text("\(String(format: "%.1f", context.state.distance))")
                    .font(.caption2)
                    .fontWeight(.semibold)
            } compactTrailing: {
                HStack(spacing: 2) {
                    Circle()
                        .fill(context.state.isRunning ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(context.state.elapsedTime.components(separatedBy: ":").dropFirst().joined(separator: ":"))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            } minimal: {
                Circle()
                    .fill(context.state.isRunning ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
            }
            .widgetURL(URL(string: "pacebud://open"))
            .keylineTint(Color.blue)
        }
    }
}

extension PacebudActivityAttributes {
    fileprivate static var preview: PacebudActivityAttributes {
        PacebudActivityAttributes(activityName: "Running Session")
    }
}

extension PacebudActivityAttributes.ContentState {
    fileprivate static var running: PacebudActivityAttributes.ContentState {
        PacebudActivityAttributes.ContentState(
            distance: 2.45,
            distanceUnit: "km",
            elapsedTime: "00:12:34",
            pace: "5:05/km",
            isRunning: true,
            goal: "10 km in 50m 00s",
            predictedFinish: "49m 30s"
        )
    }
     
    fileprivate static var paused: PacebudActivityAttributes.ContentState {
        PacebudActivityAttributes.ContentState(
            distance: 1.23,
            distanceUnit: "mi",
            elapsedTime: "00:08:15",
            pace: "6:42/mi",
            isRunning: false,
            goal: "6.0 mi in 1h 00m 00s",
            predictedFinish: "1h 02m 10s"
        )
    }
}

#Preview("Notification", as: .content, using: PacebudActivityAttributes.preview) {
   com_orzan_pacerunner_PacebudWidgetLiveActivity()
} contentStates: {
    PacebudActivityAttributes.ContentState.running
    PacebudActivityAttributes.ContentState.paused
}
