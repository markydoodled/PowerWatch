//
//  ContentView.swift
//  PowerWatch watchOS Watch App
//
//  Created by Mark Howard on 04/08/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager

    private var phonePercentage: Double { sessionManager.phoneSnapshot.level }
    private var phoneState: Int { sessionManager.phoneSnapshot.state }
    private var watchPercentage: Double { sessionManager.watchSnapshot.level }
    private var watchState: Int { sessionManager.watchSnapshot.state }

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
                                if (phonePercentage * 100) >= 21 {
                                    Text("\((phonePercentage * 100), specifier: "%.0f")%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.green)
                                } else if (phonePercentage * 100) >= 11 {
                                    Text("\((phonePercentage * 100), specifier: "%.0f")%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                } else if (phonePercentage * 100) <= 10 {
                                    Text("\((phonePercentage * 100), specifier: "%.0f")%")
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
                                        .foregroundColor(.green)
                                }
                                if phoneState == 3 {
                                    Text("Full")
                                        .bold()
                                        .foregroundColor(.accentColor)
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
                                if (watchPercentage * 100) >= 21 {
                                    Text("\((watchPercentage * 100), specifier: "%.0f")%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.green)
                                } else if (watchPercentage * 100) >= 11 {
                                    Text("\((watchPercentage * 100), specifier: "%.0f")%")
                                        .bold()
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                } else if (watchPercentage * 100) <= 10 {
                                    Text("\((watchPercentage * 100), specifier: "%.0f")%")
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
                                        .foregroundColor(.green)
                                }
                                if watchState == 3 {
                                    Text("Full")
                                        .bold()
                                        .foregroundColor(.accentColor)
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
                }
            }
            .navigationTitle("PowerWatch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        sessionManager.refreshAll()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            sessionManager.refreshAll()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSessionManager.shared)
}
