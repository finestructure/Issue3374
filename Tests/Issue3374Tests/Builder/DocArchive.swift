import Foundation


public struct DocArchive: Codable, Equatable {
    public var name: String
    public var title: String

    public init(name: String, title: String) {
        self.name = name
        self.title = title
    }
}


extension DocArchive {
    struct Index: Codable, Equatable {
        var interfaceLanguages: Language
        var schemaVersion: Version

        struct Language: Codable, Equatable {
            var swift: [Child]

            struct Child: Codable, Equatable {
                var children: [Child]?
                var path: String?
                var title: String
                var type: String
            }
        }

        struct Version: Codable, Equatable {
            var major: Int
            var minor: Int
            var patch: Int
        }
    }
}


extension DocArchive.Index {
    init?(path: String) {
        guard let data = FileManager.default.contents(atPath: path),
              let index = try? JSONDecoder().decode(DocArchive.Index.self, from: data)
        else { return nil }
        self = index
    }
}
