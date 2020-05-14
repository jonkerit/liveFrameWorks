//
//  BJLIcStudentQuestionResponderViewController.h
//  BJLiveUI
//
//  Created by fanyi on 2019/5/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BJLRoom;

NS_ASSUME_NONNULL_BEGIN

/** 学生端抢答器 */

@interface BJLIcStudentQuestionResponderViewController : UIViewController

@property (nonatomic, nullable) void (^errorCallback)(NSString *message);
@property (nonatomic, nullable) BOOL (^responderCallback)(void);
@property (nonatomic, nullable) void (^hiddenCallback)(void);

@property (nonatomic, nullable) void (^responderSuccessCallback)(BJLUser *user, UIButton *button);

- (instancetype)initWithRoom:(BJLRoom *)room
               countDownTime:(NSInteger)time;

- (instancetype)init NS_UNAVAILABLE;

- (void)hide;

@end

NS_ASSUME_NONNULL_END
