//
//  BJLScImageViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/9.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScImageViewController : UIViewController

@property (nonatomic, nullable) void (^cancelStickyCallback)(void);

- (instancetype)initWithMessage:(BJLMessage *)message
                  imageMessages:(NSArray<BJLMessage *> *)imageMessages
                isStickyMessage:(BOOL)isStickyMessage;

- (void)hide;

@end

NS_ASSUME_NONNULL_END
