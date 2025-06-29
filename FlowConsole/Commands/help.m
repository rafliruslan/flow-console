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

#import "BLKDefaults.h"
#import "BKUserConfigurationManager.h"

#include "ios_system/ios_system.h"
#include "ios_error.h"
#include "UIApplication+Version.h"
#include "MCPSession.h"
#import "Flow_Console-Swift.h"

void __print_commands(void) {
  MCPSession *session = (__bridge MCPSession *)thread_context;
  if (!session) {
    return;
  }

  NSString *formattedCommands = [CompleteClass formattedCommandsWithWidth: session.device.cols];
  puts(formattedCommands.UTF8String);
}

__attribute__ ((visibility("default"))) __attribute__((used))
int help_main(int argc, char *argv[]) {
  
  if (argc == 2 && [@"list-commands" isEqual: @(argv[1])]) {
    __print_commands();
    return 0;
  }
  NSString *help = [@[
    @"",
    [UIApplication flowConsoleVersion],
    @"",
    @"Available commands:",
    @"  <tab>: list available UNIX commands.",
    @"  mosh: mosh client.",
    @"  ssh: ssh client.",
    @"  config: Setup ssh keys, hosts, keyboard, etc.",
    @"  code: code editor. (don't forget install blink-fs extension)",
    @"  help: Prints this.",
    @"  whatsnew: Discover new features.",
    @"  exit: Close this shell.",
    @"",
    @"Gestures:",
    @"  ✌️ tap -> New Terminal.  ",
    @"  👆 tap -> Mouse click.  ",
    @"  👆 swipe left/right -> Switch Terminals.  ",
    @"  pinch -> Change font size.",
    UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? @"  👆 drag down -> Dismiss keyboard.\n" : @"",
    @"Shortcuts:",
    @"  Press and hold ⌘ on hardware kb to show a list of shortcuts.",
    @"  Run config. Go to Keyboard > Shortcuts for configuration.",
    @"",
    @"Selection Control:",
    @"  VIM users:",
    @"    h j k l (left, down, up, right)",
    @"    w b (forward/backward by word)",
    @"    o (change selection point)",
    @"    y p (yank, paste)",
    @"  EMACS users:",
    @"    C-f,b,n,p (right, left, down, up)",
    @"    C-M-f,b (forward/backward by word)",
    @"    C-x (change selection point)",
    @"  OTHER: arrows and fingers",
    @"",
    @"Docs: https://blink.sh/docs",
    @"",
    
 ] componentsJoinedByString:@"\n"];
 
  puts(help.UTF8String);
  
  return 0;
}
