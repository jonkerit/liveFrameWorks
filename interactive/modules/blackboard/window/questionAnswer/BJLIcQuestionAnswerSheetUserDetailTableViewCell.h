//
//  BJLIcQuestionAnswerSheetUserDetailTableViewCell.h
//  BJLiveUI
//
//  Created by fanyi on 2019/6/4.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BJLAnswerSheet;

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcQuestionAnswerSheetUserDetailTableViewCell : UITableViewCell

- (void)updateWithUserDetailModel:(nullable BJLAnswerSheetUserDetail *)userDetail
                      hasSubmited:(BOOL)hasSubmited
                         userInfo:(nullable BJLUser *)userInfo
                        groupInfo:(nullable BJLUserGroup *)groupInfo;

@end

NS_ASSUME_NONNULL_END
