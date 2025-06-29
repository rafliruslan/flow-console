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


#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface KBWebViewBase : WKWebView

@property (readonly) UIKeyModifierFlags trackingModifierFlags;

- ( UIView * _Nullable )selectionView;
- (void)reportFocus:(BOOL) value;
- (void)reportStateReset:(BOOL)hasSelection;
- (void)reportLang:(NSString *) lang isHardwareKB: (BOOL)isHardwareKB;
- (void)reportHex:(NSString *) hex;
- (void)reportPress:(UIKeyModifierFlags)mods keyId:(NSString *)keyId;
- (void)reportToolbarPress:(UIKeyModifierFlags)mods keyId:(NSString *)keyId;
- (void)reportToolbarModifierFlags:(UIKeyModifierFlags)flags;
- (void)onSelection:(NSDictionary *)args;
- (void)onCommand:(NSString *)command;
- (void)setHasSelection:(BOOL)value;
- (void)removeAssistantsFromView;
- (void)removeAssistantsFromContentView;
- (void)report:(NSString *)cmd arg:(NSObject *)arg;
- (void)ready;
- (void)onMods;
- (void)onOut:(NSString *)data;
- (void)onIME:(NSString *)event data:(NSString *)data;
- (void)setTrackingModifierFlags:(UIKeyModifierFlags)trackingModifierFlags;
- (void)terminate;

- (void)_keyboardDidChangeFrame:(NSNotification *)notification;
- (void)_keyboardWillChangeFrame:(NSNotification *)notification;
- (void)_keyboardWillShow:(NSNotification *)notification;
- (void)_keyboardWillHide:(NSNotification *)notification;
- (void)_keyboardDidHide:(NSNotification *)notification;
- (void)_keyboardDidShow:(NSNotification *)notification;

- (BOOL)canBeFocused;

- (void)hideCaret;

- (void)showCaret;


@end

NS_ASSUME_NONNULL_END
