//
//  BJLIcWritingBoardTopToolBarViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJLIcAppearance.h"
#import <BJLiveCore/BJLWritingBoard.h>

@class BJLRoom;

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcWritingBoardTopToolBarViewController : UIViewController

@property (nonatomic) void(^shareBoardCallback)(void);
@property (nonatomic) void(^screenShotCallback)(void);

@property (nonatomic, readonly) UILabel *studentNameLabel, *groupColorLabel, *groupNameLabel;

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

- (void)updateViewConstraintsWithStatus:(BJLIcWriteBoardStatus)status;

@end

NS_ASSUME_NONNULL_END
