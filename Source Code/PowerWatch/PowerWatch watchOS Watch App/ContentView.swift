//
//  ContentView.swift
//  PowerWatch watchOS Watch App
//
//  Created by Mark Howard on 04/08/2023.
//

import SwiftUI

struct ContentView: View {
    @State var phonePercentage = 0.0
    @State var phoneState = 0
    @State var watchPercentage = 0.0
    @State var watchState = 0
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Label("iPhone", systemImage: "iphone")
                                .bold()
                            Group {
                                if phonePercentage >= 21 {
                                    Text("\(String(stringLiteral: phonePercentage.formatted()))%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                                if phonePercentage >= 11 {
                                    Text("\(String(stringLiteral: phonePercentage.formatted()))%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                }
                                if phonePercentage <= 10 {
                                    Text("\(String(stringLiteral: phonePercentage.formatted()))%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.red)
                                }
                            }
                            Group {
                                if phoneState == 1 {
                                    Text("Unplugged")
                                        .bold()
                                        .foregroundColor(.orange)
                                }
                                if phoneState == 2 {
                                    Text("Charging")
                                        .bold()
                                        .foregroundColor(.accentColor)
                                }
                                if phoneState == 3 {
                                    Text("Full")
                                        .bold()
                                        .foregroundColor(.green)
                                }
                                if phoneState == 0 {
                                    Text("Unknown")
                                        .bold()
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    Divider()
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Label("Apple Watch", systemImage: "applewatch")
                                .bold()
                            Group {
                                if watchPercentage >= 21 {
                                    Text("\(String(stringLiteral: watchPercentage.formatted()))%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                                if watchPercentage >= 11 {
                                    Text("\(String(stringLiteral: watchPercentage.formatted()))%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                }
                                if watchPercentage <= 10 {
                                    Text("\(String(stringLiteral: watchPercentage.formatted()))%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.red)
                                }
                            }
                            Group {
                                if watchState == 1 {
                                    Text("Unplugged")
                                        .bold()
                                        .foregroundColor(.orange)
                                }
                                if watchState == 2 {
                                    Text("Charging")
                                        .bold()
                                        .foregroundColor(.accentColor)
                                }
                                if watchState == 3 {
                                    Text("Full")
                                        .bold()
                                        .foregroundColor(.green)
                                }
                                if watchState == 0 {
                                    Text("Unknown")
                                        .bold()
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    Divider()
                    Button(action: {
                        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
                        let batteryLevel = WKInterfaceDevice.current().batteryLevel
                        let batteryState = WKInterfaceDevice.current().batteryState
                        watchState = batteryState.rawValue
                        watchPercentage = Double(batteryLevel)
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("PowerWatch")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear() {
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
            let batteryLevel = WKInterfaceDevice.current().batteryLevel
            let batteryState = WKInterfaceDevice.current().batteryState
            watchState = batteryState.rawValue
            watchPercentage = Double(batteryLevel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
