//
//  SleepWidgetBundle.swift
//  SleepWidget
//
//  Created by zhixin on 2026/9/14.
//

import WidgetKit
import SwiftUI

@main
struct SleepWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepWidget()
        SleepWidgetLiveActivity()
    }
}
