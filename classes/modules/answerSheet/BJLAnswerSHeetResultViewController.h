//
//  BJLAnswerSHeetResultViewController.h
//  BJLiveUI
//
//  Created by fanyi on 2019/7/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLAnswerSheet.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLAnswerSHeetResultViewController : UIViewController

// 关闭回调
@property (nonatomic, copy, nullable) void (^closeCallback)(void);

- (instancetype)initWithAnswerSheet:(BJLAnswerSheet *)answerSheet;

@end

NS_ASSUME_NONNULL_END
