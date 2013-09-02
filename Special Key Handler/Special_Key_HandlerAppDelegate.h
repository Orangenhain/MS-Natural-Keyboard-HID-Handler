//
//  Special_Key_HandlerAppDelegate.h
//  Special Key Handler
//
//  Created by OrangeRaven on 110807.
//  Copyright 2011. All rights reserved.
//

@interface Special_Key_HandlerAppDelegate : NSObject <NSApplicationDelegate>

@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (strong) NSString *currentKeyName;
@property (strong) NSString *currentFilePath;

- (IBAction) selectFile:(id)sender;

@end
