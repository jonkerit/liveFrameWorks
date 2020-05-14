//
//  BJLScQuestionCell.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString
* const BJLScQuestionCellReuseIdentifier,
* const BJLScQuestionReplyCellReuseIdentifier;

@interface BJLScQuestionCell : UITableViewCell

@property (nonatomic, nullable) void (^singleTapCallback)(BJLQuestion *question, BJLQuestionReply * _Nullable questionReply, CGPoint point);

@property (nonatomic, nullable) void (^longPressCallback)(BJLQuestion *question, BJLQuestionReply * _Nullable questionReply, CGPoint point);

- (void)updateWithQuestion:(nullable BJLQuestion *)question questionReply:(nullable BJLQuestionReply *)questionReply;

+ (NSArray<NSString *> *)allCellIdentifiers;

@end

NS_ASSUME_NONNULL_END
