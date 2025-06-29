////////////////////////////////////////////////////////////////////////////////
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


#import <Foundation/Foundation.h>
#import "TermView.h"
#import "TermDevice.h"


NS_ASSUME_NONNULL_BEGIN

typedef struct BuildHTTPResponse {
  const int32_t code;
  const void * body;
  const NSUInteger body_len;
} BuildHTTPResponse;

typedef void (*build_service_callback) (void *, BuildHTTPResponse *);

@interface TokioSignals : NSObject {
  @public void *_signals;
}
- (void) signalCtrlC;

+ (instancetype) requestService:
  (NSURLRequest *) request
  auth: (BOOL) auth
  ctx: (void *)ctx
  callback: (build_service_callback) callback;

+ (nullable NSString *)getBuildId;




@end

NS_ASSUME_NONNULL_END
