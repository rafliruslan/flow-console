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

#import "BKFont.h"
#import <UIKit/UIKit.h>

@implementation BKFont

+ (NSString *)resourcesPathName
{
  return @"Fonts";
}

+ (NSString *)resourcesExtension
{
  return @"css";
}

+ (NSArray *)all
{
  return [[
          self.defaultResources
          arrayByAddingObjectsFromArray: [self _systemWideFonts]]
          arrayByAddingObjectsFromArray: self.customResources];
}


+ (NSArray<BKFont *> *)_systemWideFonts
{
  NSMutableDictionary *map = [[NSMutableDictionary alloc] init];
  NSMutableArray *result = [[NSMutableArray alloc] init];
  for (BKFont *f in self.defaultResources) {
    map[f.name] = f;
  }
  map[@"Apple Color Emoji"] = @(YES);
  
  NSDictionary *traitsAttributes = @{UIFontSymbolicTrait: @(UIFontDescriptorTraitMonoSpace)};
  NSDictionary *fontAttributes = @{UIFontDescriptorTraitsAttribute: traitsAttributes};
  UIFontDescriptor *fontDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:fontAttributes];
  NSArray *array = [fontDescriptor matchingFontDescriptorsWithMandatoryKeys:nil];
  for (UIFontDescriptor *descriptor in array) {
    UIFont *f = [UIFont fontWithDescriptor:descriptor size:10];
    if (map[f.familyName]) {
      continue;
    }
  
    BKFont * font = [[BKFont alloc] init];
    font.name = f.familyName;
    font.systemWide = YES;
    map[font.name] = font;
    [result addObject:font];
  }
  
  return result;
}

- (NSString *)content
{
  if (!_systemWide) {
    return [super content];
  }
  
  NSString * css = [
  @[
      @"@font-face {",
      @" font-family: '[[family]]';",
      @" src: local('[[family]]');",
      @" font-weight: normal;",
      @" font-style: normal;",
      @"}",
      @"",
      @"@font-face {",
      @" font-family: '[[family]]';",
      @" src: local('[[family]]');",
      @" font-weight: bold;",
      @" font-style: normal;",
      @"}",
      @"",
      @"@font-face {",
      @" font-family: '[[family]]';",
      @" src: local('[[family]]');",
      @" font-weight: normal;",
      @" font-style: italic;",
      @" }",
      @" ",
      @"@font-face {",
      @" font-family: '[[family]]';",
      @" src: local('[[family]]');",
      @" font-weight: bold;",
      @" font-style: italic;",
      @"}",
      @"",
  ] componentsJoinedByString:@"\n"];
  
  return [css stringByReplacingOccurrencesOfString:@"[[family]]" withString:self.name];
}

-(BOOL)isCustom
{
  if (_systemWide) {
    return YES;
  }
  return [super isCustom];
}

- (BOOL)isEqual:(id)object {
  if ([super isEqual:object]) {
    return YES;
  }
  
  if (![object isKindOfClass:[BKFont class]]) {
    return NO;
  }
  
  BKFont *other = (BKFont *)object;
  
  return [self isCustom] == [other isCustom] && [self.name isEqualToString:other.name];
}


@end
