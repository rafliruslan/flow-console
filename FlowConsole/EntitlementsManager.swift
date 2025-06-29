//////////////////////////////////////////////////////////////////////////////////
//
// Flow Console - Free Terminal Application
//
// This file provides stub implementations for subscription-related classes
// that have been removed to make the app completely free and open source.
//
//////////////////////////////////////////////////////////////////////////////////

import Foundation
import SwiftUI

// Stub implementation for removed subscription system
class EntitlementsManager: ObservableObject {
    static let shared = EntitlementsManager()
    
    private init() {}
    
    // Stub properties - always return free/unlimited access
    var earlyAccessFeatures = EarlyAccessFeatures()
    
    func currentPlanName() -> String {
        return "Flow Console (Free)"
    }
    
    func groupsCheckViolation() -> Bool {
        return false // Never show violations in free version
    }
    
    func customerTier() -> CustomerTier {
        return .Free
    }
}

// Stub structures for early access features
struct EarlyAccessFeatures {
    let active = true // Always active in free version
    let period = Period.Normal
}

enum Period {
    case Normal
    case Trial
}

// Customer tier enum for compatibility
enum CustomerTier {
    case Plus
    case Classic
    case TestFlight
    case Free
}