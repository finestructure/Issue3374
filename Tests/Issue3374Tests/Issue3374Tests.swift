import Foundation

import Testing


@Test func issue3374() async throws {
    // https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server/issues/2504
    let cloneURL = "https://github.com/finestructure/swift-mmio"
    let ref = "issue-3374"
    let pathFragment = "finestructure/swift-mmio"
    try await testGenerateDocs(cloneURL: cloneURL,
                               repository: .init(owner: "finestructure", name: "swift-mmio"),
                               reference: ref,
                               target: "SVD2Swift") { tempDir in
        let docsDir = tempDir + "/checkout/.docs/\(pathFragment)/\(ref)"
        let indexJSON = "\(docsDir)/index/index.json".lowercased()
        #expect(FileManager.default.fileExists(atPath: indexJSON))
        let index = try #require(DocArchive.Index(path: indexJSON))
        #expect(index.interfaceLanguages.swift.map(\.path) == [
            "/documentation/svd2swift"
        ])
        let jsonFiles = try await Shell.run(command: .ls("\(docsDir)/data/documentation/svd2swift"))
            .split(separator: "\n")
            .sorted()
        #expect(jsonFiles.count == 2)
        #expect(jsonFiles == ["usingsvd2swift.json", "usingsvd2swiftplugin.json"])
    }
}


func testGenerateDocs(cloneURL: String,
                      repository: Github.Repository,
                      reference: String,
                      target: String,
                      validation: (String) async throws -> Void = { _ in },
                      file: StaticString = #filePath, line: UInt = #line) async throws {
    try await withTempDir { tempDir in
        let buildDir = tempDir.appending("/checkout")
        try await Builder.checkout(cloneURL: cloneURL, reference: reference, workDir: buildDir)

        let docsDirectory = DocsDirectory(repository: repository, reference: reference, workDir: buildDir)
        try await Builder.generateDocs(docsDirectory: docsDirectory, target: target, workDir: buildDir)

        try await validation(tempDir)
    }
}
