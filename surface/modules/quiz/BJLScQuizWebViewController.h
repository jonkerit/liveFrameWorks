//
//  BJLScQuizWebViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>
#import <BJLiveBase/BJLWebViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScQuizWebViewController : BJLWebViewController

@property (nonatomic, copy, nullable) BJLError * _Nullable (^sendQuizMessageCallback)(NSDictionary<NSString *, id> *message);
@property (nonatomic, copy, nullable) void (^closeWebViewCallback)(void);

+ (nullable instancetype)instanceWithQuizMessage:(NSDictionary<NSString *, id> *)message roomVM:(BJLRoomVM *)roomVM;
+ (NSDictionary *)quizReqMessageWithUserNumber:(NSString *)userNumber;

- (void)didReceiveQuizMessage:(NSDictionary<NSString *, id> *)message;

@end

NS_ASSUME_NONNULL_END
