//
//  BJLScQuestionViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScQuestionViewController : BJLTableViewController

@property (nonatomic, nullable) void (^replyCallback)(BJLQuestion *question, BJLQuestionReply * _Nullable reply);
@property (nonatomic, nullable) void (^newMessageCallback)(void);
@property (nonatomic, nullable) void (^showQuestionInputViewCallback)(void);

- (instancetype)initWithRoom:(BJLRoom *)room;
- (void)sendQuestion:(NSString *)content;
- (void)clearReplyQuestion;
- (void)updateQuestion:(BJLQuestion *)question reply:(NSString *)reply;
- (void)updateSegmentHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
