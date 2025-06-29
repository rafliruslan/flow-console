# Development Workflow & Best Practices

## Workflow Standards

### Git & Release Management

- **GitFlow**: Use standard GitFlow branching strategy
  - `main` - Production releases only
  - `develop` - Integration branch (default)
  - `feature/` - Feature development
  - `release/` - Release preparation
  - `hotfix/` - Emergency production fixes
- **Semantic Versioning**: Follow semver (MAJOR.MINOR.PATCH)
- **Changelog**: Maintain detailed changelog following Keep a Changelog format
- **Git Tags**: Tag all releases with version numbers

### Development Process

1. **Explore** - Research (Think) and understand requirements
2. **Plan** - Create detailed implementation plan
3. **Code** - Implement features following best practices
4. **Commit** - Make atomic, well-documented commits

### Testing Strategy

- **Test-Driven Development (TDD)** preferred approach
- **Write tests first**, then implement
- **Commit tests separately** from implementation
- **Iterate**: Code → Test → Refactor → Commit cycle

### Build & Testing Commands

#### Building for iPad Device

```bash
# List available devices
xcrun xctrace list devices

# Build for connected iPad Pro 11-inch
xcodebuild -project "Flow Console.xcodeproj" \
  -scheme "Flow Console" \
  -destination "platform=iOS,name=iPad Pro (11-inch)" \
  clean build

# Build for iPad Pro 11-inch M4 Simulator
xcodebuild -project "Flow Console.xcodeproj" \
  -scheme "Flow Console" \
  -destination "platform=iOS Simulator,id=FF15DE22-1F53-4B6F-881F-96BE884AE3D9" \
  clean build

# Build and install to device
xcodebuild -project "Flow Console.xcodeproj" \
  -scheme "Flow Console" \
  -destination "platform=iOS,name=iPad Pro (11-inch)" \
  -derivedDataPath ./build \
  clean build

# Archive for distribution
xcodebuild -project "Flow Console.xcodeproj" \
  -scheme "Flow Console" \
  -destination "generic/platform=iOS" \
  -archivePath ./Flow_Console.xcarchive \
  clean archive

# Install and launch on simulator
xcrun simctl install FF15DE22-1F53-4B6F-881F-96BE884AE3D9 "path/to/Flow Console.app"
xcrun simctl launch FF15DE22-1F53-4B6F-881F-96BE884AE3D9 com.flowconsole.Flow-Console
```

### Code Standards

- Follow Swift coding conventions
- Maintain iPad-first design principles
- Use SwiftUI for all UI components
- Keep architecture modular and testable
- Document public APIs

### Commit Standards

- Use conventional commit messages
- Make atomic commits with single responsibility
- Write descriptive commit messages
- Reference issues/features when applicable
- **IMPORTANT**: Never mention Claude, Anthropic, or AI assistance in commits/PRs

### Project Guidelines

- Maintain clean, professional codebase
- Focus on core terminal functionality
- Keep free and open source principles
- Prioritize performance and user experience

## iOS Development Lessons Learned

### Bundle Identifier & App ID Management

**Key Insight**: Changing bundle identifiers in complex iOS apps requires careful consideration of associated entitlements and capabilities.

#### Apple Developer Account Limits
- **App ID Limit**: 10 App IDs per 7-day rolling period
- **Impact**: Can block device deployment when limit reached
- **Workaround**: Use iOS Simulator for development during limit period

#### Bundle Identifier Dependencies
When changing bundle identifiers, verify all associated components:

1. **App Groups** - Must exist in Apple Developer account
   - Used for: Data sharing between main app and extensions
   - Format: `group.{bundle.identifier.prefix}`
   - Required for: File Provider Extensions, shared data access

2. **iCloud Containers** - Must match bundle identifier pattern
   - Used for: Cross-device data synchronization
   - Format: `iCloud.{bundle.identifier}`
   - Required for: User data sync, document storage

3. **Keychain Groups** - For secure credential sharing
   - Used for: SSH keys, certificates, secure storage
   - Format: Typically matches bundle identifier
   - Required for: Secure authentication, certificate management

4. **Provisioning Profiles** - Must include all required capabilities
   - Data Protection (for file encryption)
   - App Groups (for extension communication)
   - iCloud (for data synchronization)
   - Keychain Sharing (for secure storage)
   - File Provider (for file system integration)

#### Best Practices
- **Verify entitlements** before changing bundle identifiers
- **Check App Group availability** in Apple Developer account
- **Test on simulator first** to validate configuration
- **Document bundle identifier dependencies** for future reference
- **Consider iOS capabilities** when reusing existing App IDs

#### Current Configuration
- **Bundle ID**: `com.rafli.flowconsole`
- **App Group**: `com.rafli.flowconsole`
- **iCloud Container**: `com.flowconsole.app`
- **Keychain Group**: `com.rafli.flowconsole`

## Project Status & Milestones

### ✅ Phase 1: Subscription Removal - COMPLETED
- **Objective**: Remove all subscription dependencies to make project completely free and open source
- **Status**: Successfully completed with comprehensive verification
- **Key Results**: 
  - Removed entire `/Blink/Subscriptions/` directory (8 files)
  - Eliminated RevenueCat SDK dependency
  - Created unlimited access stubs for EntitlementsManager
  - Project builds successfully on both simulator and device
  - All features unlocked and freely available

### ✅ Phase 2: Complete Rebranding - COMPLETED  
- **Objective**: Transform from "Blink Shell" to "Flow Console" across entire codebase
- **Status**: Successfully completed with full functionality verification
- **Key Results**:
  - Renamed `Blink.xcodeproj` → `Flow Console.xcodeproj`
  - Updated 285+ files with Flow Console branding
  - Changed bundle identifiers: `sh.blink.*` → `com.flowconsole.*`
  - Updated terminal prompt: "blink>" → "flow>"
  - Fixed all runtime crashes and UI elements
  - App launches successfully with working terminal

### Current Status: **PRODUCTION READY** 🎉

The Flow Console project is now fully transformed and ready for:
- ✅ Distribution via App Store or direct installation
- ✅ Open source community contributions  
- ✅ Further feature development
- ✅ Commercial or non-commercial use

### Verification Commands

```bash
# Verify successful build
xcodebuild -project "Flow Console.xcodeproj" -scheme "Flow Console" \
  -destination "platform=iOS Simulator,id=FF15DE22-1F53-4B6F-881F-96BE884AE3D9" clean build
# Expected: BUILD SUCCEEDED

# Verify app functionality
xcrun simctl launch FF15DE22-1F53-4B6F-881F-96BE884AE3D9 com.flowconsole.Flow-Console
# Expected: App launches with "flow>" terminal prompt
```
