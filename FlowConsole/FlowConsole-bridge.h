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


#ifndef FlowConsole_bridge_h
#define FlowConsole_bridge_h

#include <stdio.h>
#include <pthread.h>

typedef int socket_t;
extern void __thread_ssh_execute_command(const char *command, socket_t in, socket_t out);
extern int ios_dup2(int fd1, int fd2);
extern void ios_exit(int errorCode) __dead2; // set error code and exits from the thread.

typedef void (*mosh_state_callback) (const void *context, const void *buffer, size_t size);

#import "BLKDefaults.h"
#import "UIDevice+DeviceName.h"
#import "BKHosts.h"
#import "FlowConsolePaths.h"
#import "DeviceInfo.h"
#import "LayoutManager.h"
#import "BKUserConfigurationManager.h"
#import "Session.h"
#import "MCPSession.h"
#import "TermDevice.h"
#import "KBWebViewBase.h"
#import "openurl.h"
#import "BKPubKey.h"
#import "BKHosts.h"
#import "UICKeyChainStore.h"
#import "BKiCloudSyncHandler.h"
#import "UIApplication+Version.h"
#import "AppDelegate.h"
#import "BKLinkActions.h"
#import "TokioSignals.h"
#import "FlowConsoleMenu.h"
#import "GeoManager.h"
#import "mosh/moshiosbridge.h"


#endif /* FlowConsole_bridge_h */
