//
//  BJLIcToolbarViewController+phoneUserVideoUpside.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolbarViewController (phoneUserVideoUpside)

- (void)makePhoneUserVideoUpsideSubviews;
- (void)remakePhoneUserVideoUpsideContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons;
- (void)remakePhoneUserVideoUpsideContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons;

@end

NS_ASSUME_NONNULL_END
