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
import CoreData


class MigrationFileProviderReplicatedExtension: MigrationStep {
  var version: Int { get { 1810 } }

  func execute() throws {
    // Replace old FileProvider extension items with the new FileProvider Replicated Extension
    for host in BKHosts.allHosts() {
      guard let json = host.fpDomainsJSON, !json.isEmpty
      else {
        continue
      }

      let domains = FileProviderDomain.listFrom(jsonString: json)
      if domains.count > 0 {
        domains.forEach { domain in
          if !domain.useReplicatedExtension {
            domain.useReplicatedExtension = true
          }
        }
        host.fpDomainsJSON = FileProviderDomain.toJson(list: domains)

        BKHosts._replaceHost(host)
      }
    }

    // Do we need it or does it happen on its own?
    BKiCloudSyncHandler.shared()?.check(forReachabilityAndSync: nil)

    self.deleteFileProviderStorage()
  }

  private func deleteFileProviderStorage() {
    // Clean up the old File Provider path
    let fileProviderURL = NSFileProviderManager.default.documentStorageURL

    guard let contentURLs = try? FileManager.default.contentsOfDirectory(at: fileProviderURL, includingPropertiesForKeys: nil, options: []) else {
      print("No contents found at \(fileProviderURL.path)")
      return
    }

    for url in contentURLs {
      do {
        try FileManager.default.removeItem(at: url)
        print("Removed: \(url.path)")
      } catch {
        print("Failed to remove \(url.path): \(error)")
      }
    }
  }
}
