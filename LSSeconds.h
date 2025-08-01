//
//  LSSeconds.h
//
//  Created by CrazyMind90 on 01/08/2025.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LSSeconds : NSObject

- (instancetype)initWithBaseController:(UIViewController *)baseController;
- (void)startUpdating;
- (void)stopUpdating;

@end

NS_ASSUME_NONNULL_END
