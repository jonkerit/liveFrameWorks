//
//  BJLScWindowTopBar.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-25.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScWindowTopBar : UIView

@property (nonatomic, readonly) UILabel *captionLabel;
@property (nonatomic, readonly) UIButton *maximizeButton, *fullscreenButton, *closeButton;

@property (nonatomic, readonly) UIView *backgroundView;

@end

NS_ASSUME_NONNULL_END
