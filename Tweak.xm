// By @CrazyMind90

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "LSSeconds.h"


#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wprotocol"
#pragma GCC diagnostic ignored "-Wmacro-redefined"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma GCC diagnostic ignored "-Wincomplete-implementation"
#pragma GCC diagnostic ignored "-Wunknown-pragmas"
#pragma GCC diagnostic ignored "-Wformat"
#pragma GCC diagnostic ignored "-Wunknown-warning-option"
#pragma GCC diagnostic ignored "-Wincompatible-pointer-types"
#pragma GCC diagnostic ignored "-Wunused-value"
#pragma GCC diagnostic ignored "-Wunused-function"




@interface SBFLockScreenDateViewController : UIViewController
-(UIView *) dateView;
@end 

%hook SBFLockScreenDateViewController
- (void)viewDidLoad {

  %orig; 

  UIView *dateView = [self dateView];
  dateView.hidden = YES;

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
     [LSSeconds.alloc initWithBaseController:self.parentViewController];
  });

}
%end















@interface _UIStatusBarStringView : UIView
- (void)setText:(NSString *)a1;
@end

static const void *kViewTimerKey = &kViewTimerKey;

static dispatch_source_t CreatePerViewTimer(_UIStatusBarStringView *view) {
    dispatch_source_t timer = dispatch_source_create(
        DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
        dispatch_get_main_queue()   
    );
    dispatch_source_set_timer(timer,
                              DISPATCH_TIME_NOW,
                              1ull * NSEC_PER_SEC,
                              0);    
    __weak typeof(view) weakView = view;
    dispatch_source_set_event_handler(timer, ^{
        __strong typeof(weakView) strongView = weakView;
        if (!strongView) {
            dispatch_source_cancel(timer);
            return;
        }

        if (strongView.window) {
            NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
            [fmt setDateFormat:@"hh:mm:ss"];
            [strongView setText:[fmt stringFromDate:[NSDate date]]];
        }
    });
    dispatch_resume(timer);
    return timer;
}

%hook _UIStatusBarStringView

- (void)setText:(NSString *)text {
    if ([text containsString:@":"]) {

        dispatch_source_t timer = objc_getAssociatedObject(self, kViewTimerKey);
        if (!timer) {
            timer = CreatePerViewTimer(self);
            objc_setAssociatedObject(
                self,
                kViewTimerKey,
                timer,
                OBJC_ASSOCIATION_RETAIN_NONATOMIC
            );
        }

        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"h:mm:ss"];
        %orig([fmt stringFromDate:[NSDate date]]);
    } else {
        %orig(text);
    }
}

- (void)dealloc {

    dispatch_source_t timer = objc_getAssociatedObject(self, kViewTimerKey);
    if (timer) {
        dispatch_source_cancel(timer);
        objc_setAssociatedObject(self, kViewTimerKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }
    %orig;
}

%end
