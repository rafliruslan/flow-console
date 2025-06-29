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


#include "UIApplication+Version.h"
#import "Flow_Console-Swift.h"

@implementation UIApplication (FlowConsoleVersion)

+ (NSString *)flowConsoleVersion {
  NSString *compileDate = [NSString stringWithUTF8String:__DATE__];
  
  NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
  NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleName"];
 
  return [NSString stringWithFormat:@"%@: %@ %@. %@",
          appDisplayName, [UIApplication flowConsoleShortVersion], [FeatureFlags currentPublishingOptions] , compileDate];
}

+ (NSString *)flowConsoleShortVersion {
  NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
  NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
  NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
  return [NSString stringWithFormat:@"v%@.%@", majorVersion, minorVersion];
}

+ (NSString *)flowConsoleMajorVersion {
  NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
  NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
  return [NSString stringWithFormat:@"v%@", majorVersion];
}


@end
