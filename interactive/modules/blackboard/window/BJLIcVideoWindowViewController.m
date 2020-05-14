//
//  BJLIcVideoWindowViewController.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/21.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcVideoWindowViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcVideoWindowViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) UIView *containerView;
@property (nonatomic, readonly) NSString *mediaID;

@end

@implementation BJLIcVideoWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room mediaID:(nonnull NSString *)mediaID {
    self = [super init];
    if (self) {
        self->_room = room;
        self->_mediaID = mediaID;
        [self prepareToOpen];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupObservers];
}

- (void)viewDidLayoutSubviews {
    [self.videoView updateVideoViewConstranints];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 视图切换回来（比如从画廊布局切到黑板布局）时，需要将视频视图从画廊布局里重新抢回来布局
    [self.videoView getBackVideoView];
    [self.videoView updateVideoViewConstranints];
}

#pragma mark - subviews

- (void)setupSubviews {
    [self updateSubviewsLayout];
    self.relativeRect = [self windowRelativeRect];
}

- (void)updateSubviewsLayout {
    if (!self.videoView) {
        return;
    }
    
    [self.videoView removeFromSuperview];
    [self setContentViewController:nil contentView:self.videoView];
    
    // top bar
    [self.topBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(0));
    }];
    
    // bottom bar
    [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
    }];
}

#pragma mark - observers

- (void)setupObservers {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, loginUser)
           filter:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return !!now;
           }
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             // 权限
             BOOL isTeacherOrAssistant = self.room.loginUser.isTeacherOrAssistant;
             [self setWindowInterfaceEnabled:isTeacherOrAssistant];
             [self setWindowInterfaceEnabled:self.room.loginUser.isTeacherOrAssistant];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.playingVM, playingUsers)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             for (BJLMediaUser *user in self.room.playingVM.playingUsers) {
                 if ([user.mediaID isEqualToString:self.videoView.mediaID]) {
                     [self.videoView updateVideoViewConstranints];
                 }
             }
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.playingVM, playingViewAspectRatioChanged:forUser:)
             observer:(BJLMethodObserver)^BOOL(CGFloat ratio, BJLMediaUser *user) {
                 bjl_strongify(self);
                 if ([user.mediaID isEqualToString:self.videoView.user.mediaID]) {
                     [self updateSubviewsLayout];
                 }
                 return YES;
             }];
}

#pragma mark - override

- (void)close {
    if (self.videoWindowCloseCallback) {
        self.videoWindowCloseCallback(self.mediaID);
    }
    [super close];
}

- (void)closeWithoutRequest {
    if (self.videoWindowCloseCallback) {
        self.videoWindowCloseCallback(self.mediaID);
    }
    [super closeWithoutRequest];
}

#pragma mark - setters

- (void)setVideoView:(BJLIcUserMediaInfoView *)videoView {
    if (_videoView) {
        [_videoView removeFromSuperview];
    }
    _videoView = videoView;
    [self setupSubviews];
}

#pragma mark - private

- (CGRect)windowRelativeRect {
    CGSize windowAreaSize = self.windowedSuperview.bounds.size;
    if (CGSizeEqualToSize(windowAreaSize, CGSizeZero)) {
        return CGRectZero;
    }
    
    CGRect originRelativeRect = [self.windowedSuperview convertRect:self.videoView.frame fromView:self.videoView.superview];
    if (CGSizeEqualToSize(originRelativeRect.size, CGSizeZero)) {
        return CGRectZero;
    }
    
    // 弹出后宽度为黑板区域的 7.5 / 16
    CGFloat relativeWidth = 7.5 / 16.0, relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth width:originRelativeRect.size.width height:originRelativeRect.size.height];
    CGFloat centerX = CGRectGetMidX(originRelativeRect) / windowAreaSize.width;
    CGFloat centerY = CGRectGetMidY(originRelativeRect) / windowAreaSize.height;
    CGFloat relativeX = MIN(MAX(centerX - relativeWidth / 2.0, 0.0), 1.0 - relativeWidth);
    CGFloat relativeY = MIN(MAX(centerY - relativeHeight / 2.0, 0.0), 1.0 -  relativeHeight);
    return CGRectMake(relativeX, relativeY, relativeWidth, relativeHeight);
}

#pragma mark - private

- (void)prepareToOpen {
    self.caption = nil;
    
    self.relativeRect = ({
        CGFloat videoWidth = 1.0 / [BJLIcAppearance sharedAppearance].fullSizedVideosCount;
        // 弹出后放大 2 倍显示
        CGFloat relativeWidth = videoWidth * 2, relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth aspectRatio:[BJLIcAppearance sharedAppearance].videoAspectRatio];
        bjl_return CGRectMake(0.0, 0.0, relativeWidth, relativeHeight);
    });
    self.fixedAspectRatio = 0.0;
    
    self.topBarBackgroundViewHidden = YES;
    self.bottomBarBackgroundViewHidden = YES;
    self.resizeHandleImageViewHidden = YES;
    
    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.closeButtonHidden = YES;
    
    self.doubleTapToMaximize = YES;
    
    self.containerView = ({
        UIView *view = [UIView new];
        view.contentMode = UIViewContentModeScaleAspectFit;
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = @"mediaInfoContainerView";
        view;
    });
    [self.view addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.containerView);
    }];
}

- (CGRect)windowRectWithDocument:(BJLDocument *)document {
    BJLDocumentPageInfo *pageInfo = document.pageInfo;
    // 弹出后宽度为黑板区域的 7.5 / 16.0
    CGFloat relativeWidth = 7.5 / 16.0, relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth width:pageInfo.width height:pageInfo.height];
    return CGRectMake(0.0, 0.0, relativeWidth, relativeHeight);
}

@end

NS_ASSUME_NONNULL_END
