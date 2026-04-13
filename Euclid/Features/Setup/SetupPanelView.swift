import ComposableArchitecture
import EuclidCore
import SwiftUI

struct SetupPanelView: View {
    let store: StoreOf<AppFeature>
    var onDismiss: () -> Void = {}
    var onSetupComplete: () -> Void = {}

    private var allGranted: Bool {
        store.microphonePermission == .granted
            && store.accessibilityPermission == .granted
            && store.inputMonitoringPermission == .granted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            HStack(spacing: 8) {
                Circle()
                    .fill(allGranted ? .green : .orange)
                    .frame(width: 8, height: 8)

                Text("Euclid")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("Setup")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // MARK: - Intro
            introSection
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // MARK: - Permissions
            VStack(alignment: .leading, spacing: 0) {
                Text("PERMISSIONS")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                VStack(spacing: 8) {
                    PermissionChecklistRow(
                        icon: "mic.fill",
                        iconColor: .orange,
                        title: "Microphone",
                        subtitle: microphoneSubtitle,
                        status: store.microphonePermission,
                        primaryAction: microphonePrimaryAction
                    )

                    PermissionChecklistRow(
                        icon: "accessibility",
                        iconColor: .orange,
                        title: "Accessibility",
                        subtitle: accessibilitySubtitle,
                        status: store.accessibilityPermission,
                        primaryAction: accessibilityPrimaryAction,
                        secondaryAction: openAccessibilitySettingsAction
                    )

                    PermissionChecklistRow(
                        icon: "keyboard",
                        iconColor: .orange,
                        title: "Input Monitoring",
                        subtitle: inputMonitoringSubtitle,
                        status: store.inputMonitoringPermission,
                        primaryAction: inputMonitoringPrimaryAction,
                        secondaryAction: openInputMonitoringSettingsAction
                    )
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)

            // MARK: - Quit
            Divider()
                .padding(.horizontal, 16)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                    Text("Quit Euclid")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: allGranted) { _, granted in
            if granted {
                onSetupComplete()
            }
        }
    }

    @ViewBuilder
    private var introSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(allGranted ? "You're all set." : "Grant the three permissions below.")
                .font(.body.weight(.semibold))

            Text("Euclid lives in your menu bar. Hold the hotkey, speak, and your transcript appears where you're typing.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Euclid only listens while you're recording. Nothing runs in the background.")
                .font(.callout)
                .foregroundStyle(.green)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var microphoneSubtitle: String? {
        guard store.microphonePermission != .granted else { return nil }
        if store.microphonePermission == .denied {
            return "Enable Euclid in System Settings to record"
        }
        return "Used only while you are recording"
    }

    private var accessibilitySubtitle: String? {
        guard store.accessibilityPermission != .granted else { return nil }
        if store.accessibilityPermission == .denied {
            return "Enable Euclid in Privacy & Security after the prompt"
        }
        return "Lets Euclid paste back into the active app"
    }

    private var inputMonitoringSubtitle: String? {
        guard store.inputMonitoringPermission != .granted else { return nil }
        if store.inputMonitoringPermission == .denied {
            return "Retry the prompt, then enable Euclid in System Settings"
        }
        return "Required for your global hotkey"
    }

    private var microphonePrimaryAction: PermissionChecklistAction? {
        guard store.microphonePermission != .granted else { return nil }
        if store.microphonePermission == .denied {
            return PermissionChecklistAction(
                title: "Open Settings",
                style: .primary,
                action: { store.send(.settings(.openMicrophoneSettings)) }
            )
        }
        return PermissionChecklistAction(
            title: "Grant",
            style: .primary,
            action: { store.send(.requestMicrophone) }
        )
    }

    private var accessibilityPrimaryAction: PermissionChecklistAction? {
        guard store.accessibilityPermission != .granted else { return nil }
        return PermissionChecklistAction(
            title: store.accessibilityPermission == .denied ? "Retry Prompt" : "Grant",
            style: .primary,
            action: { store.send(.requestAccessibility) }
        )
    }

    private var inputMonitoringPrimaryAction: PermissionChecklistAction? {
        guard store.inputMonitoringPermission != .granted else { return nil }
        return PermissionChecklistAction(
            title: store.inputMonitoringPermission == .denied ? "Retry Prompt" : "Grant",
            style: .primary,
            action: { store.send(.requestInputMonitoring) }
        )
    }

    private var openAccessibilitySettingsAction: PermissionChecklistAction? {
        guard store.accessibilityPermission != .granted else { return nil }
        return PermissionChecklistAction(
            title: "Open Settings",
            action: { store.send(.settings(.openAccessibilitySettings)) }
        )
    }

    private var openInputMonitoringSettingsAction: PermissionChecklistAction? {
        guard store.inputMonitoringPermission != .granted else { return nil }
        return PermissionChecklistAction(
            title: "Open Settings",
            action: { store.send(.settings(.openInputMonitoringSettings)) }
        )
    }
}
