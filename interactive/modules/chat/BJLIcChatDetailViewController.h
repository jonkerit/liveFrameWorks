//
//  BJLIcChatDetailViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/16.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcChatDetailViewController : UIViewController

- (instancetype)initWithMessage:(BJLMessage *)message imageMessages:(NSArray<BJLMessage *> *)imageMessages;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
