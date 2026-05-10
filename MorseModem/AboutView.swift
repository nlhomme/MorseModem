//
//  AboutView.swift
//  MorseModem
//

import SwiftUI

struct AboutView: View {
    @ScaledMetric private var iconSize: CGFloat = 60

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: iconSize))
                        .foregroundStyle(.tint)

                    Text("MorseModem")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(String(localized: "Version \(appVersion) (\(buildNumber))"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section(String(localized: "Developer")) {
                Label("Nicolas Lhomme", systemImage: "person")

                // TODO: Replace with your actual website URL
                Link(destination: URL(string: "https://nicolas.lhomme.xyz")!) {
                    Label(String(localized: "Website"), systemImage: "globe")
                }

                // TODO: Replace with your actual email
                Link(destination: URL(string: "mailto:contact+morsemodem@lhomme.xyz")!) {
                    Label(String(localized: "Contact"), systemImage: "envelope")
                }
            }

            Section(String(localized: "Legal")) {
                // TODO: Replace with your actual Privacy Policy URL
                Link(destination: URL(string: "https://morsemodem.lhomme.xyz/privacy.html")!) {
                    Label(String(localized: "Privacy Policy"), systemImage: "lock.shield")
                }
            }

            Section(String(localized: "Acknowledgements")) {
                Text("Thank you to all the open-source contributors and the Swift community for making this project possible.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(String(localized: "About"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
