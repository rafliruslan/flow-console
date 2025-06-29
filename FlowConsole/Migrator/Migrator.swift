//////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Copyright (C) 2016-2019 Flow Console Project
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
// In addition, Flow Console is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Flow Console Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////


import Foundation
import FlowConsoleConfig


@objc class Migrator : NSObject {
  @objc static func perform() {
    Self.perform(steps: [MigrationToAppGroup(),
                         MigrationAddSnippetsShortcut(),
                         MigrationFileProviderReplicatedExtension()
                        ])
  }

  static func perform(steps: [MigrationStep]) {
    let migratorFileURL = URL(fileURLWithPath: FlowConsolePaths.groupContainerPath()).appendingPathComponent(".migrator")

    let currentVersionString = try? String(contentsOf: migratorFileURL, encoding: .utf8)
    var currentVersion = Int(currentVersionString ?? "0") ?? 0

    steps.forEach { step in
      guard step.version > currentVersion else {
        return
      }

      do {
        try step.execute()
        currentVersion = step.version
        try String(currentVersion)
          .data(using: .utf8)!
          .write(to: migratorFileURL,
                 options:  [.atomic, .noFileProtection])
      } catch {
        print(error)
        exit(0)
      }
    }
  }
}

protocol MigrationStep {
  // Migration steps should be idempotent
  func execute() throws
  // After a step is applied, the version is updated
  var version: Int { get }
}
