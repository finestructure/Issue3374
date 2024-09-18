import Foundation


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
