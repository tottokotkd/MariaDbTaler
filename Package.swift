import PackageDescription

let package = Package(
    name: "MariaDbTaler",
    dependencies: [
        .Package(url: "https://github.com/tottokotkd/Sterntaler.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/tottokotkd/CMariaDB.git", majorVersion: 1)
    ]
)
