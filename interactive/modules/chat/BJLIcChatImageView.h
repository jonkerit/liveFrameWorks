//
//  BJLIcChatImageView.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/9/3.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcChatImageView : UIView

@property (nonatomic, nullable) void (^hideCallback)(void);

- (instancetype)initWithMessages:(NSArray<BJLMessage *> *)messages currentMessage:(BJLMessage *)currentMessage;

- (void)updateMessages:(nullable NSMutableArray<BJLMessage *> *)messages;


@end

NS_ASSUME_NONNULL_END
