//////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Based on Blink Shell for iOS
// Original Copyright (C) 2016-2024 Blink Shell contributors
// Flow Console modifications Copyright (C) 2024 Flow Console Project
//
// This file is part of Flow Console.
//
// Flow Console is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Flow Console is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Flow Console. If not, see <http://www.gnu.org/licenses/>.
//
// Original Blink Shell project: https://github.com/blinksh/blink
// Flow Console project: https://github.com/rafliruslan/flow-console
//
////////////////////////////////////////////////////////////////////////////////


import Foundation

// Feature flags definition
extension FeatureFlags {
  @objc static let noSubscriptionNag     = _enabled(for: .developer, .testFlight)
  @objc static let blinkBuild            = _enabled(for: .developer, .testFlight)
  @objc static let blinkBuildStaging     = _enabled(for: .developer, .testFlight)
//  @objc static let checkReceipt          = _enabled(for: .legacy)
  @objc static let earlyAccessFeatures   = _enabled(for: .developer, .testFlight)
//  @objc static let earlyAccessFeatures   = _enabled(for: .legacy)
}

struct PublishingOptions: OptionSet, CustomStringConvertible, CustomDebugStringConvertible {
  let rawValue: UInt8
  
  static let developer  = Self.init(rawValue: 1 << 0)
  static let testFlight = Self.init(rawValue: 1 << 1)
  static let appStore   = Self.init(rawValue: 1 << 2)
  
  static let legacyDeveloper  = Self.init(rawValue: 1 << 3)
  static let legacyTestFlight = Self.init(rawValue: 1 << 4)
  static let legacyAppStore   = Self.init(rawValue: 1 << 5)
  
  static let all: Self = [.developer, .testFlight, .appStore, .legacyDeveloper, .legacyTestFlight, .legacyAppStore]
  
  static let legacy: Self = [.legacyDeveloper, .legacyTestFlight, .legacyAppStore]
  
#if FLOW_CONSOLE_LEGACY_PUBLISHING_OPTION_DEVELOPER
  static var current: Self  = .legacyDeveloper
#elseif FLOW_CONSOLE_LEGACY_PUBLISHING_OPTION_TESTFLIGHT
  static var current: Self  = .legacyTestFlight
#elseif FLOW_CONSOLE_LEGACY_PUBLISHING_OPTION_APPSTORE
  static var current: Self  = .legacyAppStore
#elseif FLOW_CONSOLE_PUBLISHING_OPTION_DEVELOPER
  static var current: Self  = .developer
#elseif FLOW_CONSOLE_PUBLISHING_OPTION_TESTFLIGHT
  static var current: Self  = .testFlight
#else
  static var current: Self  = .appStore
#endif
  
  var description: String {
    var result: [String] = []
    if self.contains(.developer) {
      result.append("Developer")
    }
    if self.contains(.testFlight) {
      result.append("Test Flight")
    }
    if self.contains(.appStore) {
      result.append("App Store")
    }
    
    if self.contains(.legacyDeveloper) {
      result.append("v14 Developer")
    }
    
    if self.contains(.legacyTestFlight) {
      result.append("v14 Test Flight")
    }
    
    if self.contains(.legacyAppStore) {
      result.append("v14 App Store")
    }
    
    return "(" + result.joined(separator: ", ") + ")"
  }
  
  var debugDescription: String {
    var result: [String] = []
    if self.contains(.developer) {
      result.append("developer")
    }
    if self.contains(.testFlight) {
      result.append("testFlight")
    }
    if self.contains(.appStore) {
      result.append("appStore")
    }
    
    if self.contains(.legacyDeveloper) {
      result.append("developer-legacy")
    }
    
    if self.contains(.legacyTestFlight) {
      result.append("testFlight-Legacy")
    }
    
    if self.contains(.legacyAppStore) {
      result.append("appStore-Legacy")
    }
    
    return "[" + result.joined(separator: ", ") + "]"
  }
}

@objc class FeatureFlags: NSObject {
  
  @available(*, unavailable)
  override init() { }

  private static func _enabled(for options: PublishingOptions...) -> Bool {
//    PublishingOptions.current.contains(PublishingOptions(options))
    PublishingOptions(options).contains(.current)
  }
  
  @objc static func currentPublishingOptions() -> String {
    PublishingOptions.current.description
  }
}


