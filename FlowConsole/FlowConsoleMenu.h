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


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * BlinkActionID NS_TYPED_EXTENSIBLE_ENUM;

extern const BlinkActionID BlinkActionSnippets;
extern const BlinkActionID BlinkActionTabClose;
extern const BlinkActionID BlinkActionTabCreate;
extern const BlinkActionID BlinkActionLayoutMenu;
extern const BlinkActionID BlinkActionMoreMenu;
extern const BlinkActionID BlinkActionChangeLayout;
extern const BlinkActionID BlinkActionToggleLayoutLock;
extern const BlinkActionID BlinkActionToggleGeoTrack;
extern const BlinkActionID BlinkActionToggleCompactActions;

extern NSString * BLINK_ACTION_TOGGLE_PREFIX;
typedef NSString * BlinkActionAppearance NS_TYPED_EXTENSIBLE_ENUM;

extern const BlinkActionAppearance BlinkActionAppearanceIcon;
extern const BlinkActionAppearance BlinkActionAppearanceIconLeading;
extern const BlinkActionAppearance BlinkActionAppearanceIconTrailing;
extern const BlinkActionAppearance BlinkActionAppearanceIconCircle;

@class TermController;
@class SpaceController;

@protocol CommandsHUDDelegate <NSObject>

- (TermController * _Nullable)currentTerm;
- (SpaceController * _Nullable)spaceController;

@end


@interface BlinkMenu : UIView

@property __nullable __weak id<CommandsHUDDelegate> delegate;

@property UIView *tapToCloseView;

- (CGSize)layoutForSize:(CGSize)size;
- (void)buildMenuWithIDs:(NSArray<BlinkActionID> *)ids andAppearance:(NSDictionary<BlinkActionID, BlinkActionAppearance> *) appearance;

@end


NS_ASSUME_NONNULL_END
