//
//  Input_Event_DumperAppDelegate.h
//  Input Event Dumper
//
//  Created by OrangeRaven on 110807.
//  Copyright 2011. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Input_Event_DumperAppDelegate : NSObject <NSApplicationDelegate>

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property (assign) BOOL shouldShowFFFF;
@property (assign) BOOL shouldShowErrorRollOver;
@property (assign) BOOL shouldShowUndefinedUsage;

@end
