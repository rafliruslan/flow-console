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


#import "BKXCallBackUrlConfigurationViewController.h"
#import "BLKDefaults.h"

#define KTextFieldTag 3001

@interface BKXCallBackUrlConfigurationViewController () <UITextFieldDelegate>

@property (weak) IBOutlet UITextField *xCallbackURLKeyTextField;

@end

@implementation BKXCallBackUrlConfigurationViewController {
  UISwitch *_xCallbackUrlEnabledSwitch;
  NSRegularExpression *_validKeyRegexp;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSString *key = [BLKDefaults xCallBackURLKey];
  if (key == nil) {
    key = [NSProcessInfo.processInfo.globallyUniqueString substringToIndex:6];
    [BLKDefaults setXCallBackURLKey:key];
  }
  
  _validKeyRegexp = [[NSRegularExpression alloc] initWithPattern:@"[^a-zA-Z0-9]" options:kNilOptions error:nil];
  
  _xCallbackUrlEnabledSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
  [_xCallbackUrlEnabledSwitch setOn:[BLKDefaults isXCallBackURLEnabled]];
  [_xCallbackUrlEnabledSwitch addTarget:self action:@selector(_onCallBackUrlEnabledChanged) forControlEvents:UIControlEventValueChanged];
  
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"switch"];
}

- (void)_onCallBackUrlEnabledChanged {
  bool isOn = _xCallbackUrlEnabledSwitch.isOn;
  [BLKDefaults setXCallBackURLEnabled:isOn];
  [BLKDefaults saveDefaults];
  NSArray * rows = @[[NSIndexPath indexPathForRow:1 inSection:0]];
  if (isOn) {
    [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationTop];
  } else {
    [self.tableView deleteRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationTop];
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (_xCallbackUrlEnabledSwitch.isOn) {
    return 2;
  } else {
    return 1;
  }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch" forIndexPath:indexPath];
    cell.accessoryView = _xCallbackUrlEnabledSwitch;
    cell.textLabel.text = @"Allow URL actions";
    return cell;
  } else if (indexPath.row == 1) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"URLKey" forIndexPath:indexPath];
    _xCallbackURLKeyTextField = [cell viewWithTag:KTextFieldTag];
    _xCallbackURLKeyTextField.text = [BLKDefaults xCallBackURLKey];
    return cell;
  }
  
    
  return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"default"];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  return NO;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  if (string.length == 0) {
    return YES;
  }
  
  NSArray *matches = [_validKeyRegexp matchesInString:string options:kNilOptions range:NSMakeRange(0, string.length)];
  
  NSUInteger oldLength = [textField.text length];
  NSUInteger replacementLength = [string length];
  NSUInteger rangeLength = range.length;
  
  NSUInteger newLength = oldLength - rangeLength + replacementLength;
  
  return matches.count == 0 && newLength <= 100;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  NSString *urlKey = [BLKDefaults xCallBackURLKey] ?: @"<URL key>";
  return [NSString stringWithFormat: @"Use x-callback-url for automation and inter-app communication. Your URL key should be kept secret.\n\nExample:\nblinkshell://run?key=%@&cmd=ls", urlKey];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  [BLKDefaults setXCallBackURLKey:textField.text];
  [BLKDefaults saveDefaults];
  [self.tableView reloadData];
}

@end
