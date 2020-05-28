//
//  BJLScSegmentViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLScChatViewController.h"
#import "BJLScQuestionViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScSegmentViewController : UIViewController

@property (nonatomic, copy, nullable) void (^showQuestionInputViewCallback)(BJLQuestion * _Nullable question);
@property (nonatomic, copy, nullable) void (^showChatInputViewCallback)(BOOL whisperChatUserExpend);
@property (nonatomic, copy, nullable) void (^showImageViewCallback)(BJLMessage *currentImageMessage, NSArray<BJLMessage *> *imageMessages, BOOL isStickyMessage);
@property (nonatomic, copy, nullable) void (^changeChatStatusCallback)(BJLChatStatus chatStatus, BJLUser * _Nullable targetUser);

@property (nonatomic, readonly) BJLScChatViewController *chatViewController;

- (instancetype)initWithRoom:(BJLRoom *)room;

@end

NS_ASSUME_NONNULL_END
