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
import UIKit
import LocalAuthentication

@objc class LocalAuth: NSObject {
  
  @objc static let shared = LocalAuth()
  
  private var _didEnterBackgroundAt: Date? = nil
  private var _inProgress = false
  
  override init() {
    super.init()
    
    // warm up LAContext
    LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    
    if BKUserConfigurationManager.userSettingsValue(forKey: BKUserConfigAutoLock) {
      _didEnterBackgroundAt = Date.distantPast
    }
    
    NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: OperationQueue.main
    ) { _ in
      
      // Do not reset didEnterBackground if we locked
      if let didEnterBackgroundAt = self._didEnterBackgroundAt,
         Date().timeIntervalSince(didEnterBackgroundAt) > TimeInterval(self.getMaxMinutesTimeInterval() * 60) {
        return
      }
      self._didEnterBackgroundAt = Date()
    }
  }
  
  var lockRequired: Bool {
    guard
      let didEnterBackgroundAt = _didEnterBackgroundAt,
      BKUserConfigurationManager.userSettingsValue(forKey: BKUserConfigAutoLock),
      Date().timeIntervalSince(didEnterBackgroundAt) > TimeInterval(getMaxMinutesTimeInterval() * 60)
    else {
      return false
    }
    
    return true
  }
  
  @objc func getMaxMinutesTimeInterval() -> Int {
    UserDefaults.standard.value(forKey: "BKUserConfigLockIntervalKey") as? Int ?? 10
  }
  
  @objc func setNewLockTimeInterval(minutes: Int) {
    UserDefaults.standard.set(minutes, forKey: "BKUserConfigLockIntervalKey")
  }
  
  func unlock() {
    authenticate(
      callback: { [weak self] (success) in
        if success {
          self?.stopTrackTime()
        }
      },
      reason: "to unlock blink."
    )
  }
  
  func stopTrackTime() {
    _didEnterBackgroundAt = nil
  }
  
  @objc func authenticate(callback: @escaping (_ success: Bool) -> Void, reason: String = "to access sensitive data.") {
    if _inProgress {
      callback(false)
      return
    }
    _inProgress = true
    
    let context = LAContext()
    var error: NSError?
    guard
      context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    else {
      debugPrint(error?.localizedDescription ?? "Can't evaluate policy")
      _inProgress = false
      callback(false)
      return
    }

    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in
      DispatchQueue.main.async {
        self._inProgress = false
        callback(success)
      }
    }
  }
}
