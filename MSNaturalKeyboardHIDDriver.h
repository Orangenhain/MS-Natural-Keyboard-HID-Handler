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

@interface MSNaturalKeyboardHIDDriver : NSObject {
@private
}

@property (assign) id delegate;

- (MSNaturalKeyboardHIDDriver *) initWithDelegate:(id)aDelegate;

@end
