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


class BackgroundTaskMonitor {
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
  private var taskIsSuspended: Bool = false
  private let start: (() -> Void)
  private let stop:  (() -> Void)
  
  public init(start: @escaping (() -> Void), stop: @escaping (() -> Void)) {
    self.start = start
    self.stop  = stop
    
    NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                           object: nil,
                                           queue: nil) { [weak self] in self?.didEnterBackground($0) }
    NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                           object: nil,
                                           queue: nil) { [weak self] in self?.willEnterForeground($0) }
    start()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
    // Remove the task
    cleanupBackgroundMonitor()
  }

  // All events are sent and processed on Main queue by iOS.
  // Foreground event
  private func willEnterForeground(_: Notification) {
    if taskIsSuspended {
      start()
      taskIsSuspended = false
    }
    cleanupBackgroundMonitor()
  }
  
  // Background event
  private func didEnterBackground(_: Notification) {
    if !taskIsSuspended {
      startBackgroundMonitor()
    }
  }
  
  // Suspension event
  private func didEnterSuspension() {
    guard self.backgroundTask != .invalid else {
      return
    }
    print("Application suspended while task is monitored. Stopping...")
    self.taskIsSuspended = true
    self.stop()
    self.cleanupBackgroundMonitor()
  }
  
  private func startBackgroundMonitor() {
    guard backgroundTask == .invalid else {
      return
    }
    print("Starting background monitoring...")
    backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
      self?.didEnterSuspension()
    }
  }
    
  private func cleanupBackgroundMonitor() {
    if backgroundTask != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTask)
      backgroundTask = .invalid
    }
  }
}
