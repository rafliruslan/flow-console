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

// MARK: Lightweight UI state encoded

protocol UserActivityCodable: Codable {
  static var activityType: String { get }
}

extension UserActivityCodable {
  static var userInfoKey: String { "data" }
  
  init?(userActivity: NSUserActivity?) {
    let decoder = PropertyListDecoder()
    guard
      let activity = userActivity,
      activity.activityType == Self.activityType,
      let data = activity.userInfo?[Self.userInfoKey] as? Data,
      let value = try? decoder.decode(Self.self, from: data)
      else {
        return nil
    }
    
    self = value
  }
}

extension NSUserActivity {
  convenience init?<T: UserActivityCodable>(userActivityCodable: T) {
    let encoder = PropertyListEncoder()
    do {
      let data = try encoder.encode(userActivityCodable)
      self.init(activityType: T.activityType)
      addUserInfoEntries(from: [T.userInfoKey: data])
    } catch {
      return nil
    }
  }
}

protocol UIStateRestorable {
  associatedtype UIState: UserActivityCodable
  
  func dumpUIState() -> UIState
  func restore(withState: UIState)
  
  static func onDidDiscardSceneSessions(_ sessions: Set<UISceneSession>)
}

extension UIStateRestorable {
  public func stateRestorationActivity() -> NSUserActivity? {
    return NSUserActivity(userActivityCodable: dumpUIState())
  }
  
  public func restoreWith(stateRestorationActivity: NSUserActivity?) {
    guard
      let activity = stateRestorationActivity,
      let uiState = UIState(userActivity: activity)
      else {
        return
    }
    
    restore(withState: uiState)
  }
  
}
