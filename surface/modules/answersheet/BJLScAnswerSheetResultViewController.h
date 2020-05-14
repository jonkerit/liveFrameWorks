//
//  BJLScAnswerSheetResultViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLAnswerSheet.h>
#import "BJLScWindowViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScAnswerSheetResultViewController : BJLScWindowViewController

// 关闭回调
@property (nonatomic, copy, nullable) void (^closeCallback)(void);

- (instancetype)initWithAnswerSheet:(BJLAnswerSheet *)answerSheet;

@end

NS_ASSUME_NONNULL_END
