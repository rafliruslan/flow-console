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

#import "BKFontCreateViewController.h"
#import "BKFont.h"
#import "BKSettingsFileDownloader.h"
#import "BKLinkActions.h"

@interface BKFontCreateViewController ()

@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITableViewCell *galleryLinkCell;
@property (strong, nonatomic) NSData *tempFileData;
@property (assign, nonatomic) BOOL downloadCompleted;

@end

@implementation BKFontCreateViewController

- (void)viewWillDisappear:(BOOL)animated
{
  if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
    [self performSegueWithIdentifier:@"unwindFromAddFont" sender:self];
    [BKSettingsFileDownloader cancelRunningDownloads];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
  [super viewWillDisappear:animated];
}

#pragma mark - Validations

- (IBAction)urlTextDidChange:(id)sender
{
  NSURL *url = [NSURL URLWithString:_urlTextField.text];
  if (url && url.scheme && url.host) {
    self.importButton.enabled = YES;
  } else {
    self.importButton.enabled = NO;
  }
}

- (IBAction)nameFieldDidChange:(id)sender
{
  if (self.nameTextField.text.length > 0 && _downloadCompleted) {
    self.navigationItem.rightBarButtonItem.enabled = YES;
  } else {
    self.navigationItem.rightBarButtonItem.enabled = NO;
  }
}


- (IBAction)importButtonClicked:(id)sender
{
  NSString *fontUrl = _urlTextField.text;
  if (fontUrl.length > 4 && [[fontUrl substringFromIndex:[fontUrl length] - 4] isEqualToString:@".css"]) {
    if ([fontUrl rangeOfString:@"github.com"].location != NSNotFound && [fontUrl rangeOfString:@"/raw/"].location == NSNotFound) {
      // Replace HTML versions of fonts with the raw version
      fontUrl = [fontUrl stringByReplacingOccurrencesOfString:@"/blob/" withString:@"/raw/"];
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self configureImportButtonForCancel];
    self.urlTextField.enabled = NO;
    [BKSettingsFileDownloader downloadFileAtUrl:fontUrl
			      expectedMIMETypes:@[@"text/css", @"text/plain"]
                          withCompletionHandler:^(NSData *fileData, NSError *error) {
                            if (error == nil) {
                              [self performSelectorOnMainThread:@selector(downloadCompletedWithFilePath:) withObject:fileData waitUntilDone:NO];
                            } else {
                              UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Download error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                              UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                              [alertController addAction:ok];
                              dispatch_async(dispatch_get_main_queue(), ^{
                                [self presentViewController:alertController animated:YES completion:nil];
                                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                self.urlTextField.enabled = YES;
                                [self reconfigureImportButton];
                              });
                            }
                          }];
  } else {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"URL error" message:@"Fonts are assigned using valid .css files. Please open the gallery for more information." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:YES completion:nil];
  }
}

- (void)downloadCompletedWithFilePath:(NSData *)fileData
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [self.importButton setTitle:@"Download Complete" forState:UIControlStateNormal];
  self.importButton.enabled = NO;
  _downloadCompleted = YES;
  _tempFileData = fileData;
  [self nameFieldDidChange:self.nameTextField];
}

- (IBAction)didTapOnSave:(id)sender
{
  if ([BKFont withName:self.nameTextField.text]) {
    //Error
    [self showErrorMsg:@"Cannot have two fonts with the same name"];
  } else {
    NSError *error;
    [BKFont saveResource:self.nameTextField.text withContent:_tempFileData error:&error];
    
    if (error) {
      [self showErrorMsg:error.localizedDescription];
    }
    [self.navigationController popViewControllerAnimated:YES];
  }
}

- (IBAction)cancelButtonTapped:(id)sender
{
  [BKSettingsFileDownloader cancelRunningDownloads];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  self.urlTextField.enabled = YES;
  [self reconfigureImportButton];
}


- (void)configureImportButtonForCancel
{
  [self.importButton setTitle:@"Cancel download" forState:UIControlStateNormal];
  [self.importButton setTintColor:[UIColor redColor]];
  [self.importButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)reconfigureImportButton
{
  [self.importButton setTitle:@"Import" forState:UIControlStateNormal];
  [self.importButton setTintColor:[UIColor blueColor]];
  [self.importButton addTarget:self action:@selector(importButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showErrorMsg:(NSString *)errorMsg
{
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Themes error" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
  [alertController addAction:ok];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *clickedCell = [self.tableView cellForRowAtIndexPath:indexPath];

  if ([clickedCell isEqual:self.galleryLinkCell]) {
    [BKLinkActions sendToGitHub:@"fonts"];
  } 
}


@end
