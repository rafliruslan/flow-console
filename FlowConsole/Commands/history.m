////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Copyright (C) 2016-2018 Flow Console Project
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

#include <stdio.h>
#include "FlowConsolePaths.h"
#include "ios_system/ios_system.h"
#include "ios_error.h"
#include "MCPSession.h"
#import "Flow_Console-Swift.h"

int _print_history_lines(NSInteger number) {
  NSString *history = [NSString stringWithContentsOfFile:[FlowConsolePaths historyFile]
                                                encoding:NSUTF8StringEncoding error:nil];
  NSArray *lines = [history componentsSeparatedByString:@"\n"];
  if (!lines) {
    return 1;
  }
  lines = [lines filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self != ''"]];
  
  NSInteger len = lines.count;
  NSInteger start = 0;
  if (number > 0) {
    len = MIN(len, number);
  } else if (number < 0) {
    start = MAX(len + number , 0);
  }
  
  for (NSInteger i = start; i < len; i++) {
    puts([NSString stringWithFormat:@"% 4li %@", i + 1, lines[i]].UTF8String);
  }
  
  return 0;
}
__attribute__ ((visibility("default")))
int history_main(int argc, char *argv[]) {
  NSString *args = @"";
  if (argc == 2) {
    args = [NSString stringWithUTF8String:argv[1]];
  } else {
    args = @"500";
  }
  NSInteger number = [args integerValue];
  if (number != 0) {
    return _print_history_lines(number);
  } else if ([args isEqualToString:@"-a"]) {
    return _print_history_lines(0);
  } else if ([args isEqualToString:@"-c"]) {
      [HistoryObj clear];
  } else {
    NSString *usage = [@[
                         @"history usage:",
                         @"history <number> - Show history (can be negative). Default 500",
                         @"history -c       - Clear history",
                         @"history -a       - Print all history",
                         @""
                         ] componentsJoinedByString:@"\n"];
    puts(usage.UTF8String);
  }
  return 1;
}
