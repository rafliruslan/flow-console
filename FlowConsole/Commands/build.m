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

#include <libssh/callbacks.h>


#include "ios_system/ios_system.h"
#include "ios_error.h"
#include "MCPSession.h"
#include "TokioSignals.h"
#include "openurl.h"

struct IOSEnv {
  int stdin_fd;
  int stdout_fd;
  int stderr_fd;
  const char * cwd;
  void * open_url_fn;
  void * start_mosh_fn;
};




void tokio_open_url(char *url) {
#ifdef BLINK_BUILD_ENABLED
  NSString * str = @(url);
  blink_openurl([NSURL URLWithString:str]);
#endif
}

void tokio_start_mosh(char * key, char * host, char * port) {
#ifdef BLINK_BUILD_ENABLED
  MCPSession *session = (__bridge MCPSession *)thread_context;
  if (!session) {
    return;
  }
  
  NSString * cmd = [NSString stringWithFormat:@"mosh -o -I build -k %@ -p %@ %@", @(key), @(port), @(host)];

  dispatch_async(session.cmdQueue, ^{
    [session enqueueCommand:cmd skipHistoryRecord:YES];
  });
#endif
}

extern int blink_build_cmd(int argc, char *argv[], struct IOSEnv * env, void ** signals);
  
__attribute__ ((visibility("default")))
int build_main(int argc, char *argv[]) {
#ifdef BLINK_BUILD_ENABLED
  MCPSession *session = (__bridge MCPSession *)thread_context;
  if (!session) {
    return -1;
  }
  
  struct IOSEnv env = {
      .stdin_fd = fileno(ios_stdin()),
      .stdout_fd = fileno(ios_stdout()),
      .stderr_fd = fileno(ios_stderr()),
      .cwd = [NSFileManager.defaultManager currentDirectoryPath].UTF8String,
      .open_url_fn = tokio_open_url,
      .start_mosh_fn = tokio_start_mosh,
  };
  
  TokioSignals *signals = [TokioSignals new];
  session.tokioSignals = signals;
  
  int res = blink_build_cmd(argc, argv, &env, &signals->_signals);
  
  session.tokioSignals = nil;
  
  return res;
#else
  return 0;
#endif
}
