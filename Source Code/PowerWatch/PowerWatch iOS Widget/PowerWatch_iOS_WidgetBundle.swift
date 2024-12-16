//
//  PowerWatch_iOS_WidgetBundle.swift
//  PowerWatch iOS Widget
//
//  Created by Mark Howard on 26/03/2024.
//

import WidgetKit
import SwiftUI

@main
struct PowerWatch_iOS_WidgetBundle: WidgetBundle {
    var body: some Widget {
        PowerWatch_iOS_Widget_Phone()
        PowerWatch_iOS_Widget_Watch()
    }
}
