import Foundation

import Testing


@Test func example() async throws {
    // https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server/issues/2504
    let cloneURL = "https://github.com/finestructure/swift-mmio"
    let ref = "issue-3374"
    let pathFragment = "finestructure/swift-mmio"
    try await generateDocs(cloneURL: cloneURL,
                           reference: ref) { tempDir in
        let docsDir = tempDir + "/checkout/.docs/\(pathFragment)/\(ref)"
        let indexJSON = "\(docsDir)/index/index.json".lowercased()
        #expect(FileManager.default.fileExists(atPath: indexJSON))
#warning("FIXME: convert these")
//        let index = #require(DocArchive.Index(path: indexJSON))
//        #expect(index.interfaceLanguages.swift.map(\.path) == [
//            "/documentation/svd2swift"
//        ])
//        let jsonFiles = try await Current.shell.run(command: .ls("\(docsDir)/data/documentation/svd2swift"))
//            .split(separator: "\n")
//            .sorted()
//        XCTAssertEqual(jsonFiles.count, 2)
//        XCTAssertEqual(jsonFiles, ["usingsvd2swift.json", "usingsvd2swiftplugin.json"])
    }
}


func generateDocs(cloneURL: String,
                  reference: String,
                  target: String? = nil,
                  validation: (String) async throws -> Void = { _ in },
                  file: StaticString = #filePath, line: UInt = #line) async throws {
    try await withTempDir { tempDir in
        let buildDir = tempDir.appending("/checkout")
        try await checkout(cloneURL: cloneURL, reference: reference, workDir: buildDir)

#warning("FIXME: convert these")
//        guard let docTargets = target.map({ [$0] }) ?? Manifest.load(in: buildDir)?
//            .documentationTargets(platform: platform, swiftVersion: swiftVersion) else {
//            XCTFail("no doc targets found", file: file, line: line)
//            return
//        }
//
//        let docsDirectory = try DocsDirectory(cloneURL: cloneURL,
//                                              reference: reference,
//                                              workDir: buildDir)
//        let sourceService = try SourceService(checkoutPath: buildDir, cloneURL: cloneURL, reference: reference)
//        try await Builder.GenerateDocs.run(docsDirectory: docsDirectory,
//                                           hostVolume: Builder.defaultHostVolume,
//                                           platform: platform,
//                                           sourceService: sourceService,
//                                           swiftVersion: swiftVersion,
//                                           targets: docTargets,
//                                           workDir: buildDir)
//        try await validation(tempDir)
    }
}


func checkout(cloneURL: String, reference: String, workDir: String) async throws {
    try await Shell.run(command: .mkdir(workDir))
    try await Shell.run(command: .git("init", "."), at: workDir)
    try await Shell.run(command: .git("remote", "add", "origin", URL(string: cloneURL)!.absoluteString), at: workDir)
    try await Shell.run(command: .git("fetch", "origin", "--depth=1", reference), at: workDir)
    try await Shell.run(command: .git("reset", "--hard", "FETCH_HEAD"), at: workDir)
    // make sure we initialise and update any submodules
    try await Shell.run(command: .gitSubmoduleUpdate(initializeIfNeeded: true, recursive: true, quiet: false), at: workDir)
}
