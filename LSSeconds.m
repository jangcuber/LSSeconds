//
//  LSSeconds.m
//
//  Created by CrazyMind90 on 01/08/2025.
//

#import "LSSeconds.h"

@interface LSSeconds ()
@property (nonatomic, strong) UIViewController *baseController;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *secondsLabel;
@property (nonatomic, strong) UILabel *ampmLabel;
@property (nonatomic, strong) UILabel *georgianDateLabel;
@property (nonatomic, strong) UILabel *hijriDateLabel;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSDateFormatter *secondsFormatter;
@property (nonatomic, strong) NSDateFormatter *ampmFormatter;
@property (nonatomic, strong) NSDateFormatter *georgianFormatter;
@property (nonatomic, strong) NSCalendar *hijriCalendar;
@property (nonatomic, strong) NSDateFormatter *hijriFormatter;
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
    
    self.georgianFormatter = [[NSDateFormatter alloc] init];
    [self.georgianFormatter setDateFormat:@"EEEE, MMMM d, yyyy"];
    
    self.hijriCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierIslamicUmmAlQura];
    self.hijriFormatter = [[NSDateFormatter alloc] init];
    self.hijriFormatter.calendar = self.hijriCalendar;
    [self.hijriFormatter setDateFormat:@"MMMM d, yyyy"];
}

- (void)setupViews {

    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = UIColor.clearColor;
    self.containerView.layer.cornerRadius = 20;
    self.containerView.layer.masksToBounds = YES;
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:108];
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.secondsLabel = [[UILabel alloc] init];
    self.secondsLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:24];
    self.secondsLabel.textColor = [UIColor colorWithWhite:0.9 alpha:0.8];
    self.secondsLabel.textAlignment = NSTextAlignmentCenter;
    self.secondsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.ampmLabel = [[UILabel alloc] init];
    self.ampmLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:20];
    self.ampmLabel.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    self.ampmLabel.textAlignment = NSTextAlignmentCenter;
    self.ampmLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.georgianDateLabel = [[UILabel alloc] init];
    self.georgianDateLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:19];
    self.georgianDateLabel.textColor = [UIColor whiteColor];
    self.georgianDateLabel.textAlignment = NSTextAlignmentCenter;
    self.georgianDateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.hijriDateLabel = [[UILabel alloc] init];
    self.hijriDateLabel.font = [UIFont fontWithName:@"ArialRoundedMTBold" size:18];
    self.hijriDateLabel.textColor = [UIColor colorWithWhite:0.9 alpha:0.7];
    self.hijriDateLabel.textAlignment = NSTextAlignmentCenter;
    self.hijriDateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.baseController.view addSubview:self.containerView];
    [self.containerView addSubview:self.timeLabel];
    [self.containerView addSubview:self.secondsLabel];
    [self.containerView addSubview:self.ampmLabel];
    [self.containerView addSubview:self.georgianDateLabel];
    [self.containerView addSubview:self.hijriDateLabel];
    
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[

        [self.containerView.centerXAnchor constraintEqualToAnchor:self.baseController.view.centerXAnchor],
        [self.containerView.topAnchor constraintEqualToAnchor:self.baseController.view.topAnchor constant:60],
        [self.containerView.widthAnchor constraintEqualToAnchor:self.baseController.view.widthAnchor],
        [self.containerView.heightAnchor constraintEqualToConstant:240],
        

        [self.timeLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.timeLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:20],
        
        [self.secondsLabel.leadingAnchor constraintEqualToAnchor:self.timeLabel.trailingAnchor constant:8],
        [self.secondsLabel.topAnchor constraintEqualToAnchor:self.timeLabel.topAnchor constant:35],
        
        [self.ampmLabel.centerXAnchor constraintEqualToAnchor:self.secondsLabel.centerXAnchor],
        [self.ampmLabel.topAnchor constraintEqualToAnchor:self.secondsLabel.bottomAnchor constant:4],
        
        [self.georgianDateLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.georgianDateLabel.topAnchor constraintEqualToAnchor:self.timeLabel.bottomAnchor constant:16],
        [self.georgianDateLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.georgianDateLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        
        [self.hijriDateLabel.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [self.hijriDateLabel.topAnchor constraintEqualToAnchor:self.georgianDateLabel.bottomAnchor constant:8],
        [self.hijriDateLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.containerView.leadingAnchor constant:16],
        [self.hijriDateLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.containerView.trailingAnchor constant:-16],
        [self.hijriDateLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.containerView.bottomAnchor constant:-16]
    ]];
}

- (void)startUpdating {
    [self updateTime];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:self
                                                      selector:@selector(updateTime)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)updateTime {
    NSDate *now = [NSDate date];
    
    self.timeLabel.text = [self.timeFormatter stringFromDate:now];
    self.secondsLabel.text = [self.secondsFormatter stringFromDate:now];
    self.ampmLabel.text = [self.ampmFormatter stringFromDate:now];
    
    self.georgianDateLabel.text = [self.georgianFormatter stringFromDate:now];
    
    self.hijriDateLabel.text = [NSString stringWithFormat:@"%@", [self.hijriFormatter stringFromDate:now]];
    
    [UIView animateWithDuration:0.1 animations:^{
        self.secondsLabel.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
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
}

@end
