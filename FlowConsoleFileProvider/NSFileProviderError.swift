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
import FileProvider

extension NSFileProviderError {
  static func couldNotConnect(dueTo error: Error) -> Self {
    // NOTE We can show the error itself, but it is not providing any extra information.
    self.init(.notAuthenticated, userInfo: [//NSLocalizedFailureErrorKey: error,
                                            NSLocalizedFailureReasonErrorKey: "Could not connect."])
  }
  static var noDomainProvided: Self {
    self.init(.notAuthenticated, userInfo: [NSLocalizedFailureReasonErrorKey: "No location provided"])
  }
  
  static func operationError(dueTo error: Error) -> Self {
    self.init(errorCode: 100,
              errorDescription: "Operation Error",
              failureReason: "\(error)")
  }
}

extension NSFileProviderError {
  init(
    errorCode: Int,
    errorDescription: String?,
    failureReason: String? = nil
  ) {
    var info = [String:Any]()
    if let errorDescription = errorDescription {
      info[NSLocalizedDescriptionKey] = errorDescription
    }
    if let failureReason = failureReason {
      info[NSLocalizedFailureReasonErrorKey] = failureReason
    }

    //info[NSLocalizedRecoverySuggestionErrorKey] = "NSLocalizedRecoverySuggestionErrorKey"


    //info[NSLocalizedFailureErrorKey] = "NSLocalizedFailureErrorKey"

    self.init(Code(rawValue: errorCode)!, userInfo: info)
  }
}
