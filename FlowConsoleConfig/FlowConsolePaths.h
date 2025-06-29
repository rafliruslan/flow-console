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

@interface FlowConsolePaths : NSObject

+ (NSString *) homePath;
+ (NSURL *)homeURL;

+ (NSString *) groupContainerPath;
+ (NSString *) documentsPath;
+ (NSString *) iCloudDriveDocuments;

// ~/.blink
+ (NSString *) blink;
// ~/.blink-build
+ (NSString *)blinkBuild;
// ~/.blink/agents
+ (NSString *)blinkAgentSettings;

// ~/.ssh
+ (NSString *) ssh;

+ (NSURL *) blinkURL;
+ (NSURL *) blinkAgentSettingsURL;
+ (NSURL *) blinkBuildURL;
+ (NSURL *) blinkBuildTokenURL;
+ (NSURL *)blinkBuildStagingMarkURL;
+ (NSURL *) sshURL;
+ (NSURL *) blinkSSHConfigFileURL;
+ (NSURL *) blinkGlobalSSHConfigFileURL;
+ (NSURL *) blinkKBConfigURL;

+ (NSString *) blinkKeysFile;
+ (NSString *) blinkHostsFile;
+ (NSString *) blinkDefaultsFile;
+ (NSString *) blinkSyncItemsFile;
+ (NSString *) blinkProfileFile;

+ (NSURL *) historyURL;
+ (NSString *) historyFile;
+ (NSString *) knownHostsFile;

+ (NSURL *) localSnippetsLocationURL;
+ (NSURL *) iCloudSnippetsLocationURL;

+ (NSURL *)fileProviderReplicatedURL;
+ (NSURL *)fileProviderRemotesURLWithRecreate:(BOOL)recreate;

+ (NSURL *)fileProviderErrorLogURL;
+ (NSURL *)blinkCodeErrorLogURL;

+ (void)linkICloudDriveIfNeeded;
+ (void)linkDocumentsIfNeeded;

@end
