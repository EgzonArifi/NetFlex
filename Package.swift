// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "NetFlex",
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
