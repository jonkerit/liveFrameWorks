//
//  BJLIcWritingBoardUserTableViewCell.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcWritingBoardUserTableViewCell : UITableViewCell

- (void)updateWithUser:(BJLUser *)user
             hasSubmit:(BOOL)hasSubmit
             hasRedDot:(BOOL)hasRedDot
             groupInfo:(nullable BJLUserGroup *)groupInfo;

@end

NS_ASSUME_NONNULL_END
