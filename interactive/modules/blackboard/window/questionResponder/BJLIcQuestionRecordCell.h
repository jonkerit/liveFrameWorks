//
//  BJLIcQuestionRecordCell.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/1/19.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcQuestionRecordCell : UITableViewCell

- (void)updateWithUser:(nullable BJLUser *)user groupInfo:(nullable BJLUserGroup *)groupInfo participateUserCount:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
