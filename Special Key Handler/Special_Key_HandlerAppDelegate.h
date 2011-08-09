//
//  Special_Key_HandlerAppDelegate.h
//  Special Key Handler
//
//  Created by OrangeRaven on 110807.
//  Copyright 2011. All rights reserved.
//

@interface Special_Key_HandlerAppDelegate : NSObject <NSApplicationDelegate> {
@private
}

- (IBAction) selectFile:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (assign) NSString *currentKeyName;
@property (assign) NSString *currentFilePath;

@end
