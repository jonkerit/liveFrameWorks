//
//  BJLScSpeakRequestUserCell.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/24.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScSpeakRequestUserCell : UITableViewCell

@property (nonatomic, copy, nullable) void(^agreeRequestCallback)(BJLScSpeakRequestUserCell *cell, BOOL allow);

- (void)updateWithUser:(BJLUser *)user;

@end

NS_ASSUME_NONNULL_END
