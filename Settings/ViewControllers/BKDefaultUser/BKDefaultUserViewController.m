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

#import "BKDefaultUserViewController.h"
#import "BLKDefaults.h"
@interface BKDefaultUserViewController ()

@property (nonatomic, weak) IBOutlet UITextField *userNameField;

@end

@implementation BKDefaultUserViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.userNameField.text = [BLKDefaults defaultUserName];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
  if([string isEqualToString:@" "]){
    return NO;
  }
  return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
  if(self.userNameField.text != nil && ![self.userNameField.text isEqualToString:@""]){
    NSString *sanitisedName = [self.userNameField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    [BLKDefaults setDefaultUserName:sanitisedName];
    [BLKDefaults saveDefaults];
  }
}

@end
