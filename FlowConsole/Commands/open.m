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

#include <stdio.h>
#import "MCPSession.h"
#include "ios_system/ios_system.h"

__attribute__ ((visibility("default")))
int open_main(int argc, char *argv[]) {
  if (argc != 2) {
    NSString *usage = [@[
                         @"usage: open file"
                         ] componentsJoinedByString:@"\n"];
    fputs(usage.UTF8String, thread_stdout);
    fputs("\n", thread_stderr);
    return 1;
  }
  NSString *args = [NSString stringWithUTF8String:argv[1]];
  
  if (args.length == 0) {
    return 1;
  }
  
  MCPSession *session = (__bridge MCPSession *)thread_context;
  
  NSFileManager *fm = [[NSFileManager alloc] init];
  NSMutableArray *urls = [[NSMutableArray alloc] init];
  bool isDir = NO;
  if ([fm fileExistsAtPath:args isDirectory:&isDir]) {
    NSURL * currentDir = [NSURL fileURLWithPath: [fm currentDirectoryPath]];
    NSURL * url = [currentDir URLByAppendingPathComponent:args isDirectory:NO];
    if (url) {
      [urls addObject:url];
    } else {
      fprintf(thread_stderr, "Can't open file or dir");
      return 1;
    }
  } else {
    NSURL *url = [NSURL URLWithString:args];
 
    if (url) {
      [urls addObject:url];
    } else {
      fprintf(thread_stderr, "%s", [NSString stringWithFormat:@"Can't open file or dir at path: %@", url].UTF8String);
      return 1;
    }
  }
  
  dispatch_semaphore_t dsema = dispatch_semaphore_create(0);
  
  UIActivityViewControllerCompletionWithItemsHandler hander = ^(UIActivityType __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError) {
    dispatch_semaphore_signal(dsema);
  };
  
  dispatch_async(dispatch_get_main_queue(), ^{
    UIActivityViewController *ctrl = [[UIActivityViewController alloc] initWithActivityItems:urls applicationActivities:nil];

    ctrl.completionWithItemsHandler = hander;
    
    if (ctrl.popoverPresentationController) {
      UIView *view = session.device.view;
      ctrl.popoverPresentationController.sourceView = view;

      CGRect rect = CGRectMake(0, view.bounds.size.height - 30, view.bounds.size.width, 30);
      ctrl.popoverPresentationController.sourceRect = rect;
    }

    [session.device.delegate.viewController presentViewController:ctrl animated:YES completion:nil];
  });
  
  dispatch_semaphore_wait(dsema, DISPATCH_TIME_FOREVER);
  
  return 0;
}
