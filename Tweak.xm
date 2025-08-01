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
-(void) setText:(NSString *)a1;
@end 

static NSTimer *globalTimer = nil;
static _UIStatusBarStringView *timeView = nil;

%hook _UIStatusBarStringView
- (void)setText:(NSString *)text {
    if ([text containsString:@":"]) {

        timeView = self;
        
        if (!globalTimer) {
            globalTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                                          repeats:YES 
                                                            block:^(NSTimer *timer) {
                if (timeView) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"hh:mm:ss"];
                    NSString *timeWithSeconds = [formatter stringFromDate:[NSDate date]];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [timeView setText:timeWithSeconds];
                    });
                }
            }];
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"h:mm:ss"];
        NSString *timeWithSeconds = [formatter stringFromDate:[NSDate date]];
        %orig(timeWithSeconds);
    } else {
        %orig(text);
    }
}

- (void)dealloc {
    if (timeView == self) {
        timeView = nil;
        if (globalTimer) {
            [globalTimer invalidate];
            globalTimer = nil;
        }
    }
    %orig;
}

%end
