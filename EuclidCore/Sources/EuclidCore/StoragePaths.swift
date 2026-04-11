import Foundation

public extension URL {
	static var euclidApplicationSupport: URL {
		get throws {
			let fm = FileManager.default
			let appSupport = try fm.url(
				for: .applicationSupportDirectory,
				in: .userDomainMask,
				appropriateFor: nil,
				create: true
			)
			let euclidDirectory = appSupport.appendingPathComponent("com.jjeremycai.Euclid", isDirectory: true)
			try fm.createDirectory(at: euclidDirectory, withIntermediateDirectories: true)
			return euclidDirectory
		}
	}

	static var legacyDocumentsDirectory: URL {
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
	}

	static func euclidMigratedFileURL(named fileName: String) -> URL {
		let newURL = (try? euclidApplicationSupport.appending(component: fileName))
			?? documentsDirectory.appending(component: fileName)
		let legacyURL = legacyDocumentsDirectory.appending(component: fileName)
		FileManager.default.migrateIfNeeded(from: legacyURL, to: newURL)
		return newURL
	}

	static var euclidModelsDirectory: URL {
		get throws {
			let modelsDirectory = try euclidApplicationSupport.appendingPathComponent("models", isDirectory: true)
			try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
			return modelsDirectory
		}
	}
}

public extension FileManager {
	func migrateIfNeeded(from legacy: URL, to new: URL) {
		guard fileExists(atPath: legacy.path), !fileExists(atPath: new.path) else { return }
		try? copyItem(at: legacy, to: new)
	}

	func removeItemIfExists(at url: URL) {
		guard fileExists(atPath: url.path) else { return }
		try? removeItem(at: url)
	}
}
