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

NSString *__screens(void) {
  NSMutableArray<NSString *> * result = [[NSMutableArray alloc] initWithCapacity:UIScreen.screens.count];
  
  UIScreen *main =  UIScreen.mainScreen;
  for (UIScreen *screen in UIScreen.screens) {
    NSMutableString * str = [[NSMutableString alloc] init];
    [str appendFormat:@"Main:          %@\n", main == screen ? @"YES": @"NO"];
    [str appendFormat:@"Captured:      %@\n", screen.captured ? @"YES": @"NO"];
    [str appendFormat:@"Bounds:        %@\n", NSStringFromCGRect(screen.bounds)];
    [str appendFormat:@"Native Scale:  %@\n", @(screen.nativeScale)];
    [str appendFormat:@"Native Bounds: %@\n", NSStringFromCGRect(screen.nativeBounds)];
    [str appendFormat:@"Max FPS:       %@\n", @(screen.maximumFramesPerSecond)];
    [str appendFormat:@"Current Mode:  %@, %@", NSStringFromCGSize(screen.currentMode.size), @(screen.currentMode.pixelAspectRatio)];
    
    [result addObject:str];
  }
  
  return [result componentsJoinedByString:@"\n---------\n"];
}

__attribute__ ((visibility("default")))
int device_info_main(int argc, char *argv[]) {
  DeviceInfo * di = DeviceInfo.shared;
  NSString *info = [@[
    @"",
    @"DEVICE",
    [NSString stringWithFormat:@"Machine:        %@", di.machine],
    [NSString stringWithFormat:@"Release:        %@", di.release_],
    [NSString stringWithFormat:@"Marketing Name: %@", di.marketingName],
    [NSString stringWithFormat:@"Notch:          %@", di.hasNotch ? @"YES" : @"NO"],
    [NSString stringWithFormat:@"Dynamic Island: %@", di.hasDynamicIsland  ? @"YES" : @"NO"],
    [NSString stringWithFormat:@"Corners:        %@", di.hasCorners  ? @"YES" : @"NO"],
    [NSString stringWithFormat:@"Apple Silicon:  %@", di.hasAppleSilicon  ? @"YES" : @"NO"],
    [NSString stringWithFormat:@"Languages:      %@", [[NSLocale preferredLanguages] componentsJoinedByString:@", "]],
    [NSString stringWithFormat:@"Version:        %@", di.version],
    @"",
    @"SCREENS",
    __screens(),
    @"",
    [UIApplication flowConsoleVersion],
    @"",
    
 ] componentsJoinedByString:@"\n"];
 
  puts(info.UTF8String);
  
  return 0;
}
