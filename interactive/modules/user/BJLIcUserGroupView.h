//
//  BJLIcUserGroupView.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/12/28.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserGroupView : UIView

@property (nonatomic, readonly) UIButton *openButton;
@property (nonatomic, readonly) UILabel *groupNameLabel;
@property (nonatomic, readonly) UILabel *colorLabel;
@property (nonatomic, readonly) UILabel *countLabel;

@property (nonatomic, nullable) void(^clickCallback)(BOOL show);
- (void)updateWithGroupInfo:(BJLUserGroup *)groupInfo
                shouldClose:(BOOL)shouldClose;

@end

NS_ASSUME_NONNULL_END
