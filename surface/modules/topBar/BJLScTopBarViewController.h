//
//  BJLScTopBarViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScTopBarViewController : UIViewController

- (instancetype)initWithRoom:(BJLRoom *)room;

@property (nonatomic, nullable) void (^showSettingCallback)(void);
@property (nonatomic, nullable) void (^shareCallback)(void);
@property (nonatomic, nullable) void (^exitCallback)(void);

@end

NS_ASSUME_NONNULL_END
