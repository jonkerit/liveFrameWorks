//
//  BJLIcUserMediaInfoView+private.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJL_M9Dev.h>

#import "BJLIcUserMediaInfoView.h"
#import "BJLIcUserOperateView.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcUserMediaInfoView () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, readwrite) BJLMediaUser *user;

@property (nonatomic) UIView *containerView;
@property (nonatomic) UIImageView *videoOffImageView;
@property (nonatomic) UIImageView *audioOnlyImageView;
@property (nonatomic) UIButton *speakRequestButton;
@property (nonatomic) UIView *speakRequestControlView;
@property (nonatomic) UIButton *allowSpeakRequestButton, *refuseSpeakRequestButton;
@property (nonatomic) UIView *infoGroupView, *groupColorView;
@property (nonatomic) UIImageView *audioLevelView, *signalLevelView;
@property (nonatomic) UILabel *userNameLabel;
@property (nonatomic) UIImageView *drawingGrantedView, *webPPTAuthorizedView;
@property (nonatomic, weak) UIView *videoView;
@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, readwrite) UIButton *likeButton;
@property (nonatomic) UIViewController *optionViewController;
@property (nonatomic, weak) UIViewController *parentViewController;
@property (nonatomic) UIView *videoLoadingView;
@property (nonatomic) UIImageView *videoLoadingImageView;

#pragma mark - weak nerwork

@property (nonatomic) UILabel *lossRateLable;

@property (nonatomic) UILabel *networkMessageLabel;
@property (nonatomic) BOOL isNetworkMessageShowing;

// < userNumber, < time, loss rate key > >
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *lossRateDictionary;

//主讲人丢包率
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *presenterLossRateDictionary;
@property (nonatomic, nullable) NSTimer *lossRateObservingTimer;

- (UIImageView *)imageViewWithName:(NSString *)imageName;
- (BOOL)sendLikeForCurrentUser;
- (BOOL)blockCurrentUser;
- (void)showSpeakRequestControlView;
- (void)allowSpeakRequest;
- (void)refuseSpeakRequest;

@end

NS_ASSUME_NONNULL_END
