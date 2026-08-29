//
//  LSSeconds.m
//
//  Created by CrazyMind90 on 01/08/2025.
//

#import "LSSeconds.h"
#import <math.h>

@interface LSSeconds ()
@property (nonatomic, weak) UIViewController *baseController;
@property (nonatomic, weak) UIView *referenceTimeView;
@property (nonatomic, weak) UIView *accessoryHostView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *accessoryContainerView;
@property (nonatomic, copy) NSArray<NSLayoutConstraint *> *positionConstraints;
@property (nonatomic, copy) NSArray<NSLayoutConstraint *> *accessoryPositionConstraints;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *secondsLabel;
@property (nonatomic, strong) UILabel *ampmLabel;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSDateFormatter *secondsFormatter;
@property (nonatomic, strong) NSDateFormatter *ampmFormatter;
@property (nonatomic) BOOL aodActive;
@property (nonatomic) BOOL accessoriesAboveDepth;
@end

@implementation LSSeconds

- (instancetype)initWithBaseController:(UIViewController *)baseController {
    return [self initWithBaseController:baseController
                      referenceTimeView:nil
                      accessoryHostView:nil];
}

- (instancetype)initWithBaseController:(UIViewController *)baseController
                      referenceTimeView:(UIView *)referenceTimeView {
    return [self initWithBaseController:baseController
                      referenceTimeView:referenceTimeView
                      accessoryHostView:nil];
}

- (instancetype)initWithBaseController:(UIViewController *)baseController
                      referenceTimeView:(UIView *)referenceTimeView
                      accessoryHostView:(UIView *)accessoryHostView {
    self = [super init];
    if (self) {
        _baseController = baseController;
        _referenceTimeView = referenceTimeView;
        _accessoryHostView = accessoryHostView;
        _accessoriesAboveDepth =
            LSSGetBoolPref(CFSTR("lockscreenAccessoriesAboveDepth"), NO);
        [self setupFormatters];
        [self setupViews];
        [self setupConstraints];
        [self startUpdating];
    }
    return self;
}

- (void)setupFormatters {

    self.timeFormatter = [[NSDateFormatter alloc] init];
    [self.timeFormatter setDateFormat:@"h:mm"];
    
    self.secondsFormatter = [[NSDateFormatter alloc] init];
    [self.secondsFormatter setDateFormat:@"ss"];
    
    self.ampmFormatter = [[NSDateFormatter alloc] init];
    [self.ampmFormatter setDateFormat:@"a"];
    
}

- (void)setupViews {

    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = UIColor.clearColor;
    self.containerView.userInteractionEnabled = NO;
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;

    self.accessoryContainerView = [[UIView alloc] init];
    self.accessoryContainerView.backgroundColor = UIColor.clearColor;
    self.accessoryContainerView.userInteractionEnabled = NO;
    self.accessoryContainerView.translatesAutoresizingMaskIntoConstraints = NO;

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:108 weight:UIFontWeightThin];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.secondsLabel = [[UILabel alloc] init];
    self.secondsLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightRegular];
    self.secondsLabel.textColor = [UIColor colorWithWhite:0.9 alpha:0.8];
    self.secondsLabel.textAlignment = NSTextAlignmentCenter;
    self.secondsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.ampmLabel = [[UILabel alloc] init];
    self.ampmLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightRegular];
    self.ampmLabel.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    self.ampmLabel.textAlignment = NSTextAlignmentCenter;
    self.ampmLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *hostView = self.referenceTimeView.superview ?: self.baseController.view;
    [hostView addSubview:self.containerView];
    [self.containerView addSubview:self.timeLabel];
    [self.containerView addSubview:self.accessoryContainerView];
    [self.accessoryContainerView addSubview:self.secondsLabel];
    [self.accessoryContainerView addSubview:self.ampmLabel];
    
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.timeLabel.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor],

        [self.secondsLabel.centerXAnchor constraintEqualToAnchor:self.accessoryContainerView.centerXAnchor],
        [self.secondsLabel.centerYAnchor constraintEqualToAnchor:self.accessoryContainerView.centerYAnchor constant:-15],

        [self.ampmLabel.centerXAnchor constraintEqualToAnchor:self.secondsLabel.centerXAnchor],
        [self.ampmLabel.topAnchor constraintEqualToAnchor:self.secondsLabel.bottomAnchor constant:4]
    ]];

    [self updatePositionConstraints];
}

- (void)updatePositionConstraints {
    [NSLayoutConstraint deactivateConstraints:self.positionConstraints ?: @[]];

    UIView *referenceView = self.referenceTimeView;
    UIView *hostView = referenceView.superview ?: self.baseController.view;
    if (!hostView) {
        self.positionConstraints = @[];
        return;
    }

    if (referenceView && referenceView.superview == hostView) {
        // Replace the native clock at the same z-order instead of covering
        // later siblings such as the charging indicator.
        [hostView insertSubview:self.containerView aboveSubview:referenceView];
    } else if (self.containerView.superview != hostView) {
        [self.containerView removeFromSuperview];
        [hostView addSubview:self.containerView];
    }

    if (referenceView && referenceView.superview == hostView) {
        // Follow the system clock's live layout. iOS moves this view to make
        // room for the date, charging indicator, notifications, and AOD.
        self.positionConstraints = @[
            [self.containerView.centerXAnchor constraintEqualToAnchor:referenceView.centerXAnchor],
            [self.containerView.centerYAnchor constraintEqualToAnchor:referenceView.centerYAnchor],
            [self.containerView.widthAnchor constraintEqualToAnchor:hostView.widthAnchor],
            [self.containerView.heightAnchor constraintEqualToConstant:140]
        ];
    } else {
        // Legacy fallback for systems where the native time view is not
        // exposed. Keep this path until the reference view becomes available.
        self.positionConstraints = @[
            [self.containerView.centerXAnchor constraintEqualToAnchor:hostView.centerXAnchor],
            [self.containerView.topAnchor constraintEqualToAnchor:hostView.topAnchor constant:70],
            [self.containerView.widthAnchor constraintEqualToAnchor:hostView.widthAnchor],
            [self.containerView.heightAnchor constraintEqualToConstant:140]
        ];
    }

    [NSLayoutConstraint activateConstraints:self.positionConstraints];
    [self updateAccessoryPositionConstraints];
}

- (void)updateAccessoryPositionConstraints {
    [NSLayoutConstraint deactivateConstraints:self.accessoryPositionConstraints ?: @[]];

    UIView *overlayHost = self.accessoryHostView;
    BOOL canUseDepthOverlay =
        self.accessoriesAboveDepth &&
        overlayHost &&
        self.referenceTimeView &&
        [self.referenceTimeView isDescendantOfView:overlayHost];
    UIView *hostView = canUseDepthOverlay ? overlayHost : self.containerView;

    if (self.accessoryContainerView.superview != hostView) {
        [self.accessoryContainerView removeFromSuperview];
        [hostView addSubview:self.accessoryContainerView];
    }

    // These constraints intentionally bridge the native clock hierarchy when
    // the accessory is in the overlay. Both views share accessoryHostView as
    // a common ancestor, so seconds continue to follow the main clock.
    self.accessoryPositionConstraints = @[
        [self.accessoryContainerView.leadingAnchor
            constraintEqualToAnchor:self.timeLabel.trailingAnchor
                         constant:8],
        [self.accessoryContainerView.centerYAnchor
            constraintEqualToAnchor:self.timeLabel.centerYAnchor],
        [self.accessoryContainerView.widthAnchor constraintEqualToConstant:64],
        [self.accessoryContainerView.heightAnchor constraintEqualToConstant:80]
    ];
    [NSLayoutConstraint activateConstraints:self.accessoryPositionConstraints];
}

- (UIView *)desiredAccessoryHostView {
    UIView *overlayHost = self.accessoryHostView;
    if (self.accessoriesAboveDepth &&
        overlayHost &&
        self.referenceTimeView &&
        [self.referenceTimeView isDescendantOfView:overlayHost]) {
        return overlayHost;
    }
    return self.containerView;
}

- (void)updateReferenceTimeView:(UIView *)referenceTimeView {
    if (!referenceTimeView) {
        return;
    }

    if (self.referenceTimeView != referenceTimeView) {
        self.referenceTimeView = referenceTimeView;
        [self updatePositionConstraints];
        return;
    }

    // On iOS 17/18 the prominent clock can enter its final hierarchy after
    // viewWillAppear. Retry only when the desired host has actually changed.
    if (self.accessoryContainerView.superview != [self desiredAccessoryHostView]) {
        [self updateAccessoryPositionConstraints];
    }
}

- (void)startUpdating {
    // Always resync immediately when returning from AOD or another delayed
    // run-loop state, even if an existing timer is still valid.
    [self updateTime];

    if (self.updateTimer) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0
                                           repeats:YES
                                             block:^(__unused NSTimer *timer) {
        [weakSelf updateTime];
    }];

    NSDate *now = [NSDate date];
    NSTimeInterval fractionalSecond = fmod(now.timeIntervalSince1970, 1.0);
    timer.fireDate = [now dateByAddingTimeInterval:(1.0 - fractionalSecond)];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.updateTimer = timer;
}

- (void)updateTime {
    [self updateTimeForDate:[NSDate date] updateSeconds:YES animated:YES];
}

- (void)updateTimeForDate:(NSDate *)date
            updateSeconds:(BOOL)updateSeconds
                 animated:(BOOL)animated {
    if (!date) {
        return;
    }

    self.timeLabel.text = [self.timeFormatter stringFromDate:date];
    self.ampmLabel.text = [self.ampmFormatter stringFromDate:date];
    self.aodActive = !updateSeconds;
    self.secondsLabel.hidden = !updateSeconds;

    if (updateSeconds) {
        self.secondsLabel.text = [self.secondsFormatter stringFromDate:date];
    }

    if (!animated) {
        [self.secondsLabel.layer removeAllAnimations];
        self.secondsLabel.transform = CGAffineTransformIdentity;
        return;
    }

    [UIView animateWithDuration:0.1 animations:^{
        self.secondsLabel.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
        if (!finished || self.aodActive) {
            self.secondsLabel.transform = CGAffineTransformIdentity;
            return;
        }

        [UIView animateWithDuration:0.1 animations:^{
            self.secondsLabel.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)stopUpdating {
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

- (void)dealloc {
    [self stopUpdating];
    [self.accessoryContainerView removeFromSuperview];
    [self.containerView removeFromSuperview];
}

@end
