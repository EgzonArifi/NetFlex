// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "NetFlex",
  platforms: [
    .macOS(.v12),
    .iOS(.v14),
    .watchOS(.v9),
    .tvOS(.v16)
  ],
  products: [
    .library(
      name: "NetFlex",
      targets: ["NetFlex"]),
  ],
  targets: [
    .target(
      name: "NetFlex"),
    .testTarget(
      name: "NetFlexTests",
      dependencies: ["NetFlex"]
    ),
  ]
)
