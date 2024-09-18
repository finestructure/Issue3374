struct DocsDirectory {
    var hostingBasePath: String
    var reference: String
    var relativeOutputPath: String
    var repository: Github.Repository
    var workDir: String

    static let directoryName = ".docs"

    init(repository: Github.Repository, reference: String, workDir: String) {
        self.reference = reference
        self.repository = repository
        self.hostingBasePath = (repository.path + "/" + reference.pathEncoded).lowercased()
        self.relativeOutputPath = Self.directoryName + "/" + hostingBasePath
        self.workDir = workDir
    }

    var outputPath: String {
        workDir + "/" + relativeOutputPath
    }

    var s3Path: String { hostingBasePath }

    var themeSettingsPath: String {
        outputPath + "/theme-settings.json"
    }
}
