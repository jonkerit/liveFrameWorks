//
//  BJLIcChatOperatorView.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/2/26.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLIcRecallType) {
    BJLIcRecallTypeNone,
    BJLIcRecallTypeNormal,
    BJLIcRecallTypeDelete,
};

@interface BJLIcChatOperatorView : UIView

- (instancetype)initWithNeedTranslate:(BOOL)needTranslate recallType:(BJLIcRecallType)recallType;
- (void)updateButtonConstraints;

@property (nonatomic, nullable) void (^onClikCopyCallback)(BOOL on);
@property (nonatomic, nullable) void (^onClikTranslateCallback)(BOOL on);
@property (nonatomic, nullable) void (^recallMessageCallback)(BOOL on);

@end

NS_ASSUME_NONNULL_END
