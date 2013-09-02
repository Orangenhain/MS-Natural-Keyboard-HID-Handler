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
NSString * const kInputEventDevice = @"device";


@interface MSNaturalKeyboardHIDDriver ()

- (void) deviceDidMatch:(IOHIDDeviceRef)inDevice;
- (void) deviceDidRemove:(IOHIDDeviceRef)inDevice;
- (void) deviceDidRecieveInput:(IOHIDValueRef)inValue;

@property (assign) IOHIDManagerRef hidManager;

@end

static void DeviceMatchingCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef);
static void     InputValueCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDValueRef    inIOHIDValueRef);
static void  DeviceRemovalCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef);


@implementation MSNaturalKeyboardHIDDriver

- (MSNaturalKeyboardHIDDriver *) initWithDelegate:(id)aDelegate
{
	NSParameterAssert(aDelegate);
    
    if ( ! (self = [super init]) )
        return nil;
    
    self.delegate = aDelegate;
    self.hidManager = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone );
    IOHIDManagerSetDeviceMatching( _hidManager, [self MSNaturalKeyboardMatchingDictionary] );
    
    IOHIDManagerRegisterDeviceMatchingCallback( _hidManager, DeviceMatchingCallback, (__bridge void *)(self) );
    IOHIDManagerRegisterDeviceRemovalCallback(  _hidManager, DeviceRemovalCallback,  (__bridge void *)(self) );
    
    IOHIDManagerScheduleWithRunLoop( _hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode );

    IOReturn iores = IOHIDManagerOpen( _hidManager, kIOHIDOptionsTypeNone );
    if ( iores != kIOReturnSuccess )
    {
        [self keyboardDriverWantsToBeNoticed:@"Cannot open HID manager."];
        return nil;
    }
    
    [self keyboardDriverWantsToBeNoticed:@"Microsoft Natural Keyboard HID Driver started."];
	return self;
}

- (BOOL) deviceIsMSNaturalKeyboard:(IOHIDDeviceRef)inDevice
{
//    return YES;
    NSString *product = (__bridge NSString *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDProductKey) );
    
    return [product hasPrefix:@"Natural"];
}

- (void) foundMSNaturalKeyboard:(IOHIDDeviceRef)inDevice;
{
    NSString *product   =  (__bridge NSString *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDProductKey) );
    unsigned  usagePage = [(__bridge NSNumber *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDPrimaryUsagePageKey) ) unsignedIntValue];
    unsigned  usage     = [(__bridge NSNumber *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDPrimaryUsageKey) ) unsignedIntValue];
    
    NSString *msg       = [NSString stringWithFormat:@"connected HID device %p: %@ (primary usage %u:%u)", inDevice, product, usagePage, usage];

    [self keyboardDriverWantsToBeNoticed:msg];
	
	IOHIDDeviceRegisterInputValueCallback( inDevice, InputValueCallback, (__bridge void *)(self) );
}

- (CFDictionaryRef) MSNaturalKeyboardMatchingDictionary;
{
    NSDictionary *matching = nil;

//    matching = [NSDictionary dictionaryWithObjectsAndKeys:
//                [NSNumber numberWithInt:0x45e], CFSTR(kIOHIDVendorIDKey),
//                [NSNumber numberWithInt:0xdb],  CFSTR(kIOHIDProductIDKey),
//                nil];

    return (__bridge CFDictionaryRef)matching;
}

- (NSDictionary *) eventDictionaryFromInputValue:(IOHIDValueRef)inValue;
{
    NSMutableDictionary *eventDict = [NSMutableDictionary dictionary];

    IOHIDElementRef	element = IOHIDValueGetElement(inValue);
    eventDict[kInputEventUsagePageKey] = @(IOHIDElementGetUsagePage(element));
    eventDict[kInputEventUsageKey]     = @(IOHIDElementGetUsage(element));
    eventDict[kInputEventValueKey]     = @(IOHIDValueGetIntegerValue(inValue));
    eventDict[kInputEventMinKey]       = @(IOHIDElementGetLogicalMin(element));
    eventDict[kInputEventMaxKey]       = @(IOHIDElementGetLogicalMax(element));
    eventDict[kInputEventDevice]       = [NSString stringWithFormat:@"%p", IOHIDElementGetDevice(element)];
    
    return eventDict;
}

- (void) dealloc
{
    if (_hidManager != NULL)
        CFRelease(_hidManager);
    
}

#pragma mark -
#pragma mark callback handler
- (void) deviceDidMatch:(IOHIDDeviceRef)inDevice;
{
    if ( [self deviceIsMSNaturalKeyboard:inDevice] ) {
        [self foundMSNaturalKeyboard:inDevice];
    } else {
        NSString *product   =  (__bridge NSString *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDProductKey) );
        unsigned  usagePage = [(__bridge NSNumber *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDPrimaryUsagePageKey) ) unsignedIntValue];
        unsigned  usage     = [(__bridge NSNumber *)IOHIDDeviceGetProperty( inDevice, CFSTR(kIOHIDPrimaryUsageKey) ) unsignedIntValue];

        NSString *msg       = [NSString stringWithFormat:@"Ignoring HID device %p: %@ (primary usage %u:%u)", inDevice, product, usagePage, usage];
        
        [self keyboardDriverWantsToBeNoticed:msg];
    }
    
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
	[(__bridge MSNaturalKeyboardHIDDriver *)inContext deviceDidMatch:inIOHIDDeviceRef];
}
static void DeviceRemovalCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef  inIOHIDDeviceRef)
{
	[(__bridge MSNaturalKeyboardHIDDriver *)inContext deviceDidRemove:inIOHIDDeviceRef];
}
static void InputValueCallback(void * inContext, IOReturn inResult, void* inSender, IOHIDValueRef  inIOHIDValueRef)
{
	[(__bridge MSNaturalKeyboardHIDDriver *)inContext deviceDidRecieveInput:inIOHIDValueRef];
}
