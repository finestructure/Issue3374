import Foundation

import Testing


@Test func example() async throws {
    // https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server/issues/2504
    let cloneURL = "https://github.com/finestructure/swift-mmio"
    let ref = "issue-3374"
    let pathFragment = "finestructure/swift-mmio"
    try await generateDocs(cloneURL: cloneURL,
                           repository: .init(owner: "finestructure", name: "swift-mmio"),
                           reference: ref,
                           target: "SVD2Swift") { tempDir in
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
                  repository: Github.Repository,
                  reference: String,
                  target: String,
                  validation: (String) async throws -> Void = { _ in },
                  file: StaticString = #filePath, line: UInt = #line) async throws {
    try await withTempDir { tempDir in
        let buildDir = tempDir.appending("/checkout")
        try await Builder.checkout(cloneURL: cloneURL, reference: reference, workDir: buildDir)

        let docsDirectory = DocsDirectory(repository: repository,
                                          reference: reference,
                                          workDir: buildDir)
        try await Builder.generateDocs(docsDirectory: docsDirectory, target: target, workDir: buildDir)
        try await validation(tempDir)
    }
}


enum Builder {
    static func checkout(cloneURL: String, reference: String, workDir: String) async throws {
        try await Shell.run(command: .mkdir(workDir))
        try await Shell.run(command: .git("init", "."), at: workDir)
        try await Shell.run(command: .git("remote", "add", "origin", URL(string: cloneURL)!.absoluteString), at: workDir)
        try await Shell.run(command: .git("fetch", "origin", "--depth=1", reference), at: workDir)
        try await Shell.run(command: .git("reset", "--hard", "FETCH_HEAD"), at: workDir)
        // make sure we initialise and update any submodules
        try await Shell.run(command: .gitSubmoduleUpdate(initializeIfNeeded: true, recursive: true, quiet: false), at: workDir)
    }


    static func generateDocs(docsDirectory: DocsDirectory, target: String, workDir: String) async throws {
        let docsPath = workDir + "/" + DocsDirectory.directoryName
        do {  // (Re-)create output path directory
            if FileManager.default.fileExists(atPath: docsPath) {
                try FileManager.default.removeItem(atPath: docsPath)
                precondition(!FileManager.default.fileExists(atPath: docsPath), "Working directory must be removed")
            }
            try FileManager.default.createDirectory(atPath: docsDirectory.outputPath,
                                                    withIntermediateDirectories: true)
        }

        try await Shell.run(command: PackageSwift.appendDoccPlugin(version: "1.0.0"), at: workDir)

        // hard-coding some values here
        let customParameters = ["--symbol-graph-minimum-access-level public",
                                "--verbose"]
        try await Shell.run(
            command: .xcrun(.spmGenerateDocs(target: target,
                                             hostingBasePath: docsDirectory.hostingBasePath,
                                             outputPath: docsDirectory.relativeOutputPath,
                                             customParameters: customParameters)),
            at: workDir,
            environment: .generateDocs
        )

    }
}

extension [String] {
    static func spmGenerateDocs(target: String,
                                hostingBasePath: String,
                                outputPath: String,
                                customParameters: [String] = []) -> Self {
        [
            "swift", "package",
            "--allow-writing-to-directory",
            outputPath,
            "generate-documentation",
            "--emit-digest",
            "--disable-indexing",
            "--output-path", outputPath,
            "--hosting-base-path", hostingBasePath,
            "--target", target,
        ]
        + customParameters
    }
}


extension Dictionary<String, String> {
    static let build = ["SPI_BUILD": "1"]
    static let generateDocs = ["SPI_GENERATE_DOCS": "1"]
}
