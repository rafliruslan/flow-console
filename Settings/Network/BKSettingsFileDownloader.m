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

#import "BKSettingsFileDownloader.h"
static NSURLSessionDownloadTask *downloadTask;
@implementation BKSettingsFileDownloader

static NSURLSessionDownloadTask *downloadTask;

+ (void)downloadFileAtUrl:(NSString *)urlString withCompletionHandler:(void (^)(NSData *fileData, NSError *error))completionHandler
{
  [self downloadFileAtUrl:urlString expectedMIMETypes:nil withCompletionHandler:completionHandler];
  // [BKSettingsFileDownloader cancelRunningDownloads];

  // NSURL *url = [NSURL URLWithString:urlString];
  // downloadTask = [[NSURLSession sharedSession]
  //   downloadTaskWithURL:url
  //     completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
  //       if (error.code != -999) {
  //         completionHandler([NSData dataWithContentsOfURL:location], error);
  //       }
  //     }];

  // [downloadTask resume];
}

+ (void)downloadFileAtUrl:(NSString *)urlString expectedMIMETypes:(NSArray *)mimeTypes withCompletionHandler:(void (^)(NSData *fileData, NSError *error))completionHandler
{
  [BKSettingsFileDownloader cancelRunningDownloads];

  NSURL *url = [NSURL URLWithString:urlString];
  downloadTask = [[NSURLSession sharedSession]
		   downloadTaskWithURL:url
		     completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
      if (!error && mimeTypes) {
	NSString *responseType = [response MIMEType];
	__block BOOL acceptedMIMEType = NO;
        [mimeTypes enumerateObjectsUsingBlock:^(NSString *type,
						NSUInteger idx,
						BOOL *stop) {
	    if ([type isEqualToString:responseType]) {
	      *stop = YES;
	      acceptedMIMEType = YES;	      
	    } 
	  }];

	if (!acceptedMIMEType) {
	  NSString *msg = [NSString stringWithFormat:@"Unsupported media type %@.", [response MIMEType]];
	  error = [NSError errorWithDomain:@"BKSettingsErrorDomain"
				      code:415
				  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(msg, nil)}];
	}
      }
      if (error.code != -999) {
	completionHandler([NSData dataWithContentsOfURL:location], error);
      }
    }];

  [downloadTask resume];
}

+ (void)cancelRunningDownloads
{
  if (downloadTask != nil || downloadTask.state == NSURLSessionTaskStateRunning) {
    [downloadTask cancel];
    downloadTask = nil;
  }
}

@end
