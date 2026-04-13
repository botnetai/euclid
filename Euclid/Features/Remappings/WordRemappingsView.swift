import ComposableArchitecture
import EuclidCore
import Inject
import SwiftUI

struct WordRemappingsView: View {
	@ObserveInjection var inject
	@Bindable var store: StoreOf<SettingsFeature>
	let isRecording: Bool
	let isTranscribing: Bool
	let onRecordSample: () -> Void
	@FocusState private var isScratchpadFocused: Bool

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				VStack(alignment: .leading, spacing: 6) {
					Text("Dictionary")
						.font(.title2.bold())
					Text("Map phrases, remove filler words, and bias preferred spellings during transcription.")
						.font(.callout)
						.foregroundStyle(.secondary)
				}

				GroupBox {
					VStack(alignment: .leading, spacing: 10) {
						HStack(alignment: .bottom, spacing: 12) {
							VStack(alignment: .leading, spacing: 4) {
								Text("Sample")
									.font(.caption.weight(.semibold))
									.foregroundStyle(.secondary)
								TextField("Say something…", text: $store.remappingScratchpadText)
									.textFieldStyle(.roundedBorder)
									.focused($isScratchpadFocused)
									.onChange(of: isScratchpadFocused) { _, newValue in
										store.send(.setRemappingScratchpadFocused(newValue))
									}
							}

							Button {
								isScratchpadFocused = true
								store.send(.setRemappingScratchpadFocused(true))
								onRecordSample()
							} label: {
								Label(
									isRecording ? "Stop" : "Record",
									systemImage: isRecording ? "stop.circle.fill" : "mic.circle.fill"
								)
							}
							.buttonStyle(.borderedProminent)
							.disabled(isTranscribing && !isRecording)
						}

						VStack(alignment: .leading, spacing: 4) {
							Text("Preview")
								.font(.caption.weight(.semibold))
								.foregroundStyle(.secondary)
							Text(previewText.isEmpty ? "—" : previewText)
								.font(.body)
								.frame(maxWidth: .infinity, alignment: .leading)
								.padding(.horizontal, 8)
								.padding(.vertical, 6)
								.background(
									RoundedRectangle(cornerRadius: 6)
										.fill(Color(nsColor: .controlBackgroundColor))
								)
						}
					}
					.padding(.vertical, 6)
				}

				remappingsSection
				removalsSection
				vocabularySection
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding()
		}
		.onDisappear {
			store.send(.setRemappingScratchpadFocused(false))
		}
		.enableInjection()
	}

	private var removalsSection: some View {
		GroupBox {
			VStack(alignment: .leading, spacing: 10) {
				Toggle(
					"Enable Word Removals",
					isOn: Binding(
						get: { store.euclidSettings.wordRemovalsEnabled },
						set: { store.send(.setWordRemovalsEnabled($0)) }
					)
				)
					.toggleStyle(.checkbox)

				removalsColumnHeaders

				LazyVStack(alignment: .leading, spacing: 6) {
					ForEach(store.euclidSettings.wordRemovals) { removal in
						if let removalBinding = removalBinding(for: removal.id) {
							RemovalRow(removal: removalBinding) {
								store.send(.removeWordRemoval(removal.id))
							}
						}
					}
				}

				HStack {
					Button {
						store.send(.addWordRemoval)
					} label: {
						Label("Add Removal", systemImage: "plus")
					}
					Spacer()
				}
			}
			.padding(.vertical, 4)
		} label: {
			VStack(alignment: .leading, spacing: 4) {
				Text("Removals")
					.font(.headline)
				Text("Remove filler words using case-insensitive regex patterns.")
					.settingsCaption()
			}
		}
	}

	private var remappingsSection: some View {
		GroupBox {
			VStack(alignment: .leading, spacing: 10) {
				remappingsColumnHeaders

				LazyVStack(alignment: .leading, spacing: 6) {
					ForEach(store.euclidSettings.wordRemappings) { remapping in
						if let remappingBinding = remappingBinding(for: remapping.id) {
							RemappingRow(remapping: remappingBinding) {
								store.send(.removeWordRemapping(remapping.id))
							}
						}
					}
				}

				HStack {
					Button {
						store.send(.addWordRemapping)
					} label: {
						Label("Add Mapping", systemImage: "plus")
					}
					Spacer()
				}
			}
			.padding(.vertical, 4)
		} label: {
			VStack(alignment: .leading, spacing: 4) {
				Text("Mappings")
					.font(.headline)
				Text("Replace specific words in every transcript. Matches whole words, case-insensitive, in order.")
					.settingsCaption()
			}
		}
	}

	private var vocabularySection: some View {
		GroupBox {
			VStack(alignment: .leading, spacing: 10) {
				vocabularyColumnHeaders

				LazyVStack(alignment: .leading, spacing: 6) {
					ForEach(store.euclidSettings.vocabularyTerms) { term in
						if let vocabularyBinding = vocabularyBinding(for: term.id) {
							VocabularyRow(vocabularyTerm: vocabularyBinding) {
								store.send(.removeVocabularyTerm(term.id))
							}
						}
					}
				}

				HStack {
					Button {
						store.send(.addVocabularyTerm)
					} label: {
						Label("Add Term", systemImage: "plus")
					}
					Spacer()
				}
			}
			.padding(.vertical, 4)
		} label: {
			VStack(alignment: .leading, spacing: 4) {
				Text("Vocabulary")
					.font(.headline)
				Text("Bias preferred spellings during transcription on supported models.")
					.settingsCaption()
			}
		}
	}

	private var removalsColumnHeaders: some View {
		HStack(spacing: 8) {
			Text("On")
				.frame(width: Layout.toggleColumnWidth, alignment: .leading)
			Text("Pattern")
				.frame(maxWidth: .infinity, alignment: .leading)
			Spacer().frame(width: Layout.deleteColumnWidth)
		}
		.font(.caption)
		.foregroundStyle(.secondary)
		.padding(.horizontal, Layout.rowHorizontalPadding)
	}

	private var remappingsColumnHeaders: some View {
		HStack(spacing: 8) {
			Text("On")
				.frame(width: Layout.toggleColumnWidth, alignment: .leading)
			Text("Match")
				.frame(maxWidth: .infinity, alignment: .leading)
			Image(systemName: "arrow.right")
				.font(.caption)
				.foregroundStyle(.secondary)
				.frame(width: Layout.arrowColumnWidth)
			Text("Replace")
				.frame(maxWidth: .infinity, alignment: .leading)
			Spacer().frame(width: Layout.deleteColumnWidth)
		}
		.font(.caption)
		.foregroundStyle(.secondary)
		.padding(.horizontal, Layout.rowHorizontalPadding)
	}

	private var vocabularyColumnHeaders: some View {
		HStack(spacing: 8) {
			Text("On")
				.frame(width: Layout.toggleColumnWidth, alignment: .leading)
			Text("Term")
				.frame(maxWidth: .infinity, alignment: .leading)
			Spacer().frame(width: Layout.deleteColumnWidth)
		}
		.font(.caption)
		.foregroundStyle(.secondary)
		.padding(.horizontal, Layout.rowHorizontalPadding)
	}

	private func removalBinding(for id: UUID) -> Binding<WordRemoval>? {
		guard let index = store.euclidSettings.wordRemovals.firstIndex(where: { $0.id == id }) else {
			return nil
		}
		return Binding(
			get: { store.euclidSettings.wordRemovals[index] },
			set: { store.send(.updateWordRemoval($0)) }
		)
	}

	private func remappingBinding(for id: UUID) -> Binding<WordRemapping>? {
		guard let index = store.euclidSettings.wordRemappings.firstIndex(where: { $0.id == id }) else {
			return nil
		}
		return Binding(
			get: { store.euclidSettings.wordRemappings[index] },
			set: { store.send(.updateWordRemapping($0)) }
		)
	}

	private func vocabularyBinding(for id: UUID) -> Binding<VocabularyTerm>? {
		guard let index = store.euclidSettings.vocabularyTerms.firstIndex(where: { $0.id == id }) else {
			return nil
		}
		return Binding(
			get: { store.euclidSettings.vocabularyTerms[index] },
			set: { store.send(.updateVocabularyTerm($0)) }
		)
	}

	private var previewText: String {
		var output = store.remappingScratchpadText
		if store.euclidSettings.wordRemovalsEnabled {
			output = WordRemovalApplier.apply(output, removals: store.euclidSettings.wordRemovals)
		}
		output = WordRemappingApplier.apply(output, remappings: store.euclidSettings.wordRemappings)
		return output
	}
}

private struct RemovalRow: View {
	@Binding var removal: WordRemoval
	var onDelete: () -> Void

	var body: some View {
		HStack(spacing: 8) {
			Toggle("", isOn: $removal.isEnabled)
				.labelsHidden()
				.toggleStyle(.checkbox)
				.frame(width: Layout.toggleColumnWidth, alignment: .leading)

			TextField("Regex Pattern", text: $removal.pattern)
				.textFieldStyle(.roundedBorder)

			Button(role: .destructive, action: onDelete) {
				Image(systemName: "trash")
			}
			.buttonStyle(.borderless)
			.frame(width: Layout.deleteColumnWidth)
		}
		.padding(.horizontal, Layout.rowHorizontalPadding)
		.padding(.vertical, Layout.rowVerticalPadding)
		.frame(maxWidth: .infinity)
		.background(
			RoundedRectangle(cornerRadius: Layout.rowCornerRadius)
				.fill(Color(nsColor: .controlBackgroundColor))
		)
	}
}

private struct RemappingRow: View {
	@Binding var remapping: WordRemapping
	var onDelete: () -> Void

	var body: some View {
		HStack(spacing: 8) {
			Toggle("", isOn: $remapping.isEnabled)
				.labelsHidden()
				.toggleStyle(.checkbox)
				.frame(width: Layout.toggleColumnWidth, alignment: .leading)

			TextField("Match", text: $remapping.match)
				.textFieldStyle(.roundedBorder)
				.frame(maxWidth: .infinity, alignment: .leading)

			Image(systemName: "arrow.right")
				.foregroundStyle(.secondary)
				.frame(width: Layout.arrowColumnWidth)

			TextField("Replace", text: $remapping.replacement)
				.textFieldStyle(.roundedBorder)
				.frame(maxWidth: .infinity, alignment: .leading)

			Button(role: .destructive, action: onDelete) {
				Image(systemName: "trash")
			}
			.buttonStyle(.borderless)
			.frame(width: Layout.deleteColumnWidth)
		}
		.padding(.horizontal, Layout.rowHorizontalPadding)
		.padding(.vertical, Layout.rowVerticalPadding)
		.frame(maxWidth: .infinity)
		.background(
			RoundedRectangle(cornerRadius: Layout.rowCornerRadius)
				.fill(Color(nsColor: .controlBackgroundColor))
		)
	}
}

private struct VocabularyRow: View {
	@Binding var vocabularyTerm: VocabularyTerm
	var onDelete: () -> Void

	var body: some View {
		HStack(spacing: 8) {
			Toggle("", isOn: $vocabularyTerm.isEnabled)
				.labelsHidden()
				.toggleStyle(.checkbox)
				.frame(width: Layout.toggleColumnWidth, alignment: .leading)

			TextField("Preferred spelling", text: $vocabularyTerm.term)
				.textFieldStyle(.roundedBorder)

			Button(role: .destructive, action: onDelete) {
				Image(systemName: "trash")
			}
			.buttonStyle(.borderless)
			.frame(width: Layout.deleteColumnWidth)
		}
		.padding(.horizontal, Layout.rowHorizontalPadding)
		.padding(.vertical, Layout.rowVerticalPadding)
		.frame(maxWidth: .infinity)
		.background(
			RoundedRectangle(cornerRadius: Layout.rowCornerRadius)
				.fill(Color(nsColor: .controlBackgroundColor))
		)
	}
}

private enum Layout {
	static let toggleColumnWidth: CGFloat = 24
	static let deleteColumnWidth: CGFloat = 24
	static let arrowColumnWidth: CGFloat = 16
	static let rowHorizontalPadding: CGFloat = 10
	static let rowVerticalPadding: CGFloat = 6
	static let rowCornerRadius: CGFloat = 8
}
