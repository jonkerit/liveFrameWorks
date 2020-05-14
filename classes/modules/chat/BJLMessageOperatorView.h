//
//  BJLMessageOperatorView.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/2/21.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLRecallType) {
    BJLRecallTypeNone,
    BJLRecallTypeNormal,
    BJLRecallTypeDelete,
};

@interface BJLMessageOperatorView : UIView

- (instancetype)initWithNeedTranslate:(BOOL)needTranslate
       needShowOnlyTeacherOrAssistant:(BOOL)needShowOnlyTeacherOrAssistant
                           recallType:(BJLRecallType)recallType
                     canStickyMessage:(BOOL)canStickyMessage;
- (void)updateButtonConstraints;

@property (nonatomic, nullable) void (^onClikCopyCallback)(BOOL on);
@property (nonatomic, nullable) void (^onClikTranslateCallback)(BOOL on);
@property (nonatomic, nullable) void (^onlyShowTeacherORAssistantMessageCallback)(BOOL on);
@property (nonatomic, nullable) void (^recallMessageCallback)(BOOL on);
@property (nonatomic, nullable) void (^stickyMessageCallback)(BOOL on);

@end

NS_ASSUME_NONNULL_END
