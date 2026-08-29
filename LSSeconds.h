//
//  LSSeconds.h
//
//  Created by CrazyMind90 on 01/08/2025.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

NS_ASSUME_NONNULL_BEGIN

static inline BOOL LSSGetBoolPref(CFStringRef key, BOOL defaultValue) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(key, CFSTR("com.cm90.lsseconds"));
    if (value) {
        BOOL boolVal = [(__bridge id)value boolValue];
        CFRelease(value);
        return boolVal;
    }
    return defaultValue;
}

@interface LSSeconds : NSObject

- (instancetype)initWithBaseController:(UIViewController *)baseController;
- (instancetype)initWithBaseController:(UIViewController *)baseController
                      referenceTimeView:(nullable UIView *)referenceTimeView;
- (instancetype)initWithBaseController:(UIViewController *)baseController
                      referenceTimeView:(nullable UIView *)referenceTimeView
                      accessoryHostView:(nullable UIView *)accessoryHostView;
- (void)updateReferenceTimeView:(nullable UIView *)referenceTimeView;
- (void)startUpdating;
- (void)stopUpdating;
- (void)updateTimeForDate:(NSDate *)date
            updateSeconds:(BOOL)updateSeconds
                 animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
