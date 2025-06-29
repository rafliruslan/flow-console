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

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class TermView;
@class TermDevice;
@class TermInput;
@class MCPParams;

extern NSString * TermViewReadyNotificationKey;
extern NSString * TermViewBrowserReadyNotificationKey;

@protocol TermViewDeviceProtocol

@property BOOL rawMode;

- (void)viewIsReady;
- (void)viewFontSizeChanged:(NSInteger)size;
- (void)viewWinSizeChanged:(struct winsize)win;
- (void)viewSendString:(NSString *)data;
- (void)viewCopyString:(NSString *)text;
- (void)viewShowAlert:(NSString *)title andMessage:(NSString *)message;
- (void)viewSubmitLine:(NSString *)line;
- (void)viewAPICall:(NSString *)api andJSONRequest:(NSString *)request;
- (void)viewNotify:(NSDictionary *)data;
- (void)viewSelectionChanged;
- (void)viewDidReceiveBellRing;

@end


@class SmarterTermInput;

@interface TermView : UIView

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BOOL hasSelection;
@property (nonatomic, readonly) NSURL *detectedLink;
@property (nonatomic, readonly) NSString *selectedText;
@property (nonatomic) id<TermViewDeviceProtocol> device;
@property (nonatomic) UIEdgeInsets additionalInsets;
@property (nonatomic) BOOL layoutLocked;
@property (nonatomic) CGRect layoutLockedFrame;
@property (nonatomic, readonly) BOOL isReady;
@property (nonatomic, readonly) CGRect selectionRect;
@property (nonatomic, readonly) SmarterTermInput *webView;
@property (nonatomic, readonly) SmarterTermInput *browserView;


- (CGRect)webViewFrame;
- (void)loadWith:(MCPParams *)params;
- (void)reloadWith:(MCPParams *)params;
- (void)clear;
- (void)setWidth:(NSInteger)count;
- (void)setFontSize:(NSNumber *)newSize;
- (void)write:(NSString *)data;
- (void)processKB:(NSString *)str;
- (void)setCursorBlink:(BOOL)state;
- (void)setBoldAsBright:(BOOL)state;
- (void)setBoldEnabled:(NSUInteger)state;
- (void)setClipboardWrite:(BOOL)state;
- (void)applyTheme:(NSString *)themeName;
- (void)copy:(id _Nullable )sender;
- (void)pasteSelection:(id _Nullable)sender;
- (void)terminate;
- (void)reset;
- (void)restore;
- (BOOL)isFocused;

- (void)blur;
- (void)focus;
- (void)reportTouchInPoint:(CGPoint)point;
- (void)cleanSelection;
- (void)increaseFontSize;
- (void)decreaseFontSize;
- (void)resetFontSize;
- (void)writeB64:(NSData *)data;
- (void)displayInput:(NSString *)input;
- (void)apiResponse:(NSString *)name response:(NSString *)response;
- (void)addBrowserWebView:(NSURL *)url agent: (NSString *)agent injectUIO: (BOOL) injectUIO;

- (void)modifySideOfSelection;
- (void)modifySelectionInDirection:(NSString *)direction granularity:(NSString *)granularity;

- (void)pasteString:(NSString *)str;
@end
