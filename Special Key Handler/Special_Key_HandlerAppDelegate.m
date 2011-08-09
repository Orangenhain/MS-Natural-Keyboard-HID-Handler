//
//  Special_Key_HandlerAppDelegate.m
//  Special Key Handler
//
//  Created by OrangeRaven on 110807.
//  Copyright 2011. All rights reserved.
//

#import "Special_Key_HandlerAppDelegate.h"
#import "MSNaturalKeyboardHIDDriver.h"
#import <IOKit/hid/IOHIDManager.h>

@interface Special_Key_HandlerAppDelegate ()

- (NSString *) specialKeyNameForInputEvent:(NSDictionary *)inputEvent;

@property (retain) MSNaturalKeyboardHIDDriver *kbdDriver;
@property (retain) NSArray *specialKeys;

@end

@implementation Special_Key_HandlerAppDelegate

@synthesize window;
@synthesize currentKeyName, currentFilePath;
@synthesize kbdDriver;
@synthesize specialKeys;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ( ([NSEvent modifierFlags] & NSAlternateKeyMask ) != 0 ) {
        [self.window makeKeyAndOrderFront:self];
    }
    
    NSDictionary *defaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                         forKey:@"showWindowForUnsetKeys"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [self.window setLevel:NSFloatingWindowLevel];
    self.specialKeys = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"special_keys" ofType:@"plist"]];
    
    [self addObserver:self forKeyPath:@"currentKeyName" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"currentFilePath" options:0 context:NULL];
    
    self.kbdDriver = [[MSNaturalKeyboardHIDDriver alloc] initWithDelegate:self];
}

- (IBAction) selectFile:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton)
            return;
        
        if ( ! [[panel URL] isFileURL] )
            return;
        
        self.currentFilePath = [[[panel URL] path] stringByAbbreviatingWithTildeInPath];
    }];
}

- (void) keyboardDriverDidRecieveInputEvent:(NSDictionary *) inputEvent;
{
    int usagePage = [(NSNumber *)[inputEvent objectForKey:kInputEventUsagePageKey] intValue];
    if ( ( usagePage != kHIDPage_Consumer ) && ( usagePage != kHIDPage_VendorDefinedStart ) )
        return;
    int usage = [(NSNumber *)[inputEvent objectForKey:kInputEventUsageKey] intValue];
    if ( ( usage == -1 ) || ( usagePage == kHIDPage_Consumer && usage == 0x00 )
        ) {
        return;
    }
    if ([(NSNumber *)[inputEvent objectForKey:kInputEventValueKey] longValue] == 0)
        return;  // not interested in KeyUp events

    self.currentKeyName = [self specialKeyNameForInputEvent:inputEvent];
}

- (NSString *) specialKeyNameForInputEvent:(NSDictionary *)inputEvent
{
    NSPredicate *keyFilter = [NSPredicate predicateWithFormat:@"SELF.usagePage == %i AND SELF.usage == %i AND SELF.value == %ld",
                              [(NSNumber *)[inputEvent objectForKey:kInputEventUsagePageKey] intValue],
                              [(NSNumber *)[inputEvent objectForKey:kInputEventUsageKey] intValue],
                              [(NSNumber *)[inputEvent objectForKey:kInputEventValueKey] longValue]];
    
    NSArray *keyCandidates = [self.specialKeys filteredArrayUsingPredicate:keyFilter];
    if ([keyCandidates count] != 1)
        return nil;
    
    return [(NSDictionary *)[keyCandidates lastObject] objectForKey:@"name"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([keyPath isEqualToString:@"currentKeyName"]) {
        if (self.currentKeyName) {
            self.currentFilePath = [defaults stringForKey:self.currentKeyName];
            if (self.currentFilePath) {
                if ( ! [self.window isVisible] ) {
                    [[NSWorkspace sharedWorkspace] openFile:[self.currentFilePath stringByStandardizingPath]];
                }
            } else {
                if ( ( ! [self.window isVisible] ) && [defaults boolForKey:@"showWindowForUnsetKeys"] ) {
                    [self.window makeKeyAndOrderFront:self];
                }
            }
        } else {
            self.currentFilePath = nil;
        }
    } else if ([keyPath isEqualToString:@"currentFilePath"]) {
        if (!self.currentKeyName)
            return;
        [defaults setObject:self.currentFilePath forKey:self.currentKeyName];
        [defaults synchronize];
    }
    
    // our super, NSObject, does not implement observeValueFor..., so there is no need to call it
}

@end
