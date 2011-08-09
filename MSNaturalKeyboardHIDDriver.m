//
//  MSNaturalKeyboardHIDDriver.m
//  MS Natural Keyboard HID Handler
//
//  Created by OrangeRaven on 110807.
//  Copyright 2011. All rights reserved.
//

#import "MSNaturalKeyboardHIDDriver.h"
#import <IOKit/hid/IOHIDManager.h>

NSString * const kInputEventUsagePageKey = @"usagePage";
NSString * const kInputEventUsageKey = @"usage";
NSString * const kInputEventValueKey = @"intValue";
NSString * const kInputEventMinKey = @"min";
NSString * const kInputEventMaxKey = @"max";


@interface MSNaturalKeyboardHIDDriver ()

- (void) deviceDidMatch:(IOHIDDeviceRef)inDevice;
- (void) deviceDidRemove:(IOHIDDeviceRef)inDevice;
- (void) deviceDidRecieveInput:(IOHIDValueRef)inValue;

- (CFDictionaryRef) MSNaturalKeyboardMatchingDictionary;
- (BOOL) deviceIsMSNaturalKeyboard:(IOHIDDeviceRef)inDevice;
- (void) foundMSNaturalKeyboard:(IOHIDDeviceRef)inDevice;

- (NSDictionary *) eventDictionaryFromInputValue:(IOHIDValueRef)inValue;

@property (assign) IOHIDManagerRef hidManager;

@end

@interface MSNaturalKeyboardHIDDriver (Delegate)

- (void) keyboardDriverDidRecieveInputEvent:(NSDictionary *) inputEvent;
- (void) keyboardDriverWantsToBeNoticed:(NSString *)aNotice;

@end

static void DeviceMatchingCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef);
static void InputValueCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDValueRef  inIOHIDValueRef);
static void DeviceRemovalCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef);


@implementation MSNaturalKeyboardHIDDriver

@synthesize delegate;
@synthesize hidManager;

- (MSNaturalKeyboardHIDDriver *) initWithDelegate:(id)aDelegate
{
	NSParameterAssert(aDelegate);
    
    if ( ! (self = [super init]) )
        return nil;
    
    self.delegate = aDelegate;
    hidManager = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone );
    IOHIDManagerSetDeviceMatching( hidManager, [self MSNaturalKeyboardMatchingDictionary] );
    
    IOHIDManagerRegisterDeviceMatchingCallback( hidManager, DeviceMatchingCallback, self);
    IOHIDManagerRegisterDeviceRemovalCallback( hidManager, DeviceRemovalCallback, self );
    
    IOHIDManagerScheduleWithRunLoop( hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode );
    IOReturn iores = IOHIDManagerOpen( hidManager, kIOHIDOptionsTypeNone );
    if ( iores != kIOReturnSuccess )
    {
        [self keyboardDriverWantsToBeNoticed:@"Cannot open HID manager."];
        [self release];
        return nil;
    }
    
    [self keyboardDriverWantsToBeNoticed:@"Microsoft Natural Keyboard HID Driver started."];
	return self;
}

- (BOOL) deviceIsMSNaturalKeyboard:(IOHIDDeviceRef)inDevice
{
    NSString *product = (NSString *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDProductKey) );
    return [product hasPrefix:@"Natural"];
}

- (void) foundMSNaturalKeyboard:(IOHIDDeviceRef)inDevice;
{
    NSString *msg = [NSString stringWithFormat:@"connected: %@", IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDProductKey ))];
    [self keyboardDriverWantsToBeNoticed:msg];
	
	IOHIDDeviceRegisterInputValueCallback( inDevice, InputValueCallback, self );
}

- (CFDictionaryRef) MSNaturalKeyboardMatchingDictionary;
{
    NSDictionary *matching = nil;

//    matching = [NSDictionary dictionaryWithObjectsAndKeys:
//                [NSNumber numberWithInt:0x45e], CFSTR(kIOHIDVendorIDKey),
//                [NSNumber numberWithInt:0xdb],  CFSTR(kIOHIDProductIDKey),
//                nil];

    return (CFDictionaryRef)matching;
}

- (NSDictionary *) eventDictionaryFromInputValue:(IOHIDValueRef)inValue;
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    IOHIDElementRef	element = IOHIDValueGetElement(inValue);
    [dict setObject:[NSNumber numberWithUnsignedInt:IOHIDElementGetUsagePage(element)] forKey:kInputEventUsagePageKey];
    [dict setObject:[NSNumber numberWithUnsignedInt:IOHIDElementGetUsage(element)] forKey:kInputEventUsageKey];
    
    [dict setObject:[NSNumber numberWithLong:IOHIDValueGetIntegerValue(inValue)] forKey:kInputEventValueKey];
    [dict setObject:[NSNumber numberWithLong:IOHIDElementGetLogicalMin(element)] forKey:kInputEventMinKey];
    [dict setObject:[NSNumber numberWithLong:IOHIDElementGetLogicalMax(element)] forKey:kInputEventMaxKey];
    
    return dict;
}

- (void) dealloc
{
    if (hidManager != NULL)
        CFRelease(hidManager);
    
    [super dealloc];
}

#pragma mark -
#pragma mark callback handler
- (void) deviceDidMatch:(IOHIDDeviceRef)inDevice;
{
    if ( ! [self deviceIsMSNaturalKeyboard:inDevice] ) {
        NSString *product = (NSString *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDProductKey) );
        unsigned usagePage = [(NSNumber *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDPrimaryUsagePageKey) ) unsignedIntValue];
        unsigned usage = [(NSNumber *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDPrimaryUsageKey) ) unsignedIntValue];

        NSString *msg = [NSString stringWithFormat:@"Ignoring HID device: %@ (primary usage %u:%u)", product, usagePage, usage];
        [self keyboardDriverWantsToBeNoticed:msg];
        
        return;
    }
    
    [self foundMSNaturalKeyboard:inDevice];
}

- (void) deviceDidRemove:(IOHIDDeviceRef)inDevice;
{
    NSString *msg = [NSString stringWithFormat:@"Removed HID device: %@", IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDProductKey ))];
    [self keyboardDriverWantsToBeNoticed:msg];
    
    // ? IOHIDDeviceClose(<#IOHIDDeviceRef device#>, <#IOOptionBits options#>);
}

- (void) deviceDidRecieveInput:(IOHIDValueRef)inValue;
{
    [self keyboardDriverDidRecieveInputEvent:[self eventDictionaryFromInputValue:inValue]];
}

#pragma mark -
#pragma mark delegate calls

- (void) keyboardDriverDidRecieveInputEvent:(NSDictionary *) inputEvent
{
    if ( ! [self.delegate respondsToSelector:@selector(keyboardDriverDidRecieveInputEvent:)] )
        return;

    [self.delegate keyboardDriverDidRecieveInputEvent:inputEvent];
}

- (void) keyboardDriverWantsToBeNoticed:(NSString *)aNotice
{
    if ( ! [self.delegate respondsToSelector:@selector(keyboardDriverWantsToBeNoticed:)] )
        return;

    [self.delegate keyboardDriverWantsToBeNoticed:aNotice];
}

@end

#pragma mark -
#pragma mark C HID Callbacks -> Objective-C

static void DeviceMatchingCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef)
{
	[(MSNaturalKeyboardHIDDriver *)inContext deviceDidMatch:inIOHIDDeviceRef];
}
static void DeviceRemovalCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef)
{
	[(MSNaturalKeyboardHIDDriver *)inContext deviceDidRemove:inIOHIDDeviceRef];
}
static void InputValueCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDValueRef  inIOHIDValueRef)
{
	[(MSNaturalKeyboardHIDDriver *)inContext deviceDidRecieveInput:inIOHIDValueRef];
}
