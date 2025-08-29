//
//  com_orzan_pacerunner_PacebudWidgetLiveActivity.swift
//  com.orzan.pacerunner.PacebudWidget
//
//  Created by Paco Orta Bazán on 8/14/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Formatting helpers (widget-only)
fileprivate func formatElapsed(_ hhmmss: String) -> String {
    let parts = hhmmss.split(separator: ":")
    if parts.count == 3 {
        let hours = String(parts[0])
        if hours == "00" || hours == "0" { // under 1 hour → mm:ss
            return "\(parts[1]):\(parts[2])"
        } else { // 1h+ → h:mm:ss
            return "\(hours):\(parts[1]):\(parts[2])"
        }
    }
    return hhmmss
}

fileprivate func removeTrailingSecondsToken(_ text: String?) -> String? {
    guard let text else { return nil }
    // For long placeholders, show compact dashes
    if text.lowercased().contains("calculating") { return "---" }
    let tokens = text.split(separator: " ")
    if let last = tokens.last, last.hasSuffix("s") {
        return tokens.dropLast().joined(separator: " ")
    }
    return text
}

fileprivate func stripPaceUnit(_ pace: String) -> String {
    if let slashIndex = pace.firstIndex(of: "/") {
        return String(pace[..<slashIndex])
    }
    return pace
}

struct com_orzan_pacerunner_PacebudWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PacebudActivityAttributes.self) { context in
            // Lock screen/banner UI — Strava‑like four columns with goal pill
            VStack(alignment: .leading, spacing: 8) {
                // DEBUG layout toggle: set to true to show max-width strings
                let debugLayout = false
                let elapsedFormatted = debugLayout ? "00:00:00" : formatElapsed(context.state.elapsedTime)
                let goalNoSec = debugLayout ? "000.00 mi in 000h 00m" : removeTrailingSecondsToken(context.state.goal)
                let projectionNoSec = debugLayout ? "000h 00m" : removeTrailingSecondsToken(context.state.predictedFinish)
                let paceDisplay = debugLayout ? "00:00/mi" : stripPaceUnit(context.state.pace)
                let minScale: CGFloat = debugLayout ? 1.0 : 0.7
                // Top row: status dot + goal pill
                HStack(spacing: 8) {
                    Circle()
                        .fill(context.state.isRunning ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    if let goal = goalNoSec {
                        Text(goal)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Text("Pacebud")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }

                // Metrics row
                HStack(alignment: .bottom, spacing: 8) {
                    // Distance
                    VStack(alignment: .leading, spacing: 2) {
                        Text(debugLayout ? "000.00" : String(format: "%.2f", context.state.distance))
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .italic()
                            .foregroundColor(.white)
                            .minimumScaleFactor(minScale)
                            .lineLimit(1)
                        Text(context.state.distanceUnit == "mi" ? "Miles" : "Kilometers")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .layoutPriority(1)
                    Spacer()
                    // Time
                    VStack(alignment: .leading, spacing: 2) {
                        Text(elapsedFormatted)
                            .font(.headline).fontWeight(.semibold)
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .minimumScaleFactor(minScale)
                            .lineLimit(1)
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .layoutPriority(1)
                    Spacer()
                    // Avg Pace
                    VStack(alignment: .leading, spacing: 2) {
                        Text(paceDisplay)
                            .font(.headline).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .minimumScaleFactor(minScale)
                            .lineLimit(1)
                        Text("Pace")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .layoutPriority(1)
                    Spacer()
                }
                // Bottom projection row (only for complex goals)
                if context.state.predictedFinish != nil {
                    HStack {
                        Spacer()
                        Text("Proj. Finish:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                        let isOverBottom = (context.state.differenceSeconds ?? 0) > 0
                        Text(projectionNoSec ?? "--")
                            .font(.headline)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundColor(isOverBottom ? .red : .white)
                            .lineLimit(1)
                        Spacer()
                    }
                }

                // Thin bottom progress bar (full width, not thick)
                if let p = context.state.progress {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 6)
                            Capsule()
                                .fill(Color.white)
                                .frame(width: max(0, min(CGFloat(p), 1.0)) * geo.size.width, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color.black.opacity(0.85))
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
            predictedFinish: "49m 30s",
            differenceSeconds: -30
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
            predictedFinish: "1h 02m 10s",
            differenceSeconds: 130
        )
    }
}

#Preview("Notification", as: .content, using: PacebudActivityAttributes.preview) {
   com_orzan_pacerunner_PacebudWidgetLiveActivity()
} contentStates: {
    PacebudActivityAttributes.ContentState.running
    PacebudActivityAttributes.ContentState.paused
}
