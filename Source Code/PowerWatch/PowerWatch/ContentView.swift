//
//  ContentView.swift
//  PowerWatch
//
//  Created by Mark Howard on 02/08/2023.
//

import SwiftUI

struct ContentView: View {
    @State var phonePercentage = 0.0
    @State var phoneState = 0
    @State var watchPercentage = 0.0
    @State var watchState = 0
    var body: some View {
        NavigationStack {
                VStack {
                    GroupBox {
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                            Label("iPhone", systemImage: "iphone")
                                .bold()
                                .font(.title)
                            Group {
                                if phonePercentage >= 21 {
                                    Text("\(String(stringLiteral: phonePercentage.formatted()))%")
                                        .bold()
                                        .font(.title)
                                        .foregroundColor(.green)
                                }
                                if phonePercentage >= 11 {
                                    Text("\(String(stringLiteral: phonePercentage.formatted()))%")
                                        .bold()
                                        .font(.title)
                                        .foregroundColor(.orange)
                                }
                                if phonePercentage <= 10 {
                                    Text("\(String(stringLiteral: phonePercentage.formatted()))%")
                                        .bold()
                                        .font(.title)
                                        .foregroundColor(.red)
                                }
                            }
                                Group {
                                    if phoneState == 1 {
                                        Text("Unplugged")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.orange)
                                    }
                                    if phoneState == 2 {
                                        Text("Charging")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.accentColor)
                                    }
                                    if phoneState == 3 {
                                        Text("Full")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.green)
                                    }
                                    if phoneState == 0 {
                                        Text("Unknown")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    .padding(.all)
                    Divider()
                    GroupBox {
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                                Label("Apple Watch", systemImage: "applewatch")
                                    .bold()
                                    .font(.title)
                                Group {
                                    if watchPercentage >= 21 {
                                        Text("\(String(stringLiteral: watchPercentage.formatted()))%")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.green)
                                    }
                                    if watchPercentage >= 11 {
                                        Text("\(String(stringLiteral: watchPercentage.formatted()))%")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.orange)
                                    }
                                    if watchPercentage <= 10 {
                                        Text("\(String(stringLiteral: watchPercentage.formatted()))%")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.red)
                                    }
                                }
                                Group {
                                    if watchState == 1 {
                                        Text("Unplugged")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.orange)
                                    }
                                    if watchState == 2 {
                                        Text("Charging")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.accentColor)
                                    }
                                    if watchState == 3 {
                                        Text("Full")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.green)
                                    }
                                    if watchState == 0 {
                                        Text("Unknown")
                                            .bold()
                                            .font(.title)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    .padding(.all)
                }
            .navigationTitle("PowerWatch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIDevice.current.isBatteryMonitoringEnabled = true
                        let batteryLevel = UIDevice.current.batteryLevel
                        let batteryState = UIDevice.current.batteryState
                        phoneState = batteryState.rawValue
                        phonePercentage = Double(batteryLevel)
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear() {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let batteryLevel = UIDevice.current.batteryLevel
            let batteryState = UIDevice.current.batteryState
            phoneState = batteryState.rawValue
            phonePercentage = Double(batteryLevel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
