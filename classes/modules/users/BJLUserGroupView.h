//
//  BJLUserGroupView.h
//  BJLiveUI
//
//  Created by fanyi on 2019/7/4.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLUser.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLUserGroupView : UIView
@property (nonatomic) UILabel *userNumberLabel;

@property (nonatomic) void(^tagCallback)(BOOL show);

- (void)updateWithGroup:(BJLUserGroup *)group
       groupColorString:(NSString *)colorString
               selected:(BOOL)selected
       isLoginUserGroup:(BOOL)isLoginUserGroup
                  count:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
