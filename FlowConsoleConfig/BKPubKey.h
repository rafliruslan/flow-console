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
#import <UIKit/UIKit.h>


typedef enum: NSUInteger {
  BKPubKeyStorageTypeKeyChain = 0,
  BKPubKeyStorageTypeSecureEnclave,
  BKPubKeyStorageTypeiCloudKeyChain,
  BKPubKeyStorageTypePlatformKey, // passkey
  BKPubKeyStorageTypeSecurityKey,
  BKPubKeyStorageTypeDistributed, // Bunkr master key
} BKPubKeyStorageType;

@interface BKPubKey : NSObject <NSSecureCoding, UIActivityItemSource>

@property (nonnull) NSString *ID; // unique name of the key
@property (nonnull) NSString *tag; // unique identifier of the key
@property (readonly, nonnull)  NSString *publicKey;
@property (readonly, nullable) NSString *keyType;
@property (readonly, nullable) NSString *certType;
@property (readonly) BKPubKeyStorageType storageType;
@property (readonly, nullable) NSData * rawAttestationObject;
@property (readonly, nullable) NSString * rpId;

- (nullable NSString *)loadPrivateKey;
- (nullable NSString *)loadCertificate;

+ (void)initialize;
+ (nullable instancetype)withID:(nullable NSString *)ID;

- (nullable instancetype)initWithID:(nonnull NSString *)ID
                                tag:(nonnull NSString *)tag
                          publicKey:(nonnull NSString *)publicKey
                            keyType:(nonnull NSString *)keyType
                           certType:(nullable NSString *)certType
               rawAttestationObject:(nullable NSData *)rawAttestationObject
                               rpId:(nullable NSString *)rpId
                        storageType:(BKPubKeyStorageType)storageType;

+ (void)loadIDS;
+ (BOOL)saveIDS;
+ (BOOL)saveGroupContainerKeys:(NSArray<BKPubKey *> *)keys;
+ (void)addCard:(nonnull BKPubKey *)pubKey;
- (void)storePrivateKeyInKeychain:(nonnull NSString *) privateKey;
- (void)storeCertificateInKeychain:(nullable NSString *) certificate;
+ (nonnull NSArray<BKPubKey *> *)all;
+ (NSInteger)count;
- (BOOL)isEncrypted;
- (void)removeCard;

// Deprecated. Use loadPrivateKey
- (nullable NSString *)privateKey DEPRECATED_ATTRIBUTE;

@end
