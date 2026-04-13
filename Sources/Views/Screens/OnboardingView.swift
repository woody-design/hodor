import SwiftUI

/// Permission onboarding — two states, no reactive state management.
/// State switching is done by AppDelegate replacing the rootView.
struct OnboardingView: View {
    let granted: Bool
    var onGetStarted: () -> Void = {}

    @AppStorage("recordingMode") private var recordingMode = false

    var body: some View {
        Group {
            if granted {
                grantedContent
            } else {
                requestingContent
            }
        }
        .frame(width: 440, height: 480)
    }

    // MARK: - Requesting

    private var requestingContent: some View {
        VStack(spacing: 32) {
            // Identity zone
            VStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)

                VStack(spacing: 8) {
                    Text("Hodor needs permission to\ninteract with other apps.")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("To paste your prompts, detect shortcuts, and respond to keywords — the same approach as Raycast and Alfred.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Action zone
            VStack(spacing: 16) {
                grantAccessButton

                VStack(spacing: 4) {
                    Text("Nothing is recorded or sent.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    Link("Read the source code \u{2192}", destination: URL(string: "https://github.com/woody-design/hodor")!)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Granted

    private var grantedContent: some View {
        VStack(spacing: 32) {
            // Info zone
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)

                VStack(spacing: 8) {
                    Text("You're all set.")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))

                    Text("Your prompts stay on your Mac.\nNo account, no cloud, no network.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button("Get Started", action: onGetStarted)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Components

    private var grantAccessButton: some View {
        Button("Grant Access", action: { PermissionService.shared.requestAccess() })
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
}

// MARK: - Previews

#Preview("Not Granted") {
    OnboardingView(granted: false)
}

#Preview("Granted") {
    OnboardingView(granted: true)
}
