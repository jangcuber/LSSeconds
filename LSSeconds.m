//
//  LSSeconds.m
//
//  Created by CrazyMind90 on 01/08/2025.
//

#import "LSSeconds.h"
#import <math.h>

@interface LSSeconds ()
@property (nonatomic, weak) UIViewController *baseController;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *secondsLabel;
@property (nonatomic, strong) UILabel *ampmLabel;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSDateFormatter *secondsFormatter;
@property (nonatomic, strong) NSDateFormatter *ampmFormatter;
@property (nonatomic) BOOL aodActive;
@end

@implementation LSSeconds

- (instancetype)initWithBaseController:(UIViewController *)baseController {
    self = [super init];
    if (self) {
        _baseController = baseController;
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
    self.containerView.layer.cornerRadius = 20;
    self.containerView.layer.masksToBounds = YES;
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    

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
    
    [self.baseController.view addSubview:self.containerView];
    [self.containerView addSubview:self.timeLabel];
    [self.containerView addSubview:self.secondsLabel];
    [self.containerView addSubview:self.ampmLabel];
    
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[

        [self.containerView.centerXAnchor constraintEqualToAnchor:self.baseController.view.centerXAnchor],
        [self.containerView.topAnchor constraintEqualToAnchor:self.baseController.view.topAnchor constant:60],
        [self.containerView.widthAnchor constraintEqualToAnchor:self.baseController.view.widthAnchor],
        [self.containerView.heightAnchor constraintEqualToConstant:160],
        

        [self.timeLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.timeLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:20],
        
        [self.secondsLabel.leadingAnchor constraintEqualToAnchor:self.timeLabel.trailingAnchor constant:8],
        [self.secondsLabel.topAnchor constraintEqualToAnchor:self.timeLabel.topAnchor constant:35],
        
        [self.ampmLabel.centerXAnchor constraintEqualToAnchor:self.secondsLabel.centerXAnchor],
        [self.ampmLabel.topAnchor constraintEqualToAnchor:self.secondsLabel.bottomAnchor constant:4]
    ]];
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
    [self.containerView removeFromSuperview];
}

@end
