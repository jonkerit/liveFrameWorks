//
//  BJLQuestionCell.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/2/11.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BJLViewImports.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString
* const BJLQuestionCellReuseIdentifier,
* const BJLQuestionReplyCellReuseIdentifier;

@interface BJLQuestionCell : UITableViewCell

@property (nonatomic, nullable) void (^singleTapCallback)(void);

@property (nonatomic, nullable) void (^longPressCallback)(NSString *content);

- (void)updateWithQuestion:(nullable BJLQuestion *)question questionReply:(nullable BJLQuestionReply *)questionReply;

+ (NSArray<NSString *> *)allCellIdentifiers;

@end

NS_ASSUME_NONNULL_END
