//////////////////////////////////////////////////////////////////////////////////
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


#import "XCConfig.h"

@implementation XCConfig

+ (NSString *)_valueForKey:(NSString *)key {
  NSBundle *bundle = [NSBundle bundleForClass:[XCConfig self]];
  return [bundle objectForInfoDictionaryKey:key];
}

+ (NSString *) infoPlistRevCatPubliKey {
  return [self _valueForKey:@"FLOW_CONSOLE_REVCAT_PUBKEY"];
}

+ (NSString *) infoPlistWhatsNewURL {
  return [self _valueForKey:@"FLOW_CONSOLE_WHATS_NEW_URL"];
}

+ (NSString *) infoPlistConversionOpportunityURL {
  return [self _valueForKey:@"FLOW_CONSOLE_CONVERSION_OPPORTUNITY_URL"];
}

+ (NSString *) infoPlistKeyChainID1 {
  return [self _valueForKey:@"FLOW_CONSOLE_KEYCHAIN_ID1"];
}

+ (NSString *) infoPlistCloudID {
  return [self _valueForKey:@"FLOW_CONSOLE_CLOUD_ID"];
}

+ (NSString *) infoPlistFullCloudID {
  return [NSString stringWithFormat:@"iCloud.%@", [self infoPlistCloudID]];
}

+ (NSString *) infoPlistGroupID {
  return [self _valueForKey:@"FLOW_CONSOLE_GROUP_ID"];
}

+ (NSString *) infoPlistFullGroupID {
  return [NSString stringWithFormat:@"group.%@", [self infoPlistGroupID]];
}


@end
