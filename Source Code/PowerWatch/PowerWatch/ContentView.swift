//
//  ContentView.swift
//  PowerWatch
//
//  Created by Mark Howard on 02/08/2023.
//

import SwiftUI
import StoreKit
import MessageUI

struct ContentView: View {
    @StateObject private var batterySync = PhoneBatterySyncController.shared
    @State var showingSettings = false
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    @State private var isShowingMailView = false

    private var phonePercentage: Double { batterySync.phoneSnapshot.level }
    private var phoneState: Int { batterySync.phoneSnapshot.state }
    private var watchPercentage: Double { batterySync.watchSnapshot.level }
    private var watchState: Int { batterySync.watchSnapshot.state }

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
                                if (phonePercentage * 100) >= 21 {
                                    Text("\((phonePercentage * 100), specifier: "%.0f")%")
                                        .bold()
                                        .font(.title)
                                        .foregroundColor(.green)
                                } else if (phonePercentage * 100) >= 11 {
                                    Text("\((phonePercentage * 100), specifier: "%.0f")%")
                                        .bold()
                                        .font(.title)
                                        .foregroundColor(.orange)
                                } else if (phonePercentage * 100) <= 10 {
                                    Text("\((phonePercentage * 100), specifier: "%.0f")%")
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
                                        .foregroundColor(.green)
                                }
                                if phoneState == 3 {
                                    Text("Full")
                                        .bold()
                                        .font(.title)
                                        .foregroundColor(.accentColor)
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
                                if (watchPercentage * 100) >= 21 {
                                    Text("\((watchPercentage * 100), specifier: "%.0f")%")
                                        .bold()
                                        .font(.title)
                                        .foregroundColor(.green)
                                } else if (watchPercentage * 100) >= 11 {
                                    Text("\((watchPercentage * 100), specifier: "%.0f")%")
                                        .bold()
                                        .font(.title)
                                        .foregroundColor(.orange)
                                } else if (watchPercentage * 100) <= 10 {
                                    Text("\((watchPercentage * 100), specifier: "%.0f")%")
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
                                        .foregroundColor(.green)
                                }
                                if watchState == 3 {
                                    Text("Full")
                                        .bold()
                                        .font(.title)
                                        .foregroundColor(.accentColor)
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
                        batterySync.refreshAll()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                    .sheet(isPresented: $showingSettings) {
                        settings
                    }
                }
            }
        }
        .onAppear {
            batterySync.refreshAll()
        }
    }

    var settings: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Version", value: "\(Bundle.main.releaseVersionNumber ?? "N/A")")
                    LabeledContent("Build", value: "\(Bundle.main.buildVersionNumber ?? "N/A")")
                } header: {
                    Label("Info", systemImage: "info.circle")
                }
                Section {
                    Link("GitHub Repository", destination: URL(string: "https://github.com/markydoodled/PowerWatch")!)
                    Link("Portfolio", destination: URL(string: "http://markydoodled.com/")!)
                    Button(action: { isShowingMailView.toggle() }) {
                        Text("Send Feedback...")
                    }
                    .sheet(isPresented: $isShowingMailView) {
                        MailView(isShowing: self.$isShowingMailView, result: self.$result)
                    }
                } header: {
                    Label("Contact", systemImage: "person.crop.circle")
                }
                Section {
                    NavigationLink(destination: tipsJar) {
                        Text("Tip Jar")
                    }
                } footer: {
                    Text("© 2026 Mark Howard")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        showingSettings = false
                    }
                }
            }
        }
    }

    var tipsJar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("If You Like This App And Want To Support Me And My Work, Please Consider A Tip!")
                    .padding()
                ForEach(TipJars.allCases) { tip in
                    ProductView(id: tip.id) {
                        Image(tip.imageName)
                            .resizable()
                            .scaledToFit()
                    }
                    .onInAppPurchaseStart { product in
                        print("User Has Started Buying \(product.id)")
                    }
                    .onInAppPurchaseCompletion { product, result in
                        switch result {
                        case .success(let purchaseResult):
                            switch purchaseResult {
                            case .success(let verificationResult):
                                switch verificationResult {
                                case .verified(let transaction):
                                    print("Purchase Verified")
                                    await transaction.finish()
                                case .unverified(let transaction, let verificationError):
                                    print("Purchase Unverified \(verificationError), \(transaction)")
                                }
                            case .pending:
                                print("Purchase Pending")
                            case .userCancelled:
                                print("Purchase Cancelled")
                            @unknown default:
                                print("Unknown Break")
                            }
                        case .failure(let error):
                            print("Purchase Failure \(error)")
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Tip Jar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension Bundle {
    var buildVersionNumber: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }

    var releaseVersionNumber: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

enum TipJars: Identifiable, CaseIterable {
    case small
    case medium
    case large

    var id: String {
        switch self {
        case .small:
            return "powerwatch_small_tip"
        case .medium:
            return "powerwatch_medium_tip"
        case .large:
            return "powerwatch_large_tip"
        }
    }

    var imageName: String {
        switch self {
        case .small:
            return "smalltip"
        case .medium:
            return "mediumtip"
        case .large:
            return "largetip"
        }
    }
}

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(isShowing: Binding<Bool>, result: Binding<Result<MFMailComposeResult, Error>?>) {
            _isShowing = isShowing
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                isShowing = false
            }

            guard let error else {
                self.result = .success(result)
                return
            }

            self.result = .failure(error)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isShowing: $isShowing, result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject("PowerWatch Feedback")
        vc.setToRecipients(["markhoward@markydoodled.com"])
        vc.setMessageBody("Please Fill Out All Relevant Sections:\nReport A Bug - \nRate The App - \nSuggest An Improvement - \n", isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {}
}

#Preview {
    ContentView()
}
