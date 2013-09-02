//
//  MSNaturalKeyboardHIDDriver.h
//  MS Natural Keyboard HID Handler
//
//  Created by OrangeRaven on 110807.
//  Copyright 2011. All rights reserved.
//

extern NSString * const kInputEventUsagePageKey;
extern NSString * const kInputEventUsageKey;
extern NSString * const kInputEventValueKey;
extern NSString * const kInputEventMinKey;
extern NSString * const kInputEventMaxKey;
extern NSString * const kInputEventDevice;

@interface MSNaturalKeyboardHIDDriver : NSObject

@property (weak) id delegate;

- (MSNaturalKeyboardHIDDriver *) initWithDelegate:(id)aDelegate;

@end


@protocol MSNaturalKeyboardHIDDriverDelegate <NSObject>

@optional
- (void) keyboardDriverDidRecieveInputEvent:(NSDictionary *) inputEvent;
- (void) keyboardDriverWantsToBeNoticed:(NSString *)aNotice;

@end