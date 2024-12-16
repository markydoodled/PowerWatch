//
//  ContentView.swift
//  PowerWatch
//
//  Created by Mark Howard on 02/08/2023.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State var phonePercentage = 0.0
    @State var phoneState = 0
    @State var watchPercentage = 0.0
    @State var watchState = 0
    @StateObject var viewModel = WatchConnectivityViewModel()
    @State var showingSettings = false
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIDevice.current.isBatteryMonitoringEnabled = true
                        let batteryLevel = UIDevice.current.batteryLevel
                        let batteryState = UIDevice.current.batteryState
                        phoneState = batteryState.rawValue
                        phonePercentage = Double(batteryLevel)
                        viewModel.sendMessageToWatch()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {showingSettings = true}) {
                        Image(systemName: "gearshape")
                    }
                    .sheet(isPresented: $showingSettings) {
                        settings
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
    var settings: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "1")
                } header: {
                    Label("Info", systemImage: "info.circle")
                }
                Section {
                    Link("GitHub Repository", destination: URL(string: "https://github.com/markydoodled/PowerWatch")!)
                    Link("Portfolio", destination: URL(string: "http://markydoodled.com/")!)
                } header: {
                    Label("Contact", systemImage: "person.crop.circle")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {showingSettings = false}) {
                        Text("Done")
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
