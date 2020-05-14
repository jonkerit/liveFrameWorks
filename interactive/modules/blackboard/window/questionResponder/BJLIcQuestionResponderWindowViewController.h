//
//  BJLIcQuestionResponderWindowViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/5/22.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

@class BJLRoom;
@class BJLUser;

NS_ASSUME_NONNULL_BEGIN

static NSString *const kQuestionRecordUserKey = @"user";
static NSString *const kQuestionRecordCountKey = @"count";

typedef NS_ENUM(NSInteger, BJLIcQuestionResponderWindowLayout) {
    BJLIcQuestionResponderWindowLayout_normal,  // 老师未发布状态
    BJLIcQuestionResponderWindowLayout_publish, // 老师已发布
    BJLIcQuestionResponderWindowLayout_end,     // 老师已结束答题
};

/** 老师端抢答器 */
@interface BJLIcQuestionResponderWindowViewController : BJLIcWindowViewController

// 发布抢答器, 返回值为判断是否操作成功
@property (nonatomic, nullable) BOOL (^publishQuestionResponderCallback)(NSTimeInterval time);

// 结束抢答器(区分是否为关闭窗口), 返回值为判断是否操作成功
@property (nonatomic, nullable) BOOL (^endQuestionResponderCallback)(BOOL close);

// 撤回抢答题, 返回值为判断是否操作成功
@property (nonatomic, nullable) BOOL (^revokeQuestionResponderCallback)(void);

// 在答题期间,点击右上角请求关闭抢答器
@property (nonatomic, nullable) void (^closeQuestionResponderCallback)(void);

// 关闭窗口回调
@property (nonatomic, nullable) void (^closeCallback)(void);

// 错误
@property (nonatomic, nullable) void (^errorCallback)(NSString *message);

@property (nonatomic, nullable) void (^keyboardFrameChangeCallback)(CGRect keyboardFrame);

@property (nonatomic, nullable) void (^responderSuccessCallback)(BJLUser *user, UIButton *button);

- (instancetype)initWithRoom:(BJLRoom *)room
                      layout:(BJLIcQuestionResponderWindowLayout)layout
         historeQuestionList:(NSArray * _Nullable)dic;

- (instancetype)init NS_UNAVAILABLE;

// 关闭抢答器窗口
- (void)closeQuestionResponder;

- (void)hideKeyboardView;

@end

NS_ASSUME_NONNULL_END
