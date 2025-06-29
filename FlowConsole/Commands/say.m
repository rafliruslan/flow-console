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

#include <stdio.h>
#include "ios_system/ios_system.h"
#include "ios_error.h"
#include "bk_getopts.h"
#import <AVFoundation/AVFoundation.h>
#import "MCPSession.h"

@interface BlinkSpeechSynthesizerDelegate : NSObject<AVSpeechSynthesizerDelegate>

- (void)wait;

@end

@implementation BlinkSpeechSynthesizerDelegate {
  dispatch_semaphore_t _sema;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _sema = dispatch_semaphore_create(0);
  }
  return self;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
  dispatch_semaphore_signal(_sema);
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
  dispatch_semaphore_signal(_sema);
}

- (void)wait {
  dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
}

@end

void _sayText(NSString *text, NSNumber* rate, AVSpeechSynthesisVoice *voice) {
  AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString: text];
  if (rate) {
    utterance.rate = rate.floatValue;
  }
  utterance.pitchMultiplier = 1;
  if (voice) {
    utterance.voice = voice;
  }
  
  BlinkSpeechSynthesizerDelegate *delegate = [[BlinkSpeechSynthesizerDelegate alloc] init];
  AVSpeechSynthesizer *synth = [[AVSpeechSynthesizer alloc] init];
  synth.delegate = delegate;
  [synth speakUtterance:utterance];
  [delegate wait];
}

__attribute__ ((visibility("default")))
int say_main(int argc, char *argv[]) {
  thread_optind = 1;
  
  
  NSString *usage = [@[@"Usage: say [-v voice] [-r rate] [-f file] [message]",
                       @"Examples:",
                       @"  say -v '?'",
                       @"  say Hello, Blink",
                       @"  echo Hello | say",
                       @"  say -v Monica Hola mundo",
                       @"  say -v Milena Привет всем"] componentsJoinedByString:@"\n"];
  
  NSString *voice = nil;
  NSString *file = nil;
  NSNumber *rate = nil;
  NSString *text = nil;
  BOOL showHelp = NO;
    
  for (;;) {
    int c = thread_getopt(argc, argv, "v:f:r:h");
    if (c == -1) {
      break;
    }
    
    switch (c) {
      case 'v':
        voice = @(thread_optarg);
        break;
      case 'f':
        file = @(thread_optarg);
        break;
      case 'r':
        rate = @([@(thread_optarg) floatValue]);
        break;
      case 'h':
        showHelp = YES;
        break;
      default:
        printf("%s\n", usage.UTF8String);
        return -1;
    }
  }
  
  if (showHelp) {
    printf("%s\n", usage.UTF8String);
    return 0;
  }
  
  if (thread_optind < argc) {
    NSMutableArray<NSString *> *words = [[NSMutableArray alloc] init];
    for (int i = thread_optind; i < argc; i++) {
      [words addObject:@(argv[i])];
    }
    text = [words componentsJoinedByString:@" "];
  }
  
  AVSpeechSynthesisVoice *speechVoice = nil;
  
  if ([voice isEqual:@"?"]) {
    for (AVSpeechSynthesisVoice * v in AVSpeechSynthesisVoice.speechVoices) {
      puts([NSString stringWithFormat:@"%-20s %@", v.name.UTF8String, v.language].UTF8String);
    }
    return 0;
  } else if (voice) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[c] %@", voice];
    speechVoice = [[AVSpeechSynthesisVoice.speechVoices filteredArrayUsingPredicate:predicate] firstObject];
  }
  

  if (!text && file.length > 0) {
    NSError *error = nil;
    text = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];
    if (!text) {
      printf("%s\n", error.localizedDescription.UTF8String);
      return 1;
    }
  }
  
  if (text) {
    _sayText(text, rate, speechVoice);
    return 0;
  }
  
  BOOL isatty = ios_isatty(fileno(thread_stdin));
  
  if (!isatty) {
    if (!text) {
      const int bufsize = 1024;
      char buffer[bufsize];
      NSMutableData* data = [[NSMutableData alloc] init];
      ssize_t count = 0;
      while ((count = read(fileno(thread_stdin), buffer, bufsize-1))) {
        [data appendBytes:buffer length:count];
      }
      
      text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    if (!text) {
      printf("%s\n", usage.UTF8String);
      return 1;
    }
    
    _sayText(text, rate, speechVoice);
    return 0;
  }
  
  MCPSession *session = (__bridge MCPSession *)thread_context;
  for (;;) {
    NSString *line = [session.device readline:@"" secure: NO];
    if (!line) {
      puts("");
      break;
    }
    _sayText(line, rate, speechVoice);
  }
  
  return 0;
}

