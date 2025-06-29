//////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Copyright (C) 2016-2024 Flow Console Project
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


#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include "ios_patches.h"

void __blink_ios_patches(void) {
  // Check to class method of UIPressAndHoldPopoverController
  // Opened Radar so this can be fixed or exposed.
  // We won't implement a different fix because plan is to move away from Hterm.
  // Also an issue on macOS: https://apple.stackexchange.com/questions/332769/macos-disable-popup-showing-accented-characters-when-holding-down-a-key
  Class cls = NSClassFromString(@"UIPressAndHoldPopoverController");
  
  SEL selector = sel_getUid("canPresentPressAndHoldPopoverForEvent:");
  Method method = class_getClassMethod(cls, selector);
  IMP override = imp_implementationWithBlock(^BOOL(id me, void* arg0) {
    return NO;
  });
  method_setImplementation(method, override);
}
