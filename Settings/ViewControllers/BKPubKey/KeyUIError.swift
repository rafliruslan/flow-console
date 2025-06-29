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

enum KeyUIError: Error, LocalizedError {
  case emptyName
  case duplicateName(name: String)
  case authKeyGenerationFailed
  case saveCardFailed
  case generationFailed
  case noReadAccess
  
  var errorDescription: String? {
    switch self {
    case .emptyName: return "Key name can't be empty."
    case .duplicateName(let name): return "Key with name `\(name)` already exists."
    case .authKeyGenerationFailed: return "Could not generate public key."
    case .saveCardFailed: return "Can't save key."
    case .generationFailed: return "Generation failed."
    case .noReadAccess: return "Can't get read access to file."
    }
  }
}
