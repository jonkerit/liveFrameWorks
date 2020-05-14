//
//  BJLIcQuizWindowViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/8/30.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcQuizWindowViewController : BJLIcWindowViewController

@property (nonatomic, nullable) BJLError * _Nullable (^sendQuizMessageCallback)(NSDictionary<NSString *, id> *message);
@property (nonatomic, nullable) void (^closeWebViewCallback)(void);
@property (nonatomic, nullable) void (^closeQuizCallback)(void);

+ (nullable instancetype)instanceWithRoom:(BJLRoom *)room quizMessage:(NSDictionary<NSString *, id> *)message;
+ (NSDictionary *)quizReqMessageWithUserNumber:(NSString *)userNumber;

- (void)didReceiveQuizMessage:(NSDictionary<NSString *, id> *)message;
- (void)updateCloseButtonHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
