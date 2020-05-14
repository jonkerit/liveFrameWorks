//
//  BJLIcWritingBoardUserListHeaderView.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/11/13.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcWritingBoardUserListHeaderView : UIView

@property (nonatomic) UILabel *groupNameLabel;
@property (nonatomic) UIButton *openButton;

@property (nonatomic) void(^tapCallback)(BOOL show);

@end

NS_ASSUME_NONNULL_END
