# GenerableErrors

GenerableErrors is a Swift package for structured, on-device HTTP error message generation with Apple's Foundation Models. This repository also includes an iOS app that integrates the package end-to-end.

## Demo

<video src="https://github.com/user-attachments/assets/62396043-1b74-4292-aebc-b5bac7c42720" controls muted playsinline width="300"></video>

## What You Get

- Typed generation boundary via `GenerationSession`
- Structured streaming output via `GenerationStream`
- Unified domain errors via `GenerationError`
- Built-in style catalog (`CuratedStyles`) with 15 styles
- Test support utilities in `GenerableErrorsTesting`

## API Shape

### Core protocols

- `ErrorDescriptor`: domain input (`code`, `name`, `explanation`)
- `ErrorStyle`: generation style (`promptHint`, optional `temperature`)
- `GenerationSession`: generation entry point with availability reporting

### Core flow

1. Conform your domain type to `ErrorDescriptor`.
2. Choose a style (curated or custom).
3. Call `generate(for:style:)`.
4. Consume streamed `GeneratedSnapshot` values.

## Package Products

| Product | Purpose |
|---|---|
| `GenerableErrors` | Core library: protocols, session abstraction, stream and error types |
| `CuratedStyles` | Optional built-in style catalog |
| `GenerableErrorsTesting` | Test support helpers for package/app tests |

## Requirements

- Xcode 26.2+ (Swift 6.2)
- iOS 26+ / macOS 26+
- Apple Intelligence and Siri enabled
- Apple Silicon for local model execution

## Installation

### Xcode

1. **File > Add Package Dependencies...**
2. Enter `https://github.com/westdorp/GenerableErrors.git`
3. Add `GenerableErrors` (and optionally `CuratedStyles`)

### `Package.swift`

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.iOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/westdorp/GenerableErrors.git", branch: "main")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "GenerableErrors", package: "GenerableErrors"),
                .product(name: "CuratedStyles", package: "GenerableErrors")
            ]
        )
    ]
)
```

## Quick Start

```swift
import CuratedStyles
import GenerableErrors

struct HTTPStatus: ErrorDescriptor {
    let code: String
    let name: String
    let explanation: String
}

func generateExample() async {
    let session = FoundationModelSession()
    session.prewarmModel()

    guard session.availability.isAvailable else {
        print(session.availability.unavailabilityMessage ?? "Model unavailable")
        return
    }

    let status = HTTPStatus(
        code: "404",
        name: "Not Found",
        explanation: "The origin server did not find a current representation for the target resource."
    )

    let stream = session.generate(for: status, style: CuratedStyle.haiku)

    do {
        for try await snapshot in stream {
            if let meaning = snapshot.meaning { print("Meaning: \(meaning)") }
            if let message = snapshot.message { print("Message: \(message)") }
        }
    } catch let error as GenerationError {
        print(error.localizedDescription)
    }
}
```

## Foundation Models APIs Used

- `@Generable` and `@Guide(description:)`
- `PartiallyGenerated` streaming snapshots
- `LanguageModelSession.streamResponse(...)`
- `GenerationOptions(temperature:)`
- `SystemLanguageModel.availability`

## Run The iOS App

1. Clone this repository.
2. Open `Example/GenerableErrors.xcodeproj`.
3. Select scheme `GenerableErrors`.
4. Run on an iOS 26 simulator or supported device.

## Repository Layout

```text
GenerableErrors/
├── Package.swift
├── Sources/
│   ├── GenerableErrors/
│   └── CuratedStyles/
├── Tests/
│   ├── GenerableErrorsTests/
│   └── GenerableErrorsTesting/
└── Example/
    ├── GenerableErrors.xcodeproj/
    ├── GenerableErrors/
    └── GenerableErrorsTests/
```

## Testing

```bash
# Fast package tests
swift test --parallel

# Package tests via Xcode
xcodebuild -scheme GenerableErrors-Package -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' test

# App tests
xcodebuild test -project Example/GenerableErrors.xcodeproj -scheme GenerableErrors -destination 'platform=iOS Simulator,name=iPhone 16'

# App tests with Thread Sanitizer
xcodebuild test -project Example/GenerableErrors.xcodeproj -scheme GenerableErrors -destination 'platform=iOS Simulator,name=iPhone 16' -parallel-testing-enabled NO -enableThreadSanitizer YES
```

## Troubleshooting

If generation fails due to model catalog/assets:

1. Open `Settings > Apple Intelligence & Siri` on the host Mac or device.
2. Enable Apple Intelligence and Siri.
3. Keep the system on Wi-Fi and power until model downloads complete.
4. Restart Simulator (if used) and relaunch the app.

## License

MIT. See [LICENSE](LICENSE).
