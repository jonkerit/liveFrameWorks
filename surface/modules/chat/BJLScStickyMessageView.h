//
//  BJLScStickyMessageView.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/4/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLScStickyMessageView : UIView

@property (nonatomic, nullable) void (^cancelStickyCallback)(void);
@property (nonatomic, nullable) void (^updateConstraintsCallback)(BOOL showcompleteMessage);
@property (nonatomic, nullable) BOOL (^linkURLCallback)(NSURL *url);
@property (nonatomic, nullable) void (^imageSelectCallback)(BJLMessage * _Nullable message);

- (instancetype)initWithMessage:(nullable BJLMessage *)message canCancel:(BOOL)canCancel;
- (void)updateStickyMessage:(nullable BJLMessage *)message;
- (void)resetStickyMessageView;

@end

NS_ASSUME_NONNULL_END
