# Contributing to AirSync macOS (2.0)

Thank you for your interest in contributing!  
Before you submit a pull request, please read the following guidelines.

## Licensing

By contributing code, documentation, or any other materials, you agree that your contributions will be licensed under the:

- Mozilla Public License 2.0
- Plus the Additional Non-Commercial Use Clause defined in the LICENSE file

This ensures that the project remains open for personal use but protected against unauthorized commercial redistribution.

## Guidelines

- Make pull requests to the `main` or `dev` branch.
- Include clear commit messages.
- Respect project structure and coding standards.
- If you're submitting a new feature, consider opening an issue to discuss it first.

## Adding New Icons

### 1. Add Image Assets
1. Add your new icon images to `Assets.xcassets/AppIcons/`
2. Create both an `.imageset` (for UI display) and optionally an `.appiconset` (for actual app icons)
3. Follow the naming convention: `AppIconImage-[variant]`

### 2. Define the Icon
Add to `AppIconExtensions.swift`:

```swift
static let newIcon = AppIcon(
    name: "Display Name",
    description: "Optional description",
    imageName: "AppIconImage-variant",  // Asset name
    iconName: "AppIconImage-variant"    // NSImage name
)
```

### 3. Register the Icon
Add to the `allIcons` array:

```swift
static let allIcons: [AppIcon] = [
    .defaultIcon,
    .pixelIcon,
    .newIcon  // Add here
]
```

## Contact

For questions about contributions or licensing, contact: sameerasw.com@gmail.com
