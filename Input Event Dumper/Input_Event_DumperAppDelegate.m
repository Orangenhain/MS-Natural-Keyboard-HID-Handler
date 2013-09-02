//
//  Input_Event_DumperAppDelegate.m
//  Input Event Dumper
//
//  Created by OrangeRaven on 110807.
//  Copyright 2011. All rights reserved.
//

#import "Input_Event_DumperAppDelegate.h"
#import "MSNaturalKeyboardHIDDriver.h"
#import <IOKit/hid/IOHIDManager.h>

@interface Input_Event_DumperAppDelegate ()

- (void) logString:(NSString *) inMessage;
- (NSString*) logEntryFromInputEvent:(NSDictionary *) inputEvent;

@property (strong) MSNaturalKeyboardHIDDriver *kbdDriver;
@property (strong) NSDictionary *usageStrings;

@end

@implementation Input_Event_DumperAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification
{
    self.usageStrings = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HID_usage_strings" ofType:@"plist"]];

    self.shouldShowFFFF = YES;
    self.shouldShowErrorRollOver = YES;
    self.shouldShowUndefinedUsage = YES;
    
    self.kbdDriver = [[MSNaturalKeyboardHIDDriver alloc] initWithDelegate:self];
}

- (void) keyboardDriverDidRecieveInputEvent:(NSDictionary *) inputEvent
{
    int usagePage = [(NSNumber *)inputEvent[kInputEventUsagePageKey] intValue];
    int usage     = [(NSNumber *)inputEvent[kInputEventUsageKey] intValue];
    
    if ( ! self.shouldShowErrorRollOver ) {
        if ( usagePage == kHIDPage_KeyboardOrKeypad && usage == kHIDUsage_KeyboardErrorRollOver)
            return;
    }
    if ( ! self.shouldShowFFFF) {
        if ( usage == -1 ) {
            return;
        }
    }
    if ( ! self.shouldShowUndefinedUsage) {
        if ( usagePage == kHIDPage_Consumer && usage == 0x00 ) {
            return;
        }
    }
    
    [self logString:[self logEntryFromInputEvent:inputEvent]];
}

- (void) keyboardDriverWantsToBeNoticed:(NSString *)aNotice
{
    [self logString:aNotice];
}

- (void) logString:(NSString *) inMessage
{
    NSTextView *tv = self.textView;
    [[[tv textStorage] mutableString] appendString:[NSString stringWithFormat:@"%@\n", inMessage]];
    
    NSFont *font = [NSFont fontWithName:@"Menlo" size:12.0f];
    [tv setFont:font];
    
    [tv scrollToEndOfDocument:nil];
}

- (NSString *) logEntryFromInputEvent:(NSDictionary *) inputEvent
{
    NSString *format = @"0x%4.4lX";
    NSString *pageString  = [NSString stringWithFormat:format, [(NSNumber *)inputEvent[kInputEventUsagePageKey] longValue]];
    NSString *usageString = [NSString stringWithFormat:format, [(NSNumber *)inputEvent[kInputEventUsageKey] longValue]];
    NSString *path = [NSString stringWithFormat:@"%@.%@", pageString, usageString];
    NSString *keyName = [self.usageStrings valueForKeyPath:path] ?: @"Unknown Key";
    
    format = @"device: %@, page: %5@, usage: %5@ -- value: %5ld (%4ld to %4ld) -- %@";
    NSString *msg = [NSString stringWithFormat:format,
                     inputEvent[kInputEventDevice],
                     pageString,
                     usageString,
                     [(NSNumber *)inputEvent[kInputEventValueKey] longValue],
                     [(NSNumber *)inputEvent[kInputEventMinKey] longValue],
                     [(NSNumber *)inputEvent[kInputEventMaxKey] longValue],
                     keyName];

    return msg;
}

@end
