import Foundation

public struct VocabularyTerm: Codable, Equatable, Identifiable, Sendable {
	public var id: UUID
	public var isEnabled: Bool
	public var term: String

	public init(
		id: UUID = UUID(),
		isEnabled: Bool = true,
		term: String
	) {
		self.id = id
		self.isEnabled = isEnabled
		self.term = term
	}
}
