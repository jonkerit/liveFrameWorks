//
//  BJLScRoomViewController+actions.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScRoomViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScRoomViewController (actions)

- (void)makeActionsOnViewDidLoad;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)updatePPTUserInteractionEnable;
- (void)updateButtonStates;
- (void)replaceMajorContentViewWithPPTView;
- (void)replaceMinorContentViewWithPPTView;
- (void)replaceMajorContentViewWithTeacherMediaInfoView;
- (void)replaceMinorContentViewWithTeacherMediaInfoView;
- (void)showQuestionViewController;
- (void)updateQuestionRedDotHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
