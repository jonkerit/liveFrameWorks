//
//  BJLIcQuestionAnswerViewController.h
//  BJLiveUI
//
//  Created by fanyi on 2019/5/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"

@class BJLRoom;
@class BJLAnswerSheet;

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, BJLIcQuestionAnswerWindowLayout) {
    BJLIcQuestionAnswerWindowLayout_normal,     // 老师未发布状态
    BJLIcQuestionAnswerWindowLayout_publish,    // 老师已发布
    BJLIcQuestionAnswerWindowLayout_end,        // 老师已结束答题
};

/** 答题器 */
@interface BJLIcQuestionAnswerViewController : BJLIcWindowViewController

// 发布答题器
@property (nonatomic, nullable) void (^publishQuestionAnswerCallback)(BJLAnswerSheet *answerSheet);

// 结束答题器
@property (nonatomic, nullable) void (^endQuestionAnswerCallback)(BOOL close);

// 撤回答题器
@property (nonatomic, nullable) void (^revokeQuestionAnswerCallback)(void);

// 关闭答题器
@property (nonatomic, nullable) void (^closeQuestionAnswerCallback)(void);

// 关闭窗口回调
@property (nonatomic, nullable) void (^closeCallback)(void);

// 请求详情
@property (nonatomic, nullable) BOOL (^requestQuestionDetailCallback)(NSString *ID);

// 错误提示
@property (nonatomic, nullable) void (^errorCallback)(NSString *message);

@property (nonatomic, nullable) void (^keyboardFrameChangeCallback)(CGRect keyboardFrame);

- (instancetype)initWithRoom:(BJLRoom *)room
                 answerSheet:(BJLAnswerSheet *)answerSheet
                      layout:(BJLIcQuestionAnswerWindowLayout)layout;

- (instancetype)init NS_UNAVAILABLE;

// 关闭抢答器窗口
- (void)closeQuestionAnswer;

- (void)hideKeyboardView;

@end

NS_ASSUME_NONNULL_END
