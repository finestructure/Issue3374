import Foundation

import ShellOut


enum Shell {
    enum Error: Swift.Error {
        case shellCommandFailed(String, path: String, stdout: String, stderr: String)
    }

    @discardableResult
    static func run(command: ShellOutCommand,
                    at path: String = ".",
                    environment: [String: String] = [:]) async throws -> String {
        let filteredEnvironment = ProcessInfo.processInfo.environment
            .filter { allowedEnvVariables.contains($0.key) }
            .merging(environment, uniquingKeysWith: { _, last in last })
            .merging( ["SPI_BUILDER": "1"], uniquingKeysWith: { _, last in last } )

        do {
            print("🖥️ \(command)")
            let (stdout, _) = try await ShellOut.shellOut(to: command, at: path, environment: filteredEnvironment)
            print(stdout)
            return stdout
        } catch let error as ShellOutError {
            let stdout = error.output
            let stderr = error.message
            throw Error.shellCommandFailed(command.description, path: path, stdout: stdout, stderr: stderr)
        }

    }

    static var allowedEnvVariables: [String] {
        [
            "DEVELOPER_DIR",
            "GIT_DEPTH",
            "LIBRARY_PATH",
            "PATH",
            "PWD",
            "SDKROOT",
            "SHELL",
            "TERM",
            "TMPDIR",
        ]
    }
}


extension ShellOutCommand {
    static func env(_ arguments: String...) -> Self {
        .init(command: "env", arguments: arguments)
    }

    static func env(_ arguments: String..., command: Self) -> Self {
        .init(command: "env", arguments: arguments + [command.command] + command.arguments)
    }

    static func file(_ arguments: String...) -> Self {
        .init(command: "file", arguments: arguments)
    }

    static func find(_ arguments: String...) -> Self {
        .init(command: "find", arguments: arguments)
    }

    static var findDocArchives: Self {
        .bash(arguments: [#"find "$PWD/.derivedData" -type d -name "*.doccarchive""#.verbatim])
    }

    static func git(_ arguments: String...) -> Self {
        .init(command: "git", arguments: arguments)
    }

    static func ls(_ arguments: String...) -> Self {
        .init(command: "ls", arguments: arguments)
    }

    static func mkdir(_ arguments: String...) -> Self {
        .init(command: "mkdir", arguments: arguments)
    }

    static func mv(_ arguments: String...) -> Self {
        .init(command: "mv", arguments: arguments)
    }

    static func rm(_ arguments: String...) -> Self {
        .init(command: "rm", arguments: arguments)
    }

    static func swift(_ arguments: String...) -> Self {
        .init(command: "swift", arguments: arguments)
    }

    static var swiftPackageDescribe: Self {
        .swift("package", "describe", "--type", "json")
    }

    static var swiftPackageResolve: Self {
        .swift("package", "resolve")
    }

    static func touch(_ arguments: String...) -> Self {
        .init(command: "touch", arguments: arguments)
    }

    static func xcrun() -> Self {
        .env(#"DEVELOPER_DIR=/Applications/Xcode-15.4.0.app"#, "xcrun")
    }

    static func xcrun(_ arguments: [String]) -> Self {
        xcrun().appending(arguments: arguments)
    }
}


enum PackageSwift {
    /// Append the swift-docc-plugin package dependency to the Package.swift file if it is not in the file already.
    /// - Parameter version: Version of the docc plugin, for example `"1.0.0"`
    /// - Returns: the `ShelloutCommand`
    static func appendDoccPlugin(version: String) -> ShellOutCommand {
        .bash(arguments: ["""
            shopt -s nullglob && for manifest in Package.swift Package@*.swift ; do
            if ! grep -E -i "https://github.com/(apple|swiftlang)/swift-docc-plugin" "$manifest" ; then
            cat <<EOF >> "$manifest"
            
            package.dependencies.append(
                .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "\(version)")
            )
            EOF
            fi
            done
            """.verbatim])
    }
}
