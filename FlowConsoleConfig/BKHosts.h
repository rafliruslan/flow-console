////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Copyright (C) 2016-2018 Flow Console Project
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
#import <CloudKit/CloudKit.h>


enum BKMoshPrediction {
  BKMoshPredictionAdaptive,
  BKMoshPredictionAlways,
  BKMoshPredictionNever,
  BKMoshPredictionExperimental
};

enum BKMoshExperimentalIP {
  BKMoshExperimentalIPNone,
  BKMoshExperimentalIPLocal,
  BKMoshExperimentalIPRemote,
};

enum BKAgentForward {
  BKAgentForwardNo,
  BKAgentForwardConfirm,
  BKAgentForwardYes,
};


@interface BKHosts : NSObject <NSSecureCoding>

@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *hostName;
@property (nonatomic, strong) NSNumber *port;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *passwordRef;
@property (readonly) NSString *password;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *moshServer;
@property (nonatomic, strong) NSString *moshPredictOverwrite;
@property (nonatomic, strong) NSNumber *moshExperimentalIP;
@property (nonatomic, strong) NSNumber *moshPort;
@property (nonatomic, strong) NSNumber *moshPortEnd;
@property (nonatomic, strong) NSString *moshStartup;
@property (nonatomic, strong) NSNumber *prediction;
@property (nonatomic, strong) NSString *proxyCmd;
@property (nonatomic, strong) NSString *proxyJump;
@property (nonatomic, strong) CKRecordID *iCloudRecordId;
@property (nonatomic, strong) NSDate *lastModifiedTime;
@property (nonatomic, strong) NSNumber *iCloudConflictDetected;
@property (nonatomic, strong) BKHosts *iCloudConflictCopy;
@property (nonatomic, strong) NSString *sshConfigAttachment;
@property (nonatomic, strong) NSString *fpDomainsJSON;
@property (nonatomic, strong) NSNumber *agentForwardPrompt;
@property (nonatomic, strong) NSArray<NSString *> *agentForwardKeys;

+ (instancetype)withHost:(NSString *)ID;
+ (void)loadHosts NS_SWIFT_NAME(loadHosts());
+ (void)resetHostsiCloudInformation;
+ (BOOL)saveHosts;
+ (BOOL)forceSaveHosts;
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
        agentForwardKeys:(NSArray<NSString *> *)agentForwardKeys
;
+ (void)_replaceHost:(BKHosts *)newHost;
+ (void)updateHost:(NSString *)host withiCloudId:(CKRecordID *)iCloudId andLastModifiedTime:(NSDate *)lastModifiedTime;
+ (void)markHost:(NSString *)host forRecord:(CKRecord *)record withConflict:(BOOL)hasConflict;
+ (NSMutableArray<BKHosts *> *)all;
+ (NSArray<BKHosts *> *)allHosts;
+ (NSInteger)count;
+ (CKRecord *)recordFromHost:(BKHosts *)host;
+ (BKHosts *)hostFromRecord:(CKRecord *)hostRecord;
+ (instancetype)withiCloudId:(CKRecordID *)record;


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
   agentForwardKeys:(NSArray<NSString *> *)agentForwardKeys;

@end
