//
//  BJLScSettingsViewController.h
//  BJLiveUI
//
//  Created by fanyi on 2019/9/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScSettingsViewController : BJLScrollViewController

@property (nonatomic, readonly) UISwitch *micSwitch, *cameraSwitch;

- (instancetype)initWithRoom:(BJLRoom *)room;

@end

NS_ASSUME_NONNULL_END
