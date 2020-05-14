//
//  BJLScLoadingViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/9.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>
#import <BJLiveBase/BJLiveBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScLoadingViewController : UIViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

@property (nonatomic, nullable) void (^loadRoomInfoSucessCallback)(void);
@property (nonatomic, copy, nullable) void (^showCallback)(BOOL reloading);
@property (nonatomic, copy, nullable) void (^hideCallback)(void);
@property (nonatomic, copy, nullable) void (^exitCallbackWithError)(BJLError * _Nullable error);
@property (nonatomic, copy, nullable) void (^exitCallback)(void);

@end

NS_ASSUME_NONNULL_END
