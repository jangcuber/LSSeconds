// By @CrazyMind90

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <math.h>
#import <objc/runtime.h>

#import "LSSeconds.h"


#pragma GCC diagnostic ignored "-Wdeprecated-declarations"


@interface CSProminentDisplayView : UIView
- (UIView *)timeView;
@end

@interface CSProminentDisplayViewController : UIViewController
@property (nonatomic) CGFloat timeAlpha;
- (CSProminentDisplayView *)_displayViewIfLoaded;
@end

@interface CSProminentTimeView : UIView
@end

@interface SBFLockScreenDateView : UIView
@property (nonatomic, retain) CSProminentDisplayViewController *prominentDisplayViewController;
- (UIView *)_timeLabel;
@end

@interface SBFLockScreenDateViewController : UIViewController
- (SBFLockScreenDateView *)dateView;
- (BOOL)screenOff;
- (void)setScreenOff:(BOOL)screenOff;
- (void)_updateWithFrameSpecifier:(id)frameSpecifier;
@end

@interface BLSAlwaysOnFrameSpecifier : NSObject
@property (nonatomic, readonly) NSDateInterval *presentationInterval;
@end


static const void *kLockScreenClockKey = &kLockScreenClockKey;
static const void *kNativeLockScreenClockKey = &kNativeLockScreenClockKey;

static BOOL LSSLockScreenClockEnabled(void) {
    return LSSGetBoolPref(CFSTR("enabled"), YES) &&
           LSSGetBoolPref(CFSTR("lockscreenEnabled"), YES);
}

static BOOL LSSLockScreenControllerIsScreenOff(
    SBFLockScreenDateViewController *controller) {
    return [controller respondsToSelector:@selector(screenOff)] &&
           [controller screenOff];
}

static UIView *LSSNativeLockScreenTimeView(
    SBFLockScreenDateViewController *controller) {
    SBFLockScreenDateView *dateView = [controller dateView];
    CSProminentDisplayViewController *prominentController = nil;
    if ([dateView respondsToSelector:@selector(prominentDisplayViewController)]) {
        prominentController = dateView.prominentDisplayViewController;
    }

    CSProminentDisplayView *displayView = nil;
    if ([prominentController respondsToSelector:@selector(_displayViewIfLoaded)]) {
        displayView = [prominentController _displayViewIfLoaded];
    }
    if (!displayView && prominentController.isViewLoaded) {
        displayView = (CSProminentDisplayView *)prominentController.view;
    }
    if ([displayView respondsToSelector:@selector(timeView)]) {
        UIView *timeView = [displayView timeView];
        if (timeView) {
            return timeView;
        }
    }

    if ([dateView respondsToSelector:@selector(_timeLabel)]) {
        return [dateView _timeLabel];
    }
    return nil;
}

static void LSSHideNativeLockScreenClock(SBFLockScreenDateViewController *controller) {
    if (!LSSLockScreenClockEnabled()) {
        return;
    }

    SBFLockScreenDateView *dateView = [controller dateView];

    if ([dateView respondsToSelector:@selector(_timeLabel)]) {
        // Legacy clock path. Keep the containing date view visible.
        [dateView _timeLabel].hidden = YES;
    }

    // iOS 16/17 renders the customized native clock in a separate prominent
    // time view. Its date, subtitle, and complication siblings stay visible.
    CSProminentDisplayViewController *prominentController = nil;
    if ([dateView respondsToSelector:@selector(prominentDisplayViewController)]) {
        prominentController = dateView.prominentDisplayViewController;
    }
    if ([prominentController respondsToSelector:@selector(setTimeAlpha:)]) {
        prominentController.timeAlpha = 0.0;
    }

    UIView *timeView = LSSNativeLockScreenTimeView(controller);
    if (timeView) {
        objc_setAssociatedObject(timeView,
                                 kNativeLockScreenClockKey,
                                 @YES,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        timeView.alpha = 0.0;
    }
}

static void LSSConfigureLockScreenClock(SBFLockScreenDateViewController *controller) {
    if (!LSSLockScreenClockEnabled()) {
        return;
    }

    LSSHideNativeLockScreenClock(controller);

    LSSeconds *clock = objc_getAssociatedObject(controller, kLockScreenClockKey);
    if (clock) {
        [clock updateReferenceTimeView:LSSNativeLockScreenTimeView(controller)];
        if (LSSLockScreenControllerIsScreenOff(controller)) {
            [clock stopUpdating];
            [clock updateTimeForDate:NSDate.date
                       updateSeconds:NO
                            animated:NO];
        } else {
            [clock startUpdating];
        }
        return;
    }

    UIViewController *baseController = controller.parentViewController ?: controller;
    clock = [[LSSeconds alloc]
        initWithBaseController:baseController
            referenceTimeView:LSSNativeLockScreenTimeView(controller)
            accessoryHostView:baseController.view];
    objc_setAssociatedObject(controller,
                             kLockScreenClockKey,
                             clock,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (LSSLockScreenControllerIsScreenOff(controller)) {
        [clock stopUpdating];
        [clock updateTimeForDate:NSDate.date
                   updateSeconds:NO
                        animated:NO];
    }
}


%group LSSLockScreenControllerHooks

%hook SBFLockScreenDateViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    LSSConfigureLockScreenClock(self);
}

- (void)viewDidLayoutSubviews {
    %orig;

    LSSeconds *clock = objc_getAssociatedObject(self, kLockScreenClockKey);
    if (!clock) {
        LSSConfigureLockScreenClock(self);
        return;
    }

    LSSHideNativeLockScreenClock(self);
    [clock updateReferenceTimeView:LSSNativeLockScreenTimeView(self)];
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig(animated);

    LSSeconds *clock = objc_getAssociatedObject(self, kLockScreenClockKey);
    [clock stopUpdating];
}

%end

%end


%group LSSLockScreenScreenOffHooks

%hook SBFLockScreenDateViewController

- (void)setScreenOff:(BOOL)screenOff {
    %orig(screenOff);

    LSSeconds *clock = objc_getAssociatedObject(self, kLockScreenClockKey);
    if (!clock) {
        return;
    }

    if (screenOff) {
        [clock stopUpdating];
        [clock updateTimeForDate:NSDate.date
                   updateSeconds:NO
                        animated:NO];
    } else {
        [clock startUpdating];
    }

    LSSHideNativeLockScreenClock(self);
}

%end

%end


%group LSSLockScreenAODFrameHooks

%hook SBFLockScreenDateViewController

- (void)_updateWithFrameSpecifier:(id)frameSpecifier {
    %orig(frameSpecifier);

    if (!LSSLockScreenControllerIsScreenOff(self)) {
        return;
    }

    LSSeconds *clock = objc_getAssociatedObject(self, kLockScreenClockKey);
    if (!clock) {
        return;
    }

    // AOD pre-renders frames for their presentation dates. Keep seconds
    // stopped/hidden, but update hours/minutes and AM/PM for each native frame.
    NSDate *presentationDate = nil;
    if ([frameSpecifier respondsToSelector:@selector(presentationInterval)]) {
        NSDateInterval *interval = [frameSpecifier presentationInterval];
        presentationDate = interval.startDate;
    }

    [clock stopUpdating];
    [clock updateTimeForDate:presentationDate ?: NSDate.date
               updateSeconds:NO
                    animated:NO];
    LSSHideNativeLockScreenClock(self);
}

%end

%end


%group LSSLockScreenAlphaHooks

%hook SBFLockScreenDateViewController

- (void)setTimeAlpha:(CGFloat)timeAlpha subtitleAlpha:(CGFloat)subtitleAlpha {
    if (LSSLockScreenClockEnabled()) {
        // Hide only the system time; preserve the date/subtitle alpha exactly.
        %orig(0.0, subtitleAlpha);
    } else {
        %orig(timeAlpha, subtitleAlpha);
    }
}

%end

%end


%group LSSProminentTimeViewHooks

%hook CSProminentTimeView

- (void)setAlpha:(CGFloat)alpha {
    if (LSSLockScreenClockEnabled() &&
        [objc_getAssociatedObject(self, kNativeLockScreenClockKey) boolValue]) {
        %orig(0.0);
    } else {
        %orig(alpha);
    }
}

- (void)layoutSubviews {
    %orig;

    if (LSSLockScreenClockEnabled() &&
        [objc_getAssociatedObject(self, kNativeLockScreenClockKey) boolValue]) {
        self.alpha = 0.0;
    }
}

%end
%end


@interface STUIStatusBarStringView : UILabel
@end

@interface _UIStatusBarStringView : UILabel
@end

@interface STUIStatusBarTimeItem : NSObject
- (STUIStatusBarStringView *)timeView;
- (STUIStatusBarStringView *)shortTimeView;
- (STUIStatusBarStringView *)pillTimeView;
- (id)applyUpdate:(id)update toDisplayItem:(id)displayItem;
@end

@interface _UIStatusBarTimeItem : NSObject
- (_UIStatusBarStringView *)timeView;
- (_UIStatusBarStringView *)shortTimeView;
- (_UIStatusBarStringView *)pillTimeView;
- (id)applyUpdate:(id)update toDisplayItem:(id)displayItem;
@end


static const void *kStatusBarClockViewKey = &kStatusBarClockViewKey;
static const void *kStatusBarTimerKey = &kStatusBarTimerKey;
static const void *kStatusBarApplyingUpdateKey = &kStatusBarApplyingUpdateKey;

static BOOL LSSStatusBarSecondsEnabled(void) {
    return LSSGetBoolPref(CFSTR("enabled"), YES) &&
           LSSGetBoolPref(CFSTR("statusbarEnabled"), YES);
}

static BOOL LSSStatusBarHideAMPM(void) {
    return LSSGetBoolPref(CFSTR("statusbarHideAMPM"), NO);
}

static NSDateFormatter *LSSStatusBarFormatter(BOOL includeSeconds) {
    static NSDateFormatter *secondsFormatter;
    static NSDateFormatter *minutesFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLocale *locale = NSLocale.autoupdatingCurrentLocale;

        secondsFormatter = [[NSDateFormatter alloc] init];
        secondsFormatter.locale = locale;
        secondsFormatter.dateFormat =
            [NSDateFormatter dateFormatFromTemplate:@"jmmss" options:0 locale:locale];

        minutesFormatter = [[NSDateFormatter alloc] init];
        minutesFormatter.locale = locale;
        minutesFormatter.dateFormat =
            [NSDateFormatter dateFormatFromTemplate:@"jmm" options:0 locale:locale];
    });

    NSDateFormatter *formatter = includeSeconds ? secondsFormatter : minutesFormatter;
    formatter.timeZone = NSTimeZone.localTimeZone;
    return formatter;
}

static NSString *LSSNormalizeWhitespace(NSString *text) {
    if (![text isKindOfClass:NSString.class]) {
        return @"";
    }

    NSArray<NSString *> *parts =
        [text componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSMutableArray<NSString *> *nonemptyParts = [NSMutableArray array];
    for (NSString *part in parts) {
        if (part.length > 0) {
            [nonemptyParts addObject:part];
        }
    }
    return [nonemptyParts componentsJoinedByString:@" "];
}

static NSString *LSSStringByRemovingDayPeriod(NSString *text,
                                               NSDateFormatter *formatter) {
    NSString *result = text ?: @"";
    NSArray<NSString *> *symbols = @[
        formatter.AMSymbol ?: @"",
        formatter.PMSymbol ?: @""
    ];

    for (NSString *symbol in symbols) {
        if (symbol.length > 0) {
            result = [result stringByReplacingOccurrencesOfString:symbol
                                                       withString:@""
                                                          options:NSCaseInsensitiveSearch
                                                            range:NSMakeRange(0, result.length)];
        }
    }
    return LSSNormalizeWhitespace(result);
}

static BOOL LSSIsStatusBarClockText(NSString *text) {
    if (![text isKindOfClass:NSString.class] || text.length == 0) {
        return NO;
    }

    NSString *candidate = LSSNormalizeWhitespace(text);
    NSDateFormatter *formatter = LSSStatusBarFormatter(NO);
    NSDate *now = NSDate.date;

    // Allow one minute of skew around a minute boundary. Compare both the
    // locale's full form and its AM/PM-free form because the stock status bar
    // may omit the day-period marker even in a 12-hour locale.
    for (NSInteger offset = -60; offset <= 60; offset += 60) {
        NSString *expected = LSSNormalizeWhitespace(
            [formatter stringFromDate:[now dateByAddingTimeInterval:offset]]);
        NSString *expectedWithoutPeriod =
            LSSStringByRemovingDayPeriod(expected, formatter);

        if ([candidate localizedCaseInsensitiveCompare:expected] == NSOrderedSame ||
            [candidate localizedCaseInsensitiveCompare:expectedWithoutPeriod] == NSOrderedSame) {
            return YES;
        }
    }

    // A fallback view may have received our seconds string before it was
    // attached to a window. Recognize that string when didMoveToWindow fires.
    formatter = LSSStatusBarFormatter(YES);
    for (NSInteger offset = -1; offset <= 1; offset++) {
        NSString *expected = LSSNormalizeWhitespace(
            [formatter stringFromDate:[now dateByAddingTimeInterval:offset]]);
        NSString *expectedWithoutPeriod =
            LSSStringByRemovingDayPeriod(expected, formatter);

        if ([candidate localizedCaseInsensitiveCompare:expected] == NSOrderedSame ||
            [candidate localizedCaseInsensitiveCompare:expectedWithoutPeriod] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

static NSString *LSSCurrentStatusBarTime(void) {
    NSDateFormatter *formatter = LSSStatusBarFormatter(YES);
    NSString *time = [formatter stringFromDate:NSDate.date];
    if (LSSStatusBarHideAMPM()) {
        return LSSStringByRemovingDayPeriod(time, formatter);
    }
    return time;
}

static void LSSStopStatusBarTimer(UILabel *view);
static void LSSApplyCurrentStatusBarTime(UILabel *view);

static void LSSStartStatusBarTimer(UILabel *view) {
    if (objc_getAssociatedObject(view, kStatusBarTimerKey)) {
        return;
    }

    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0,
                                                     0,
                                                     dispatch_get_main_queue());
    dispatch_source_set_timer(timer,
                              DISPATCH_TIME_NOW,
                              NSEC_PER_SEC,
                              50 * NSEC_PER_MSEC);

    __weak UILabel *weakView = view;
    dispatch_source_set_event_handler(timer, ^{
        UILabel *strongView = weakView;
        if (!strongView) {
            return;
        }

        if (!LSSStatusBarSecondsEnabled()) {
            LSSStopStatusBarTimer(strongView);
            return;
        }

        if (strongView.window) {
            LSSApplyCurrentStatusBarTime(strongView);
        }
    });

    objc_setAssociatedObject(view,
                             kStatusBarTimerKey,
                             timer,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dispatch_resume(timer);
}

static void LSSApplyCurrentStatusBarTime(UILabel *view) {
    if (!view) {
        return;
    }

    if (!LSSStatusBarSecondsEnabled()) {
        LSSStopStatusBarTimer(view);
        return;
    }

    objc_setAssociatedObject(view,
                             kStatusBarApplyingUpdateKey,
                             @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [view setText:LSSCurrentStatusBarTime()];
    objc_setAssociatedObject(view,
                             kStatusBarApplyingUpdateKey,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void LSSStopStatusBarTimer(UILabel *view) {
    dispatch_source_t timer =
        objc_getAssociatedObject(view, kStatusBarTimerKey);
    if (timer) {
        dispatch_source_cancel(timer);
        objc_setAssociatedObject(view,
                                 kStatusBarTimerKey,
                                 nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void LSSRegisterStatusBarClockView(UILabel *view) {
    if (!view) {
        return;
    }

    objc_setAssociatedObject(view,
                             kStatusBarClockViewKey,
                             @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (LSSStatusBarSecondsEnabled() && view.window && view.text.length > 0) {
        LSSStartStatusBarTimer(view);
        LSSApplyCurrentStatusBarTime(view);
    } else {
        LSSStopStatusBarTimer(view);
    }
}

static BOOL LSSIsRegisteredStatusBarClockView(UILabel *view) {
    return [objc_getAssociatedObject(view, kStatusBarClockViewKey) boolValue];
}

static BOOL LSSShouldApplyStatusBarSeconds(UILabel *view, NSString *text) {
    if (!LSSStatusBarSecondsEnabled() ||
        ![text isKindOfClass:NSString.class] ||
        text.length == 0) {
        return NO;
    }

    return LSSIsRegisteredStatusBarClockView(view) ||
           LSSIsStatusBarClockText(text);
}

static void LSSRegisterStatusBarTimeItemViews(id item) {
    if ([item respondsToSelector:@selector(timeView)]) {
        LSSRegisterStatusBarClockView((UILabel *)[item timeView]);
    }
    if ([item respondsToSelector:@selector(shortTimeView)]) {
        LSSRegisterStatusBarClockView((UILabel *)[item shortTimeView]);
    }
    if ([item respondsToSelector:@selector(pillTimeView)]) {
        LSSRegisterStatusBarClockView((UILabel *)[item pillTimeView]);
    }
}


%group LSSStatusBarIOS17TimeItemHooks

%hook STUIStatusBarTimeItem

- (id)applyUpdate:(id)update toDisplayItem:(id)displayItem {
    id result = %orig(update, displayItem);
    LSSRegisterStatusBarTimeItemViews(self);
    return result;
}

%end
%end


%group LSSStatusBarLegacyTimeItemHooks

%hook _UIStatusBarTimeItem

- (id)applyUpdate:(id)update toDisplayItem:(id)displayItem {
    id result = %orig(update, displayItem);
    LSSRegisterStatusBarTimeItemViews(self);
    return result;
}

%end
%end


%group LSSStatusBarIOS17Hooks

%hook STUIStatusBarStringView

- (void)setText:(NSString *)text {
    if ([objc_getAssociatedObject(self, kStatusBarApplyingUpdateKey) boolValue]) {
        %orig(text);
        return;
    }

    if (LSSShouldApplyStatusBarSeconds(self, text)) {
        if (self.window) {
            LSSStartStatusBarTimer(self);
        } else {
            LSSStopStatusBarTimer(self);
        }
        %orig(LSSCurrentStatusBarTime());
        return;
    }

    LSSStopStatusBarTimer(self);
    %orig(text);
}

- (void)didMoveToWindow {
    %orig;

    if (self.window && LSSShouldApplyStatusBarSeconds(self, self.text)) {
        LSSStartStatusBarTimer(self);
        LSSApplyCurrentStatusBarTime(self);
    } else {
        LSSStopStatusBarTimer(self);
    }
}

- (void)dealloc {
    LSSStopStatusBarTimer(self);
    %orig;
}

%end
%end


%group LSSStatusBarLegacyHooks

%hook _UIStatusBarStringView

- (void)setText:(NSString *)text {
    if ([objc_getAssociatedObject(self, kStatusBarApplyingUpdateKey) boolValue]) {
        %orig(text);
        return;
    }

    if (LSSShouldApplyStatusBarSeconds(self, text)) {
        if (self.window) {
            LSSStartStatusBarTimer(self);
        } else {
            LSSStopStatusBarTimer(self);
        }
        %orig(LSSCurrentStatusBarTime());
        return;
    }

    LSSStopStatusBarTimer(self);
    %orig(text);
}

- (void)didMoveToWindow {
    %orig;

    if (self.window && LSSShouldApplyStatusBarSeconds(self, self.text)) {
        LSSStartStatusBarTimer(self);
        LSSApplyCurrentStatusBarTime(self);
    } else {
        LSSStopStatusBarTimer(self);
    }
}

- (void)dealloc {
    LSSStopStatusBarTimer(self);
    %orig;
}

%end
%end


%ctor {
    @autoreleasepool {
        Class lockScreenControllerClass =
            objc_getClass("SBFLockScreenDateViewController");
        if (lockScreenControllerClass) {
            %init(LSSLockScreenControllerHooks);
            if (class_getInstanceMethod(lockScreenControllerClass,
                                        @selector(setScreenOff:))) {
                %init(LSSLockScreenScreenOffHooks);
            }
            if (class_getInstanceMethod(lockScreenControllerClass,
                                        @selector(_updateWithFrameSpecifier:))) {
                %init(LSSLockScreenAODFrameHooks);
            }
            if (class_getInstanceMethod(lockScreenControllerClass,
                                        @selector(setTimeAlpha:subtitleAlpha:))) {
                %init(LSSLockScreenAlphaHooks);
            }
        }
        if (objc_getClass("CSProminentTimeView")) {
            %init(LSSProminentTimeViewHooks);
        }

        Class statusBarTimeItemClass = objc_getClass("STUIStatusBarTimeItem");
        if (statusBarTimeItemClass &&
            class_getInstanceMethod(statusBarTimeItemClass,
                                    @selector(applyUpdate:toDisplayItem:))) {
            %init(LSSStatusBarIOS17TimeItemHooks);
        }
        if (objc_getClass("STUIStatusBarStringView")) {
            %init(LSSStatusBarIOS17Hooks);
        }

        Class legacyTimeItemClass = objc_getClass("_UIStatusBarTimeItem");
        if (legacyTimeItemClass &&
            class_getInstanceMethod(legacyTimeItemClass,
                                    @selector(applyUpdate:toDisplayItem:))) {
            %init(LSSStatusBarLegacyTimeItemHooks);
        }
        if (objc_getClass("_UIStatusBarStringView")) {
            %init(LSSStatusBarLegacyHooks);
        }
    }
}
