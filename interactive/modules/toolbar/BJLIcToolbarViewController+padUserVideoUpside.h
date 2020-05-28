//
//  BJLIcToolbarViewController+padUserVideoUpside.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolbarViewController (padUserVideoUpside)

- (void)makePadUserVideoUpsideSubviews;
- (void)remakePadUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons;
- (void)remakePadUserVideoUpsideContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons;

@end

NS_ASSUME_NONNULL_END
