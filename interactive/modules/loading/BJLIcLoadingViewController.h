//
//  BJLIcLoadingViewController.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/18.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcLoadingViewController : UIViewController

/**
 退出教室
 */
@property (nonatomic, nullable) void (^exitCallback)(void);

/**
 加载完教室信息回调
 */
@property (nonatomic, nullable) void (^loadRoomInfoSucessCallback)(void);

/**
 隐藏回调
 */
@property (nonatomic, nullable) void (^hideCallback)(void);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
