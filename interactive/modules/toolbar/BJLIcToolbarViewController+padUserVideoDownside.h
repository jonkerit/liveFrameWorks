//
//  BJLIcToolbarViewController+padUserVideoDownside.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolbarViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolbarViewController (padUserVideoDownside)

- (void)makePadUserVideoDownsideSubviews;
- (void)makePadUserVideoDownsideObserving;
- (void)makeTouchMoveGesture;
- (void)remakePadUserVideoDownsideContainerViewForTeacherOrAssistantWithmediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons;
- (void)remakePadUserVideoDownsideContainerViewForStudentWithMediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons;
- (void)remakePadUserVideoDownsideToolbarConstraintsWithDrawingGranted:(BOOL)drawingGranted mediaButtons:(NSArray *)mediaButtons optionButtons:(NSArray *)optionButtons;
- (nullable BJLIcUserMediaInfoView *)updatePadUserVideoDownsideTeacherMediaInfoViewLeaveSeat:(BOOL)leaveSeat;

@end

NS_ASSUME_NONNULL_END
