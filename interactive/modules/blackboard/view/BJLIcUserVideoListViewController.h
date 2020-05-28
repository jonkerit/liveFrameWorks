//
//  BJLIcUserVideoListViewController.h
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcUserMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserVideoListViewController : UIViewController

@property (nonatomic, nullable) void(^popOverVideoViewCallback)(BJLUser *user);
@property (nonatomic, nullable) void(^replaceVideoViewCallback)(BJLMediaUser *old, BJLMediaUser *now);
@property (nonatomic, nullable) void(^sendBackVideoViewCallback)(BJLMediaUser *user);
@property (nonatomic, nullable) void(^sendBackAllVideoViewCallback)(void);
@property (nonatomic, nullable) void(^receiveLikeCallback)(BJLUser *user, UIButton *button);
@property (nonatomic, nullable) void(^showErrorMessageCallback)(NSString *message);
@property (nonatomic, nullable) void(^updateVideoCallback)(BJLMediaUser *user, BOOL on);
@property (nonatomic, nullable) BOOL(^blockUserCallback)(BJLUser *user);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) NSMutableDictionary *userMediaInfoViews;

- (nullable BJLIcUserMediaInfoView *)mediaInfoViewWithPanGesture:(UIPanGestureRecognizer *)panGesture;

- (nullable BJLIcUserMediaInfoView *)setUserLeaveSeatWithMediaID:(NSString *)mediaID;

- (void)sendUserBackToSeatWithMediaID:(NSString *)mediaID;

#pragma mark - observable methods

- (BJLObservable)videoUsersDidUpdate:(NSArray<BJLUser *> *)users;

@end

NS_ASSUME_NONNULL_END
