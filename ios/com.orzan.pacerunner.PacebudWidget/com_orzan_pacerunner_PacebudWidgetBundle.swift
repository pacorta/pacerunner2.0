//
//  com_orzan_pacerunner_PacebudWidgetBundle.swift
//  com.orzan.pacerunner.PacebudWidget
//
//  Created by Paco Orta Bazán on 8/14/25.
//

import WidgetKit
import SwiftUI

@main
struct com_orzan_pacerunner_PacebudWidgetBundle: WidgetBundle {
    var body: some Widget {
        com_orzan_pacerunner_PacebudWidget()
        com_orzan_pacerunner_PacebudWidgetControl()
        com_orzan_pacerunner_PacebudWidgetLiveActivity()
    }
}
