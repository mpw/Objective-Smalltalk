// swift-tools-version:5.3

import Foundation
import PackageDescription

var sources = ["src/parser.c"]
if FileManager.default.fileExists(atPath: "src/scanner.c") {
    sources.append("src/scanner.c")
}

let package = Package(
    name: "TreeSitterObjectives",
    products: [
        .library(name: "TreeSitterObjectives", targets: ["TreeSitterObjectives"]),
    ],
    dependencies: [
        .package(name: "SwiftTreeSitter", url: "https://github.com/tree-sitter/swift-tree-sitter", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "TreeSitterObjectives",
            dependencies: [],
            path: ".",
            sources: sources,
            resources: [
                .copy("queries")
            ],
            publicHeadersPath: "bindings/swift",
            cSettings: [.headerSearchPath("src")]
        ),
        .testTarget(
            name: "TreeSitterObjectivesTests",
            dependencies: [
                "SwiftTreeSitter",
                "TreeSitterObjectives",
            ],
            path: "bindings/swift/TreeSitterObjectivesTests"
        )
    ],
    cLanguageStandard: .c11
)
