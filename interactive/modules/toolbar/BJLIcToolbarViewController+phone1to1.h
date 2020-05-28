//
//  BJLIcToolbarViewController+phone1to1.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolbarViewController (phone1to1)

- (void)makePhone1to1Subviews;
- (void)remakePhone1to1ContainerViewForTeacherOrAssistantWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons;
- (void)remakePhone1to1ContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons;

@end

NS_ASSUME_NONNULL_END
