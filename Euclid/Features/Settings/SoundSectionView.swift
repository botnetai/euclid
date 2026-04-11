import ComposableArchitecture
import EuclidCore
import Inject
import SwiftUI

struct SoundSectionView: View {
	@ObserveInjection var inject
	@Bindable var store: StoreOf<SettingsFeature>

	var body: some View {
		let sliderBinding = Binding<Double>(
			get: { volumePercentage(for: store.euclidSettings.soundEffectsVolume) },
			set: { store.send(.setSoundEffectsVolume(actualVolume(fromPercentage: $0))) }
		)

		return Section {
			Label {
				Toggle(
					"Sound Effects",
					isOn: Binding(
						get: { store.euclidSettings.soundEffectsEnabled },
						set: { store.send(.setSoundEffectsEnabled($0)) }
					)
				)
			} icon: {
				Image(systemName: "speaker.wave.2.fill")
			}

			VStack(alignment: .leading, spacing: 8) {
				HStack {
					Text("Volume")
					Spacer()
					Text(formattedVolume(for: store.euclidSettings.soundEffectsVolume))
						.foregroundStyle(.secondary)
						.monospacedDigit()
				}
				Slider(value: sliderBinding, in: 0...1)
					.disabled(!store.euclidSettings.soundEffectsEnabled)
			}
		} header: {
			Text("Sound")
		}
		.enableInjection()
	}
}

private func formattedVolume(for actualVolume: Double) -> String {
	let percent = volumePercentage(for: actualVolume)
	return "\(Int(round(percent * 100)))%"
}

private func volumePercentage(for actualVolume: Double) -> Double {
	guard EuclidSettings.baseSoundEffectsVolume > 0 else { return 0 }
	let ratio = actualVolume / EuclidSettings.baseSoundEffectsVolume
	return max(0, min(1, ratio))
}

private func actualVolume(fromPercentage percentage: Double) -> Double {
	let clampedPercentage = max(0, min(1, percentage))
	return clampedPercentage * EuclidSettings.baseSoundEffectsVolume
}
