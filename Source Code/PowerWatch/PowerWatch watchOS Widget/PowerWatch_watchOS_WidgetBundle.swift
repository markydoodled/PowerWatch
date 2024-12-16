//
//  PowerWatch_watchOS_WidgetBundle.swift
//  PowerWatch watchOS WidgetExtension
//
//  Created by Mark Howard on 27/03/2024.
//

import WidgetKit
import SwiftUI

@main
struct PowerWatch_watchOS_WidgetBundle: WidgetBundle {
    var body: some Widget {
        PowerWatch_watchOS_Widget_Phone()
        PowerWatch_watchOS_Widget_Watch()
    }
}
