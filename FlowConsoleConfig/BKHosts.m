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

#import "BKHosts.h"
#import "BKiCloudSyncHandler.h"
#import "UICKeyChainStore.h"
#import "FlowConsolePaths.h"
#import <FlowConsoleConfig/FlowConsoleConfig-Swift.h>

NSMutableArray *__hosts;

static UICKeyChainStore *__get_keychain() {
  return [UICKeyChainStore keyChainStoreWithService:@"sh.blink.pwd"];
}

@implementation BKHosts

+ (BOOL) supportsSecureCoding {
  return YES;
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if (!self) {
    return self;
  }
  
  NSSet *strings = [NSSet setWithObjects:NSString.class, nil];
  NSSet *numbers = [NSSet setWithObjects:NSNumber.class, nil];

  _host = [coder decodeObjectOfClasses:strings forKey:@"host"];
  _hostName = [coder decodeObjectOfClasses:strings forKey:@"hostName"];
  _port = [coder decodeObjectOfClasses:numbers forKey:@"port"];
  _user = [coder decodeObjectOfClasses:strings forKey:@"user"];
  _passwordRef = [coder decodeObjectOfClasses:strings forKey:@"passwordRef"];
  _key = [coder decodeObjectOfClasses:strings forKey:@"key"];
  _moshServer = [coder decodeObjectOfClasses:strings forKey:@"moshServer"];
  _moshPredictOverwrite = [coder decodeObjectOfClasses:strings forKey:@"moshPredictOverwrite"];
  _moshExperimentalIP = [coder decodeObjectOfClasses:numbers forKey:@"moshExperimentalIP"];
  _moshPort = [coder decodeObjectOfClasses:numbers forKey:@"moshPort"];
  _moshPortEnd = [coder decodeObjectOfClasses:numbers forKey:@"moshPortEnd"];
  _moshStartup = [coder decodeObjectOfClasses:strings forKey:@"moshStartup"];
  _prediction = [coder decodeObjectOfClasses:numbers forKey:@"prediction"];
  _lastModifiedTime = [coder decodeObjectOfClass:[NSDate class] forKey:@"lastModifiedTime"];
  _iCloudRecordId = [coder decodeObjectOfClass:[CKRecordID class] forKey:@"iCloudRecordId"];
  _iCloudConflictDetected = [coder decodeObjectOfClasses:numbers forKey:@"iCloudConflictDetected"];
  _proxyCmd = [coder decodeObjectOfClasses:strings forKey:@"proxyCmd"];
  _proxyJump = [coder decodeObjectOfClasses:strings forKey:@"proxyJump"];
  _sshConfigAttachment = [coder decodeObjectOfClasses:strings forKey:@"sshConfigAttachment"];
  _fpDomainsJSON = [coder decodeObjectOfClasses:strings forKey:@"fpDomainsJSON"];
  _agentForwardPrompt = [coder decodeObjectOfClasses:numbers forKey:@"agentForwardPrompt"];
  _agentForwardKeys = [coder decodeArrayOfObjectsOfClass:NSString.class forKey:@"agentForwardKeys"];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_host forKey:@"host"];
  [encoder encodeObject:_hostName forKey:@"hostName"];
  [encoder encodeObject:_port forKey:@"port"];
  [encoder encodeObject:_user forKey:@"user"];
  [encoder encodeObject:_passwordRef forKey:@"passwordRef"];
  [encoder encodeObject:_key forKey:@"key"];
  [encoder encodeObject:_moshServer forKey:@"moshServer"];
  [encoder encodeObject:_moshPredictOverwrite forKey:@"moshPredictOverwrite"];
  [encoder encodeObject:_moshExperimentalIP forKey:@"moshExperimentalIP"];
  [encoder encodeObject:_moshPort forKey:@"moshPort"];
  [encoder encodeObject:_moshPortEnd forKey:@"moshPortEnd"];
  [encoder encodeObject:_moshStartup forKey:@"moshStartup"];
  [encoder encodeObject:_prediction forKey:@"prediction"];
  [encoder encodeObject:_lastModifiedTime forKey:@"lastModifiedTime"];
  [encoder encodeObject:_iCloudRecordId forKey:@"iCloudRecordId"];
  [encoder encodeObject:_iCloudConflictDetected forKey:@"iCloudConflictDetected"];
  [encoder encodeObject:_proxyCmd forKey:@"proxyCmd"];
  [encoder encodeObject:_proxyJump forKey:@"proxyJump"];
  [encoder encodeObject:_sshConfigAttachment forKey:@"sshConfigAttachment"];
  [encoder encodeObject:_fpDomainsJSON forKey:@"fpDomainsJSON"];
  [encoder encodeObject:_agentForwardPrompt forKey:@"agentForwardPrompt"];
  [encoder encodeObject:_agentForwardKeys forKey:@"agentForwardKeys"];
}

- (id)initWithAlias:(NSString *)alias
           hostName:(NSString *)hostName
            sshPort:(NSString *)sshPort
               user:(NSString *)user
        passwordRef:(NSString *)passwordRef
            hostKey:(NSString *)hostKey
         moshServer:(NSString *)moshServer
      moshPortRange:(NSString *)moshPortRange
moshPredictOverwrite:(NSString *)moshPredictOverwrite
 moshExperimentalIP:(enum BKMoshExperimentalIP)moshExperimentalIP
         startUpCmd:(NSString *)startUpCmd
         prediction:(enum BKMoshPrediction)prediction
           proxyCmd:(NSString *)proxyCmd
          proxyJump:(NSString *)proxyJump
sshConfigAttachment:(NSString *)sshConfigAttachment
      fpDomainsJSON:(NSString *)fpDomainsJSON
 agentForwardPrompt:(enum BKAgentForward)agentForwardPrompt
   agentForwardKeys:(NSArray<NSString *> *)agentForwardKeys
{
  self = [super init];
  if (self) {
    _host = alias;
    _hostName = hostName;
    if (![sshPort isEqualToString:@""]) {
      _port = [NSNumber numberWithInt:sshPort.intValue];
    }
    _user = user;
    _passwordRef = passwordRef;
    _key = hostKey;
    if (![moshServer isEqualToString:@""]) {
      _moshServer = moshServer;
    }
    if (![moshPredictOverwrite isEqualToString:@""]) {
      _moshPredictOverwrite = moshPredictOverwrite;
    }
    if (![moshPortRange isEqualToString:@""]) {
      NSArray<NSString *> *parts = [moshPortRange componentsSeparatedByString:@":"];
      _moshPort = [NSNumber numberWithInt:parts[0].intValue];
      if (parts.count > 1) {
        _moshPortEnd = [NSNumber numberWithInt:parts[1].intValue];
      }
    }
    _moshStartup = startUpCmd;
    _moshExperimentalIP = [NSNumber numberWithInt:moshExperimentalIP];
    _prediction = [NSNumber numberWithInt:prediction];
    _proxyCmd = proxyCmd;
    _proxyJump = proxyJump;
    _sshConfigAttachment = sshConfigAttachment;
    _fpDomainsJSON = fpDomainsJSON;
    _agentForwardPrompt = [NSNumber numberWithInt: agentForwardPrompt];
    _agentForwardKeys = agentForwardKeys;
  }
  return self;
}

- (NSString *)password
{
  if (!_passwordRef) {
    return nil;
  } else {
    return [__get_keychain() stringForKey:_passwordRef];
  }
}

+ (instancetype)withHost:(NSString *)aHost
{
  for (BKHosts *host in __hosts) {
    if ([host->_host isEqualToString:aHost]) {
      return host;
    }
  }
  return nil;
}

+ (instancetype)withiCloudId:(CKRecordID *)record
{
  for (BKHosts *host in __hosts) {
    if ([host->_iCloudRecordId isEqual:record]) {
      return host;
    }
  }
  return nil;
}

+ (NSMutableArray<BKHosts *> *)all
{
  if (!__hosts.count) {
    [BKHosts loadHosts];
  }
  return __hosts;
}

+ (NSArray<BKHosts *> *)allHosts
{
  if (!__hosts.count) {
    [BKHosts loadHosts];
  }
  return [__hosts copy];
}

+ (NSInteger)count
{
  return [[self all] count];
}

+ (instancetype)saveHost:(NSString *)host
             withNewHost:(NSString *)newHost
                hostName:(NSString *)hostName
                 sshPort:(NSString *)sshPort
                    user:(NSString *)user
                password:(NSString *)password
                 hostKey:(NSString *)hostKey
              moshServer:(NSString *)moshServer
    moshPredictOverwrite:(NSString *)moshPredictOverwrite
      moshExperimentalIP:(enum BKMoshExperimentalIP)moshExperimentalIP
           moshPortRange:(NSString *)moshPortRange
              startUpCmd:(NSString *)startUpCmd
              prediction:(enum BKMoshPrediction)prediction
                proxyCmd:(NSString *)proxyCmd
               proxyJump:(NSString *)proxyJump
     sshConfigAttachment:(NSString *)sshConfigAttachment
           fpDomainsJSON:(NSString *)fpDomainsJSON
      agentForwardPrompt:(enum BKAgentForward)agentForwardPrompt
        agentForwardKeys:(NSArray *)agentForwardKeys
{
  NSString *pwdRef = @"";
  if (password) {
    pwdRef = [newHost stringByAppendingString:@".pwd"];
    [__get_keychain() setString:password forKey:pwdRef];
  }

  BKHosts *bkHost = [BKHosts withHost:host];
  // Save password to keychain if it changed
  if (!bkHost) {
    bkHost = [[BKHosts alloc] initWithAlias:newHost
                                   hostName:hostName
                                    sshPort:sshPort
                                       user:user
                                passwordRef:pwdRef
                                    hostKey:hostKey
                                 moshServer:moshServer
                              moshPortRange:moshPortRange
                       moshPredictOverwrite:moshPredictOverwrite
                         moshExperimentalIP:moshExperimentalIP
                                 startUpCmd:startUpCmd
                                 prediction:prediction
                                   proxyCmd:proxyCmd
                                  proxyJump:proxyJump
                        sshConfigAttachment:sshConfigAttachment
                              fpDomainsJSON:fpDomainsJSON
                         agentForwardPrompt:agentForwardPrompt
                           agentForwardKeys:agentForwardKeys
    ];
    [__hosts addObject:bkHost];
  } else {
    bkHost.host = newHost;
    bkHost.hostName = hostName;
    if (![sshPort isEqualToString:@""]) {
      bkHost.port = [NSNumber numberWithInt:sshPort.intValue];
    } else {
      bkHost.port = nil;
    }
    bkHost.user = user;
    bkHost.passwordRef = pwdRef;
    bkHost.key = hostKey;
    bkHost.moshServer = moshServer;
    bkHost.moshPredictOverwrite = moshPredictOverwrite;
    bkHost.moshExperimentalIP = [NSNumber numberWithInt:moshExperimentalIP];
    bkHost.moshPort = nil;
    bkHost.moshPortEnd = nil;
    if (![moshPortRange isEqualToString:@""]) {
      NSArray<NSString *> *parts = [moshPortRange componentsSeparatedByString:@":"];
      bkHost.moshPort = [NSNumber numberWithInt:parts[0].intValue];
      if (parts.count > 1) {
        bkHost.moshPortEnd = [NSNumber numberWithInt:parts[1].intValue];
      }
    }
    bkHost.moshStartup = startUpCmd;
    bkHost.prediction = [NSNumber numberWithInt:prediction];
    bkHost.proxyCmd = proxyCmd;
    bkHost.proxyJump = proxyJump;
    bkHost.sshConfigAttachment = sshConfigAttachment;
    bkHost.fpDomainsJSON = fpDomainsJSON;
    bkHost.agentForwardPrompt = [NSNumber numberWithInt: agentForwardPrompt];
    bkHost.agentForwardKeys = agentForwardKeys;
  }
  if (![BKHosts saveHosts]) {
    return nil;
  }
  return bkHost;
}

// Helper to replace a Host, but won't process changes like passwords, etc...
+ (void)_replaceHost:(BKHosts *)newHost
{
  for (int i = 0; i < __hosts.count; i++) {
    BKHosts *host = __hosts[i];
    if ([host->_host isEqualToString:newHost->_host]) {
      __hosts[i] = newHost;
      [self updateHost:host.host withiCloudId: host.iCloudRecordId andLastModifiedTime:[NSDate now]];
      return;
    }
  }
}

+ (void)updateHost:(NSString *)host withiCloudId:(CKRecordID *)iCloudId andLastModifiedTime:(NSDate *)lastModifiedTime
{
  BKHosts *bkHost = [BKHosts withHost:host];
  if (bkHost) {
    bkHost.iCloudRecordId = iCloudId;
    bkHost.lastModifiedTime = lastModifiedTime;
  }
  [BKHosts saveHosts];
}

+ (void)markHost:(NSString *)host forRecord:(CKRecord *)record withConflict:(BOOL)hasConflict
{
  BKHosts *bkHost = [BKHosts withHost:host];
  if (bkHost) {
    if (hasConflict && record != nil) {
      BKHosts *conflictCopy = [BKHosts hostFromRecord:record];
      conflictCopy.iCloudRecordId = record.recordID;
      conflictCopy.lastModifiedTime = record.modificationDate;
      bkHost.iCloudConflictCopy = conflictCopy;
    }
    if (!hasConflict) {
      bkHost.iCloudConflictCopy = nil;
    }
    bkHost.iCloudConflictDetected = [NSNumber numberWithBool:hasConflict];
  }
  [BKHosts saveHosts];
}

+ (BOOL)saveHosts {
  return [self saveHostsAndEnforce:false];
}

+ (BOOL)forceSaveHosts {
  return [self saveHostsAndEnforce:true];
}

+ (BOOL)saveHostsAndEnforce:(BOOL)force
{
  // App may start in the background and Hosts file may not load, causing hosts to be empty.
  // Then the user would load the app, and the Hosts would be empty, overwriting a never read hosts file.
  // This way we differentiate if saving is due to user, or part of the UI flow.
  if (!__hosts && !force) {
    return NO;
  }
  
  NSError *error = nil;
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:__hosts
                                       requiringSecureCoding:YES
                                                       error:&error];
  if (error || !data) {
    NSLog(@"[BKHosts] Failed to archive hosts to data: %@", error);
    return NO;
  }
  
  BOOL result = [data writeToFile:[FlowConsolePaths blinkHostsFile]
                          options:NSDataWritingAtomic | NSDataWritingFileProtectionNone
                            error:&error];
  
  if (error || !result) {
    NSLog(@"[BKHosts] Failed to write data to file: %@", error);
    return NO;
  }
  
  [self saveAllToSSHConfig];

  return result;
}

// Used when importing hosts. Dumps iCloud information so Hosts list is considered new against it.
+ (void)resetHostsiCloudInformation
{
  for (BKHosts *host in __hosts) {
    host.iCloudRecordId = nil;
    host.iCloudConflictCopy = nil;
    host.iCloudConflictDetected = nil;
  }
  
  [self saveHosts];
}

+ (void)loadHosts {
  __hosts = [[NSMutableArray alloc] init];
  
  NSError *error = nil;
  NSData *data = [NSData dataWithContentsOfFile:[FlowConsolePaths blinkHostsFile]
                                        options:NSDataReadingMappedIfSafe
                                          error:&error];
  
  if (error || !data) {
    NSLog(@"[BKHosts] Failed to load data: %@", error);
    return;
  }
  NSArray *result =
    [NSKeyedUnarchiver unarchivedArrayOfObjectsOfClass:[BKHosts class]
                                              fromData:data
                                                 error:&error];
  
  if (error || !result) {
    NSLog(@"[BKHosts] Failed to unarchive data: %@", error);
    return;
  }
  
  __hosts = [result mutableCopy];
}

+ (CKRecord *)recordFromHost:(BKHosts *)host
{

  CKRecord *hostRecord = nil;
  if (host.iCloudRecordId) {
    hostRecord = [[CKRecord alloc] initWithRecordType:@"BKHost" recordID:host.iCloudRecordId];
  } else {
    hostRecord = [[CKRecord alloc] initWithRecordType:@"BKHost"];
  }
  [hostRecord setValue:host.host forKey:@"host"];
  [hostRecord setValue:host.hostName forKey:@"hostName"];
  [hostRecord setValue:host.key forKey:@"key"];
  
  [hostRecord setValue:host.moshPort forKey:@"moshPort"];
  [hostRecord setValue:host.moshPortEnd forKey:@"moshPortEnd"];
  [hostRecord setValue:host.moshServer forKey:@"moshServer"];
  [hostRecord setValue:host.moshPredictOverwrite forKey:@"moshPredictOverwrite"];
  [hostRecord setValue:host.moshExperimentalIP forKey:@"moshExperimentalIP"];
  [hostRecord setValue:host.moshStartup forKey:@"moshStartup"];
  [hostRecord setValue:host.password forKey:@"password"];
  [hostRecord setValue:host.passwordRef forKey:@"passwordRef"];
  [hostRecord setValue:host.port forKey:@"port"];
  [hostRecord setValue:host.prediction forKey:@"prediction"];
  [hostRecord setValue:host.user forKey:@"user"];
  [hostRecord setValue:host.proxyCmd forKey:@"proxyCmd"];
  [hostRecord setValue:host.proxyJump forKey:@"proxyJump"];
  [hostRecord setValue:host.sshConfigAttachment forKey:@"sshConfigAttachment"];
  [hostRecord setValue:host.fpDomainsJSON forKey:@"fpDomainsJSON"];
  [hostRecord setValue:host.agentForwardPrompt forKey:@"agentForwardPrompt"];
  [hostRecord setValue:host.agentForwardKeys forKey:@"agentForwardKeys"];
  return hostRecord;
}

+ (BKHosts *)hostFromRecord:(CKRecord *)hostRecord
{
  NSNumber *moshPort    = [hostRecord valueForKey:@"moshPort"];
  NSNumber *moshPortEnd = [hostRecord valueForKey:@"moshPortEnd"];
  
  NSString *moshPortRange = moshPort ? moshPort.stringValue : @"";
  if (moshPort && moshPortEnd) {
    moshPortRange = [NSString stringWithFormat:@"%@:%@", moshPortRange, moshPortEnd.stringValue];
  }
  
  
  BKHosts *host = [[BKHosts alloc] initWithAlias:[hostRecord valueForKey:@"host"]
                                        hostName:[hostRecord valueForKey:@"hostName"]
                                         sshPort:[hostRecord valueForKey:@"port"] ? [[hostRecord valueForKey:@"port"] stringValue] : @""
                                            user:[hostRecord valueForKey:@"user"]
                                     passwordRef:[hostRecord valueForKey:@"passwordRef"]
                                         hostKey:[hostRecord valueForKey:@"key"]
                                      moshServer:[hostRecord valueForKey:@"moshServer"]
                                   moshPortRange:moshPortRange
                            moshPredictOverwrite:[hostRecord valueForKey:@"moshPredictOverwrite"]
                            moshExperimentalIP:[[hostRecord valueForKey:@"moshExperimentalIP"] intValue]
                                      startUpCmd:[hostRecord valueForKey:@"moshStartup"]
                                      prediction:[[hostRecord valueForKey:@"prediction"] intValue]
                                        proxyCmd:[hostRecord valueForKey:@"proxyCmd"]
                                       proxyJump:[hostRecord valueForKey:@"proxyJump"]
                             sshConfigAttachment:[hostRecord valueForKey:@"sshConfigAttachment"]
                                   fpDomainsJSON:[hostRecord valueForKey:@"fpDomainsJSON"]
                              agentForwardPrompt:[[hostRecord valueForKey:@"agentForwardPrompt"] intValue]
                                agentForwardKeys:[hostRecord valueForKey:@"agentForwardKeys"]
  ];

  return host;
}

@end
