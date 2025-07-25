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


@interface SshRsa : NSObject

- (SshRsa *)initWithLength:(int)bits;
- (SshRsa *)initFromPrivateKey:(NSString *)privateKey passphrase:(NSString *)passphrase;
- (NSString *)privateKeyWithPassphrase:(NSString *)passphrase;
- (NSString *)publicKey;

@end

@interface PKCard : NSObject <NSCoding>

@property NSString *ID;
@property (readonly) NSString *privateKey;
@property (readonly) NSString *publicKey;

+ (void)initialize;
+ (instancetype)withID:(NSString *)ID;
+ (BOOL)saveIDS;
+ (id)saveCard:(NSString *)ID privateKey:(NSString *)privateKey publicKey:(NSString *)publicKey;
+ (NSMutableArray *)all;
+ (NSInteger)count;

- (NSString *)publicKey;
- (NSString *)privateKey;
- (BOOL)isEncrypted;

@end

// Responsible of the lifecycle of the IDCards within the system.
// Offers a directory to the rest, in the same way that you wouldn't offer everything in a file interface.
// Class methods can give us this, then we can connect the TableViewController for rendering, extending them with
// a Decorator (or in this case maybe a custom View that represents the Cell)
