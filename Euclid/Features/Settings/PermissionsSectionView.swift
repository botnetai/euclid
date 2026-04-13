import ComposableArchitecture
import EuclidCore
import Inject
import SwiftUI

struct PermissionsSectionView: View {
	@ObserveInjection var inject
	@Bindable var store: StoreOf<SettingsFeature>
	let microphonePermission: PermissionStatus
	let accessibilityPermission: PermissionStatus
	let inputMonitoringPermission: PermissionStatus

	var body: some View {
		Section {
			VStack(alignment: .leading, spacing: 10) {
				Text("Grant the remaining permissions so Euclid can record, listen for your hotkey, and paste into the active app.")
					.font(.callout)
					.foregroundStyle(.secondary)
					.fixedSize(horizontal: false, vertical: true)

				Text("Euclid only listens while you hold the hotkey.")
					.font(.caption)
					.foregroundStyle(.green)

				PermissionChecklistRow(
					icon: "mic.fill",
					iconColor: .orange,
					title: "Microphone",
					subtitle: microphoneSubtitle,
					status: microphonePermission,
					primaryAction: microphonePrimaryAction
				)

				PermissionChecklistRow(
					icon: "accessibility",
					iconColor: .orange,
					title: "Accessibility",
					subtitle: accessibilitySubtitle,
					status: accessibilityPermission,
					primaryAction: accessibilityPrimaryAction,
					secondaryAction: openAccessibilitySettingsAction
				)

				PermissionChecklistRow(
					icon: "keyboard",
					iconColor: .orange,
					title: "Input Monitoring",
					subtitle: inputMonitoringSubtitle,
					status: inputMonitoringPermission,
					primaryAction: inputMonitoringPrimaryAction,
					secondaryAction: openInputMonitoringSettingsAction
				)
			}
		} header: {
			Text("Permissions")
		}
		.enableInjection()
	}

	private var microphoneSubtitle: String? {
		guard microphonePermission != .granted else { return nil }
		if microphonePermission == .denied {
			return "Enable Euclid in System Settings to record"
		}
		return "Used only while you are recording"
	}

	private var accessibilitySubtitle: String? {
		guard accessibilityPermission != .granted else { return nil }
		if accessibilityPermission == .denied {
			return "Grant the prompt, then enable Euclid in Privacy & Security"
		}
		return "Lets Euclid paste back into the active app"
	}

	private var inputMonitoringSubtitle: String? {
		guard inputMonitoringPermission != .granted else { return nil }
		if inputMonitoringPermission == .denied {
			return "Retry the prompt, then enable Euclid in Privacy & Security"
		}
		return "Required for your global hotkey"
	}

	private var microphonePrimaryAction: PermissionChecklistAction? {
		guard microphonePermission != .granted else { return nil }
		if microphonePermission == .denied {
			return PermissionChecklistAction(
				title: "Open Settings",
				style: .primary,
				action: { store.send(.openMicrophoneSettings) }
			)
		}
		return PermissionChecklistAction(
			title: "Grant",
			style: .primary,
			action: { store.send(.requestMicrophone) }
		)
	}

	private var accessibilityPrimaryAction: PermissionChecklistAction? {
		guard accessibilityPermission != .granted else { return nil }
		return PermissionChecklistAction(
			title: accessibilityPermission == .denied ? "Retry Prompt" : "Grant",
			style: .primary,
			action: { store.send(.requestAccessibility) }
		)
	}

	private var inputMonitoringPrimaryAction: PermissionChecklistAction? {
		guard inputMonitoringPermission != .granted else { return nil }
		return PermissionChecklistAction(
			title: inputMonitoringPermission == .denied ? "Retry Prompt" : "Grant",
			style: .primary,
			action: { store.send(.requestInputMonitoring) }
		)
	}

	private var openAccessibilitySettingsAction: PermissionChecklistAction? {
		guard accessibilityPermission != .granted else { return nil }
		return PermissionChecklistAction(
			title: "Open Settings",
			action: { store.send(.openAccessibilitySettings) }
		)
	}

	private var openInputMonitoringSettingsAction: PermissionChecklistAction? {
		guard inputMonitoringPermission != .granted else { return nil }
		return PermissionChecklistAction(
			title: "Open Settings",
			action: { store.send(.openInputMonitoringSettings) }
		)
	}
}
