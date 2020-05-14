//
//  BJLScQuestionOptionView.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/27.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScQuestionOptionView : UIView

@property (nonatomic, nullable) void (^replyCallback)(BJLQuestion *question, BJLQuestionReply * _Nullable reply);
@property (nonatomic, nullable) void (^publishCallback)(BJLQuestion *question, BOOL publish);
@property (nonatomic, nullable) void (^copyCallback)(BJLQuestion *question);

- (instancetype)initWithRoom:(BJLRoom *)room question:(BJLQuestion *)question reply:(BJLQuestionReply *)reply;

- (CGSize)viewSize;

@end

NS_ASSUME_NONNULL_END
