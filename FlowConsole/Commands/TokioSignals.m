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


#import "TokioSignals.h"


#ifdef BLINK_BUILD_ENABLED
extern void signal_release(void * signals);
extern void signal_send(void * signals, int signal);

extern char * build_get_build_id(void);

extern void build_call_service(
                               const char * url,
                               const char * method,
                               const void * body,
                               NSUInteger body_len,
                               const char * content_type,
                               BOOL auth, void * ctx,
                               build_service_callback callback,
                               void ** signals);
#endif

@implementation TokioSignals {
}

+ (instancetype) requestService:
  (NSURLRequest *) request
  auth: (BOOL) auth
  ctx: (void *)ctx
  callback: (build_service_callback) callback
{
  TokioSignals *signals = [TokioSignals new];
#ifdef BLINK_BUILD_ENABLED
  build_call_service(
                     request.URL.absoluteString.UTF8String,
                     request.HTTPMethod.UTF8String,
                     request.HTTPBody.bytes,
                     request.HTTPBody.length,
                     [request valueForHTTPHeaderField:@"Content-Type"].UTF8String,
                     auth,
                     ctx, callback, &signals->_signals);
#endif
  
  return signals;
}

+ (nullable NSString *)getBuildId {
#ifdef BLINK_BUILD_ENABLED
  char *ptr = build_get_build_id();
  if (ptr) {
    return [[NSString alloc] initWithBytesNoCopy:ptr
                                          length:strlen(ptr)
                                        encoding:NSUTF8StringEncoding
                                    freeWhenDone:YES];
  } else {
    return nil;
  }
#else
  return nil;
#endif
}


- (void) signalCtrlC {
  if (_signals) {
#ifdef BLINK_BUILD_ENABLED
    signal_send(_signals, 0);
#endif
  }
}

- (void)dealloc {
  if (_signals) {
#ifdef BLINK_BUILD_ENABLED
    signal_release(_signals);
#endif
    _signals = NULL;
  }
}

@end
