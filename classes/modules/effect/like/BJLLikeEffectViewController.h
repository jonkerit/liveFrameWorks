//
//  BJLLikeEffectViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2018/10/22.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLLikeEffectViewController : UIViewController

- (instancetype)initWithName:(NSString *)name;

- (instancetype)initForInteractiveClassWithName:(NSString *)name endPoint:(CGPoint)endPoint;

@end

NS_ASSUME_NONNULL_END
