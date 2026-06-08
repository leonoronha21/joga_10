// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_face_liveness",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "flutter_face_liveness", targets: ["flutter_face_liveness"])
    ],
    targets: [
        .target(
            name: "flutter_face_liveness",
            dependencies: [],
            path: "Sources/flutter_face_liveness"
        )
    ]
)
