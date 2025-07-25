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

public protocol PublicKey {
  // Authorized key format
  var type: String { get }
  // Key blob in wire format. Does not include comment.
  func encode() throws -> Data
  //func verify(signature bytes: Data, of data: Data) throws -> Bool
}

public protocol Signer {
  var publicKey: PublicKey { get }
  func sign(_ message: Data, algorithm: String?) throws -> Data
  var comment: String? { get }
  var sshKeyType: SSHKeyType { get }
}

extension PublicKey {
  public func authorizedKey(withComment comment: String) throws -> String {
    let blob = try encode()
    
    // Trim the size from wire encoding
    var parts = [type, blob[4...].base64EncodedString()]
    
    if !comment.isEmpty {
      parts.append(comment)
    }
    
    return parts.joined(separator: " ")
  }
}
