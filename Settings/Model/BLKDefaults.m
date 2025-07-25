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
#import "BKFont.h"
#import "UIDevice+DeviceName.h"
#import "FlowConsolePaths.h"
#import "DeviceInfo.h"
#import "LayoutManager.h"


BLKDefaults *defaults;

NSString *const BKAppearanceChanged = @"BKAppearanceChanged";

@implementation BLKDefaults

#pragma mark - NSCoding

- (id)init
{
  self = [super init];
  if (!self) {
    return self;
  }
  
  // For Stage Manager compatibility, set default overscan mode with Apple Silicon.
  if ([[DeviceInfo shared] hasAppleSilicon]) {
    _overscanCompensation = BKBKOverscanCompensationMirror;
  } else {
    _overscanCompensation = 0;
  }

  return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if (!self) {
    return self;
  }
  NSSet *strings = [NSSet setWithObjects:NSString.class, nil];
  NSSet *numbers = [NSSet setWithObjects:NSNumber.class, nil];
  
  
  _themeName = [coder decodeObjectOfClasses:strings forKey:@"themeName"];
  _fontName = [coder decodeObjectOfClasses:strings forKey:@"fontName"];
  _fontSize = [coder decodeObjectOfClasses:numbers forKey:@"fontSize"];
  _externalDisplayFontSize = [coder decodeObjectOfClasses:numbers forKey:@"externalDisplayFontSize"];
  _defaultUser = [coder decodeObjectOfClasses:strings forKey:@"defaultUser"];
  _globalSSHConfig = [coder decodeObjectOfClasses: [NSSet setWithObjects: [BKGlobalSSHConfig class], nil] forKey:@"globalSSHConfig"];
  _cursorBlink = [coder decodeBoolForKey:@"cursorBlink"];
  _enableBold = [coder decodeIntegerForKey:@"enableBold"];
  _boldAsBright = [coder decodeBoolForKey:@"boldAsBright"];
  _keyboardStyle = (BKKeyboardStyle)[coder decodeIntegerForKey:@"keyboardStyle"];
  _keycasts = [coder decodeBoolForKey:@"keycasts"];
  _alternateAppIcon = [coder decodeBoolForKey:@"alternateAppIcon"];
  _layoutMode = (BKLayoutMode)[coder decodeIntegerForKey:@"layoutMode"];
  if ([coder containsValueForKey:@"overscanCompensation"]) {
    _overscanCompensation = (BKOverscanCompensation)[coder decodeIntegerForKey:@"overscanCompensation"];
  }
  _xCallBackURLEnabled = [coder decodeBoolForKey:@"xCallBackURLEnabled"];
  _xCallBackURLKey = [coder decodeObjectOfClasses:strings forKey:@"xCallBackURLKey"];
  _disableCustomKeyboards = [coder decodeBoolForKey:@"disableCustomKeyboards"];
  _playSoundOnBell = [coder decodeBoolForKey:@"playSoundOnBell"];
  _notificationOnBellUnfocused = [coder decodeBoolForKey:@"notificationOnBellUnfocused"];
  _hapticFeedbackOnBellOff = [coder decodeBoolForKey:@"hapticFeedbackOnBellOff"];
  _oscNotifications = [coder decodeBoolForKey:@"oscNotifications"];
  _invertVerticalScroll = [coder decodeBoolForKey:@"invertVerticalScroll"];
  _compactQuickActions = [coder decodeBoolForKey:@"compactQuickActions"];
  
  _dontUseBlinkSnippetsIndex = [coder decodeBoolForKey:@"dontUseBlinkSnippetsIndex"];
  _snippetsDefaultLocation = [coder decodeIntegerForKey:@"snippetsDefaultLocation"];
  
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_themeName forKey:@"themeName"];
  [encoder encodeObject:_fontName forKey:@"fontName"];
  [encoder encodeObject:_fontSize forKey:@"fontSize"];
  [encoder encodeObject:_externalDisplayFontSize forKey:@"externalDisplayFontSize"];
  [encoder encodeObject:_defaultUser forKey:@"defaultUser"];
  [encoder encodeObject:_globalSSHConfig forKey:@"globalSSHConfig"];
  [encoder encodeBool:_cursorBlink forKey:@"cursorBlink"];
  [encoder encodeInteger:_enableBold forKey:@"enableBold"];
  [encoder encodeBool:_boldAsBright forKey:@"boldAsBright"];
  [encoder encodeInteger: _keyboardStyle forKey:@"keyboardStyle"];
  [encoder encodeBool: _keycasts forKey:@"keycasts"];
  [encoder encodeBool:_alternateAppIcon forKey:@"alternateAppIcon"];
  [encoder encodeInteger:_layoutMode forKey:@"layoutMode"];
  [encoder encodeInteger:_overscanCompensation forKey:@"overscanCompensation"];
  [encoder encodeBool:_xCallBackURLEnabled forKey:@"xCallBackURLEnabled"];
  [encoder encodeObject:_xCallBackURLKey forKey:@"xCallBackURLKey"];
  [encoder encodeBool:_disableCustomKeyboards forKey:@"disableCustomKeyboards"];
  [encoder encodeBool:_playSoundOnBell forKey:@"playSoundOnBell"];
  [encoder encodeBool:_notificationOnBellUnfocused forKey:@"notificationOnBellUnfocused"];
  [encoder encodeBool:_hapticFeedbackOnBellOff forKey:@"hapticFeedbackOnBellOff"];
  [encoder encodeBool:_oscNotifications forKey:@"oscNotifications"];
  [encoder encodeBool:_invertVerticalScroll forKey:@"invertVerticalScroll"];
  [encoder encodeBool:_compactQuickActions forKey:@"compactQuickActions"];
  [encoder encodeBool:_dontUseBlinkSnippetsIndex forKey:@"dontUseBlinkSnippetsIndex"];
  [encoder encodeInteger:_snippetsDefaultLocation forKey:@"snippetsDefaultLocation"];
  
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (BOOL)saveDefaults {
  NSError *error = nil;
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:defaults
                                       requiringSecureCoding:YES
                                                       error:&error];
  
  if (error || !data) {
    NSLog(@"[BLKDefaults] Failed to archive: %@", error);
    return NO;
  }
  
  BOOL result = [data writeToFile:[FlowConsolePaths blinkDefaultsFile]
                          options:NSDataWritingAtomic | NSDataWritingFileProtectionNone
                            error:&error];
  
  if (error || !result) {
    NSLog(@"[BLKDefaults] Failed to save data to file: %@", error);
    return NO;
  }
  
  [BLKDefaults saveGlobalSSHConfig];
  
  return result;
}


+ (void)loadDefaults {
  defaults = [[BLKDefaults alloc] init];
  
  NSError *error = nil;
  NSData *data = [NSData dataWithContentsOfFile:[FlowConsolePaths blinkDefaultsFile]
                                        options:NSDataReadingMappedIfSafe
                                          error:&error];
  
  if (error || !data) {
    NSLog(@"[BLKDefaults] Failed to load data: %@", error);
  } else {
    BLKDefaults * result = [NSKeyedUnarchiver unarchivedObjectOfClass:[BLKDefaults class]
                                                            fromData:data
                                                               error:&error];
    if (error || !result) {
      NSLog(@"[BLKDefaults] Failed to unarchive: %@", error);
//      CFStringRef str = CFStringCreateWithBytesNoCopy(NULL, data.bytes, data.length, kCFStringEncodingASCII, NO, kCFAllocatorNull);
//      CFRange range = CFStringFind(str, CFSTR("classnameX$classesZBKDefaults"), 0);
//      CFRelease(str);
//      if (range.location > 0 && range.length > 0) {
      
      NSLog(@"[BLKDefaults] try again with BKDefaults replacement");
      error = nil;
      [NSKeyedUnarchiver setClass:[BLKDefaults class] forClassName:@"BKDefaults"];
      result = [NSKeyedUnarchiver unarchivedObjectOfClass:[BLKDefaults class]
                                                              fromData:data
                                                                 error:&error];
      if (error || ! result) {
        NSLog(@"[BLKDefaults] Failed again to unarchive with BKDefaults replacement: %@", error);
      } else {
        NSLog(@"[BLKDefaults] loaded with BKDefaults replacement");
        defaults = result;
      }
    } else {
      defaults = result;
    }
  }
  
  if (defaults.layoutMode == BKLayoutModeDefault) {
    defaults.layoutMode = [LayoutManager deviceDefaultLayoutMode];
  }

  if (!defaults.fontName) {
    if ([BKFont withName:@"Pragmata Pro Mono"] != nil) {
      [defaults setFontName:@"Pragmata Pro Mono"];
    } else {
      [defaults setFontName:@"Source Code Pro"];
    }
  }
  if (!defaults.themeName) {
    [defaults setThemeName:@"Default"];
  }
  
  if (!defaults.fontSize) {
    #if TARGET_OS_MACCATALYST
      [defaults setFontSize:[NSNumber numberWithInt:22]];
    #else
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
      [defaults setFontSize:[NSNumber numberWithInt:18]];
    } else {
      [defaults setFontSize:[NSNumber numberWithInt:10]];
    }
    #endif
  }
  if (!defaults.externalDisplayFontSize) {
    [defaults setExternalDisplayFontSize:[NSNumber numberWithInt:24]];
  }
  
  if(!defaults.defaultUser || ![[defaults.defaultUser stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]){
    [defaults setDefaultUser:[UIDevice getInfoTypeFromDeviceName:BKDeviceInfoTypeUserName]];
  }

  if(!defaults.globalSSHConfig) {
    [BLKDefaults saveGlobalSSHConfig];
  }
}

+ (void)setCursorBlink:(BOOL)state
{
  defaults.cursorBlink = state;
}

+ (void)setBoldAsBright:(BOOL)state
{
  defaults.boldAsBright = state;
}

+ (void)setAlternateAppIcon:(BOOL)state
{
  defaults.alternateAppIcon = state;
}

+ (void)setKeycasts:(BOOL)state {
  defaults.keycasts = state;
}

+ (void)setEnableBold:(NSUInteger)state
{
  defaults.enableBold = state;
}

+ (void)setFontName:(NSString *)fontName
{
  defaults.fontName = fontName;
}

+ (void)setThemeName:(NSString *)themeName
{
  defaults.themeName = themeName;
}

+ (void)setFontSize:(NSNumber *)fontSize
{
  defaults.fontSize = fontSize;
}

+ (void)setExternalDisplayFontSize:(NSNumber *)fontSize
{
  defaults.externalDisplayFontSize = fontSize;
}

+ (void)setDefaultUserName:(NSString*)name
{
  defaults.defaultUser = name;
}

+ (void)saveGlobalSSHConfig
{
  BKGlobalSSHConfig *config = [[BKGlobalSSHConfig alloc] initWithUser: defaults.defaultUser];
  [config saveFile];
}

+ (void)setLayoutMode:(BKLayoutMode)mode {
  defaults.layoutMode = mode;
}

+ (void)setOversanCompensation:(BKOverscanCompensation)value {
  defaults.overscanCompensation = value;
}

+ (void)setKeyboardStyle:(BKKeyboardStyle)value {
  defaults.keyboardStyle = value;
}

+ (void)setXCallBackURLEnabled:(BOOL)value {
  defaults.xCallBackURLEnabled = value;
}

+ (void)setDisableCustomKeyboards:(BOOL)state {
  defaults.disableCustomKeyboards = state;
}

+ (void)setXCallBackURLKey:(NSString *)key {
  defaults.xCallBackURLKey = key;
}

+ (void)setPlaySoundOnBell:(BOOL)state {
  defaults.playSoundOnBell = state;
}

+ (void)setInvertedVerticalScroll:(BOOL) state {
  defaults.invertVerticalScroll = state;
}

+ (void)setNotificationOnBellUnfocused:(BOOL)state {
  defaults.notificationOnBellUnfocused = state;
}

+ (void)setHapticFeedbackOnBellOff:(BOOL)state {
  defaults.hapticFeedbackOnBellOff = state;
}

+ (void)setOscNotifications:(BOOL)state {
  defaults.oscNotifications = state;
}

+ (void)setDontUseBlinkSnippetsIndex: (BOOL)state {
  defaults.dontUseBlinkSnippetsIndex = state;
}

+ (void)setSnippetsDefaultLocation:(BKSnippetDefaultLocation) value {
  defaults.snippetsDefaultLocation = value;
}


+ (NSString *)selectedFontName
{
  return defaults.fontName;
}
+ (NSString *)selectedThemeName
{
  return defaults.themeName;
}

+ (NSNumber *)selectedFontSize
{
  return defaults.fontSize;
}

+ (NSNumber *)selectedExternalDisplayFontSize
{
  return defaults.externalDisplayFontSize;
}

+ (BOOL)isCursorBlink
{
  return defaults.cursorBlink;
}

+ (NSUInteger)enableBold
{
  return defaults.enableBold;
}

+ (BOOL)isBoldAsBright
{
  return defaults.boldAsBright;
}

+ (BOOL)isAlternateAppIcon
{
  return defaults.alternateAppIcon;
}

+ (BOOL)isKeyCastsOn
{
  return defaults.keycasts;
}

+ (NSString*)defaultUserName
{
  return defaults.defaultUser;
}

+ (BKLayoutMode)layoutMode
{
  return defaults.layoutMode;
}

+ (BKOverscanCompensation)overscanCompensation
{
  return defaults.overscanCompensation;
}

+ (BKKeyboardStyle)keyboardStyle {
  return defaults.keyboardStyle;
}

+ (BOOL)isXCallBackURLEnabled
{
  return defaults.xCallBackURLEnabled;
}

+ (NSString *)xCallBackURLKey
{
  return defaults.xCallBackURLKey;
}

+ (BOOL)disableCustomKeyboards {
  return defaults.disableCustomKeyboards;
}

+ (BOOL)isPlaySoundOnBellOn {
  return defaults.playSoundOnBell;
}

+ (BOOL)isNotificationOnBellUnfocusedOn {
  return defaults.notificationOnBellUnfocused;
}

+ (BOOL)hapticFeedbackOnBellOff {
  return defaults.hapticFeedbackOnBellOff;
}

+ (BOOL)isOscNotificationsOn {
  return defaults.oscNotifications;
}

+ (BOOL)doInvertVerticalScroll {
  return defaults.invertVerticalScroll;
}

+ (BOOL)compactQuickActions {
  return defaults.compactQuickActions;
}

+ (void)setCompactQuickActions:(BOOL)value {
  defaults.compactQuickActions = value;
}

+ (BOOL)dontUseBlinkSnippetsIndex {
  return defaults.dontUseBlinkSnippetsIndex;
}

+ (BKSnippetDefaultLocation)snippetsDefaultLocation {
  return defaults.snippetsDefaultLocation;
}


+ (void)applyExternalScreenCompensation:(BKOverscanCompensation)value {
  if (UIScreen.screens.count <= 1) {
    return;
  }
  
  UIScreen *screen = UIScreen.screens.lastObject;
  
  switch (value) {
    case BKBKOverscanCompensationNone:
      screen.overscanCompensation = UIScreenOverscanCompensationNone;
      break;
    case BKBKOverscanCompensationScale:
      screen.overscanCompensation = UIScreenOverscanCompensationScale;
      break;
    case BKBKOverscanCompensationInsetBounds:
      screen.overscanCompensation = UIScreenOverscanCompensationInsetBounds;
      break;
    default:
      break;
  }
  
  
}

@end
