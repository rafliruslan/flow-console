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

@import CloudKit;
@import UserNotifications;

#import "BKiCloudConfigurationViewController.h"
#import "BKUserConfigurationManager.h"

@interface BKiCloudConfigurationViewController ()

@property (nonatomic, weak) IBOutlet UISwitch *toggleiCloudSync;
@property (nonatomic, weak) IBOutlet UISwitch *toggleiCloudKeysSync;

@end

@implementation BKiCloudConfigurationViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setupUI];
}

- (void)setupUI
{
  [_toggleiCloudSync setOn:[BKUserConfigurationManager userSettingsValueForKey:@"iCloudSync"]];
  [_toggleiCloudKeysSync setOn:[BKUserConfigurationManager userSettingsValueForKey:@"iCloudKeysSync"]];
}

#pragma mark - Action Method

- (IBAction)didToggleSwitch:(id)sender
{
  UISwitch *toggleSwitch = (UISwitch *)sender;
  if (toggleSwitch == _toggleiCloudSync) {
    [self checkiCloudStatusAndToggle];
    [self.tableView reloadData];
  } else if (toggleSwitch == _toggleiCloudKeysSync) {
    [BKUserConfigurationManager setUserSettingsValue:_toggleiCloudKeysSync.isOn forKey:@"iCloudKeysSync"];
  }
}

- (void)checkiCloudStatusAndToggle
{
  [[CKContainer defaultContainer] accountStatusWithCompletionHandler:
				    ^(CKAccountStatus accountStatus, NSError *error) {
              
    dispatch_async(dispatch_get_main_queue(), ^{

      if (accountStatus == CKAccountStatusNoAccount) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Please login to your iCloud account to enable Sync" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        [_toggleiCloudSync setOn:NO];
      } else {
        if (_toggleiCloudSync.isOn) {
          [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert)
                                                                              completionHandler:^(BOOL granted, NSError *_Nullable error){}];
          [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        [BKUserConfigurationManager setUserSettingsValue:_toggleiCloudSync.isOn forKey:@"iCloudSync"];
      }
    });
  }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  if (_toggleiCloudSync.isOn) {
    return [super numberOfSectionsInTableView:tableView];
  } else {
    return 1;
  }
}


@end
