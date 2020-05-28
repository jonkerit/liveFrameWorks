//
//  BJLScUserCell.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScUserCell : UITableViewCell

@property (nonatomic, readonly) UIImageView *avatarImageView;

- (void)updateWithUser:(BJLUser *)user isSubCell:(BOOL)isSubCell;

@end

NS_ASSUME_NONNULL_END
