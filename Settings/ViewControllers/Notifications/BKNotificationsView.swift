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

import SwiftUI

struct BKNotificationsView: View {
  @StateObject var notification = NotificationConfig()
  
  var body: some View {
    List {
      Section(header: Text("BEL Notifications"), footer: Text("Play a sound when a BEL character is received and send a notification if the terminal is not in focus.")) {
        Toggle("Play Sound on active shell", isOn: $notification.playSoundOnActiveShell)
        Toggle("Notification on background shell", isOn: $notification.notificationOnBackgroundShell)
        
        if (UIDevice.current.userInterfaceIdiom == .phone) {
          Toggle("Use haptic feedback", isOn: $notification.useHapticFeedback)
        }
      }
      
      Section(header: Text("OSC Sequences"), footer: NotifyNotificationsView()) {
        Toggle("'Notify' notifications", isOn: $notification.notifyNotifications)
      }
    }
    .listStyle(GroupedListStyle())
    .navigationBarTitle("Notifications")
  }
}

fileprivate enum BKNotifications: CaseIterable {
  case systemNotification
  case systemLike
  
  /// User-facing string describing the type of notification available
  var description: LocalizedStringKey {
    switch self {
    case .systemNotification: return "System notification"
    case .systemLike: return "System-like notification with title & body"
    }
  }
  
  /// Code sample to show to the user
  var example: String {
    switch self {
    case .systemNotification: return "echo -e \"\\033]9;Text to show\\a\""
    case .systemLike: return "echo -e \"\\033]777;notify;Title;Body of the notification\\a\""
    }
  }
}

/**
 Sample view to show off the available commands and samples. Tap on each command copies it and
 */
struct NotifyNotificationsView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Text("Blink supports standard OSC sequences & iTerm2 growl notifications. Some OSC sequences might not be supported in Mosh. Persist your connections using the geo command to receive notifications in the background after a while.\n\nExamples (tap to copy & use them on a SSH connection):")
      
      ForEach(BKNotifications.allCases, id: \.self) { notification in
        
        Button(action: {
          UIPasteboard.general.string = notification.example
        }) {
          VStack(alignment: .leading) {
            Text(notification.description).bold()
            Text(notification.example).font(.system(.caption, design: .monospaced))
          }
        }.buttonStyle(PlainButtonStyle())
        .clipShape(Rectangle())
        .padding(2)
      }
    }.onDisappear(perform: {
      BLKDefaults.save()
    })
  }
}

class NotificationConfig: ObservableObject {
  @Published var playSoundOnActiveShell: Bool {
    didSet {
      BLKDefaults.setPlaySoundOnBell(playSoundOnActiveShell)
    }
  }
  
  @Published var notificationOnBackgroundShell: Bool {
    didSet {
      _askForNotificationPermissions(completion: { granted in
        if !granted {
          self.notificationOnBackgroundShell = false
        }
        BLKDefaults.setNotificationOnBellUnfocused(self.notificationOnBackgroundShell)
      })
    }
  }
  
  @Published var useHapticFeedback: Bool {
    didSet {
      BLKDefaults.setHapticFeedbackOnBellOff(!useHapticFeedback)
    }
  }
  
  @Published var notifyNotifications: Bool {
    didSet {
      
      _askForNotificationPermissions(completion: { granted in
        if !granted {
          self.notifyNotifications = false
        }
        BLKDefaults.setOscNotifications(self.notifyNotifications)
      })
    }
  }
  
  private func _askForNotificationPermissions(completion: @escaping(Bool) -> Void) {
    
    let center = UNUserNotificationCenter.current()
    
    center.requestAuthorization(options: [.alert, .sound, .announcement]) { (granted, error) in
      DispatchQueue.main.async {
        completion(granted)
      }
    }
  }
  
  init() {
    playSoundOnActiveShell = BLKDefaults.isPlaySoundOnBellOn()
    notificationOnBackgroundShell = BLKDefaults.isNotificationOnBellUnfocusedOn()
    useHapticFeedback = !BLKDefaults.hapticFeedbackOnBellOff()
    notifyNotifications = BLKDefaults.isOscNotificationsOn()
  }
}
