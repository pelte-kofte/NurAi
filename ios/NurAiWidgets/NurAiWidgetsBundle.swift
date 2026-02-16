//
//  NurAiWidgetsBundle.swift
//  NurAiWidgets
//
//  Created by Bekir Cem Kusdemir on 16.02.2026.
//

import WidgetKit
import SwiftUI

@main
struct NurAiWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NurAiWidgets()
        NurAiWidgetsControl()
        NurAiWidgetsLiveActivity()
    }
}
