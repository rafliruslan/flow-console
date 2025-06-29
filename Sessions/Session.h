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

#include <sys/ioctl.h>

#import "TermDevice.h"

@class SessionParams;

@protocol SessionDelegate

- (void)sessionFinished;

@end

@interface Session : NSObject {
  pthread_t _tid;
  TermStream *_stream;
  TermDevice *_device;
}

@property (strong, atomic) SessionParams *sessionParams;
@property (strong) TermStream *stream;
@property (strong) TermDevice *device;
@property (readonly) pthread_t tid;

@property (weak) id<SessionDelegate> delegate;

- (id)init __unavailable;
- (id)initWithDevice:(TermDevice *)device andParams:(SessionParams *)params;
- (void)executeWithArgs:(NSString *)args;
- (void)executeAttachedWithArgs:(NSString *)args;
- (int)main:(int)argc argv:(char **)argv;
- (void)main_cleanup;
- (void)sigwinch;
- (void)kill;
- (void)suspend;
- (void)handleControl:(NSString *)control;
- (void)setActiveSession;

@end
