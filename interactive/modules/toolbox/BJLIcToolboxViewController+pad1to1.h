//
//  BJLIcToolboxViewController+pad1to1.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/7/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcToolboxViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcToolboxViewController (pad1to1)

- (void)remakePad1to1ContainerViewForTeacherOrAssistant;
- (void)remakePad1to1ContainerViewForStudent;
- (void)remakePad1to1ConstraintsWithButtons:(NSArray *)buttons;

@end

NS_ASSUME_NONNULL_END
