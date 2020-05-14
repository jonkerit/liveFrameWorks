//
//  BJLIcDocumentWindowViewController.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcDocumentWindowViewController.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"
#import "BJLAppearance.h"
#import "BJLIcLaserPointView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentWindowViewController () <UIPopoverPresentationControllerDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic, readwrite) NSInteger pageIndex;
@property (nonatomic) NSInteger pageCount;
@property (nonatomic) UIViewController<BJLSlideshowUI> *documentViewController;
@property (nonatomic, readonly, nullable) UIButton *pptRemarkInfoButton;
@property (nonatomic, readonly) UIButton *nextPageButton, *prevPageButton;
@property (nonatomic, readonly) UILabel *pageNumberLabel;
@property (nonatomic, nullable) id<BJLObservation> laserPointObservation;

#pragma mark - h5 ppt

// h5 文档数据如果没有总页码的情况下，禁用上层 UI 翻页，隐藏翻页按钮和页码数等信息
@property (nonatomic) BOOL disablePageChange;

@end

@implementation BJLIcDocumentWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room documentID:(NSString *)documentID {
    self = [super init];
    if (self) {
        self->_room = room;
        self->_documentID = documentID;
        self.documentViewController = [room.documentVM documentViewControllerWithID:documentID];
        bjl_weakify(self);
        self.documentViewController.shouldSwitchNativePPTBlock = ^(NSString * _Nullable documentID, void (^ _Nonnull callback)(BOOL)) {
            bjl_strongify(self);
            if (documentID.length && [documentID isEqualToString:self.documentID]) {
                callback(YES);
            }
        };
        self.documentViewController.prevPageIndicatorImage = [UIImage bjl_imageNamed:@"bjl_ic_ppt_prev"];
        self.documentViewController.nextPageIndicatorImage = [UIImage bjl_imageNamed:@"bjl_ic_ppt_next"];
        BJLDocument *document = [room.documentVM documentWithID:self.documentID];
        self.pageCount = document.pageInfo.pageCount;
        self.disablePageChange = document.pageInfo.isWebDoc && document.pageInfo.pageCount <= 1;
        [self prepareToOpen];
    }
    return self;
}

- (void)dealloc {
    [self.windowGestures removeAllObjects];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubviews];
    [self setupObservers];
}

#pragma mark - subviews

- (void)setupSubviews {
    if (!self.documentViewController) {
        return;
    }
    
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
    [self setContentViewController:self.documentViewController contentView:nil];
    
    // top bar
    [self.topBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
    }];
    
    // bottom bar
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    if (iPad && self.state == BJLWindowState_fullscreen) {
        [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@40.0);
        }];
    }
    else {
        [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
        }];
    }
    
    // page control
    self->_pageNumberLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.accessibilityLabel = BJLKeypath(self, pageNumberLabel);
        label;
    });
    [self.bottomBar addSubview:self.pageNumberLabel];
    [self.pageNumberLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.center.equalTo(self.bottomBar);
    }];
    
    self->_prevPageButton = ({
        UIButton *button = [UIButton new];
        [button setImage:[UIImage bjlic_imageNamed:@"window_prevpage"] forState:UIControlStateNormal];
        button.accessibilityLabel = BJLKeypath(self, prevPageButton);
        [button addTarget:self action:@selector(prevPage) forControlEvents:UIControlEventTouchUpInside];
        bjl_return button;
    });
    [self.bottomBar addSubview:self.prevPageButton];
    [self.prevPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.pageNumberLabel.bjl_left).offset(- [BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight / 2);
        make.top.bottom.equalTo(self.bottomBar);
        make.width.equalTo(self.prevPageButton.bjl_height);
    }];
    
    self->_nextPageButton = ({
        UIButton *button = [UIButton new];
        [button setImage:[UIImage bjlic_imageNamed:@"window_nextpage"] forState:UIControlStateNormal];
        button.accessibilityLabel = BJLKeypath(self, nextPageButton);
        [button addTarget:self action:@selector(nextPage) forControlEvents:UIControlEventTouchUpInside];
        bjl_return button;
    });
    [self.bottomBar addSubview:self.nextPageButton];
    [self.nextPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.pageNumberLabel.bjl_right).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight / 2);
        make.top.bottom.equalTo(self.bottomBar);
        make.width.equalTo(self.nextPageButton.bjl_height);
    }];

    self->_pptRemarkInfoButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"window_pptremark_off"] forState:UIControlStateNormal];
        [button setImage:[UIImage bjlic_imageNamed:@"window_pptremark_on"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(switchShowPPTRemarkInfo) forControlEvents:UIControlEventTouchUpInside];
        button.clipsToBounds = YES;
        button;
    });
    [self.bottomBar addSubview:self.pptRemarkInfoButton];
    [self.pptRemarkInfoButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self.bottomBar);
        make.left.equalTo(self.bottomBar).offset(12.0);
        make.width.equalTo(self.pptRemarkInfoButton.bjl_height);
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
             self.resizeHandleImageViewHidden = !isTeacherOrAssistant;
             [self setWindowGesturesEnabled:!self.room.drawingVM.drawingEnabled];
             BOOL enabledPPT = self.room.loginUser.isTeacher
                               || (self.room.loginUser.isStudent && self.room.documentVM.authorizedPPT)
                               || (self.room.loginUser.isAssistant && [self.room.roomVM getAssistantaAuthorityWithDocumentControl]);
             self.forgroundView.hidden = YES;
             [self.documentViewController updateScaleEnabled:YES];
             [self updatePPTUserInteractionEnabled:enabledPPT];
             self.pptRemarkInfoButton.hidden = !isTeacherOrAssistant;
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, allDocumentsDidOverwrite:)
             observer:^BOOL(NSArray<BJLDocument *> *allDocuments) {
                 bjl_strongify(self);
                 if (![self.room.documentVM documentWithID:self.documentID]) {
                     [self close];
                 }
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didDeleteDocument:)
               filter:^BOOL(BJLDocument *document){
                   bjl_strongify(self);
                   return [self.documentID isEqualToString:document.documentID];
               }
             observer:^BOOL{
                 bjl_strongify(self);
                 [self close];
                 return YES;
             }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingEnabled)
           filter:^BOOL(NSNumber *now, NSNumber *old, BJLPropertyChange * _Nullable change) {
               return now.boolValue != old.boolValue;
           } observer:^BOOL(NSNumber *now, NSNumber *old, BJLPropertyChange * _Nullable change) {
               bjl_strongify(self);
               [self setWindowGesturesEnabled:!now.boolValue];
               return YES;
           }];
    
    [self bjl_kvo:BJLMakeProperty(self.documentViewController, showPPTRemarkInfo)
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.pptRemarkInfoButton.selected = now.boolValue;
             return YES;
         }];
    
    [self bjl_kvoMerge:@[BJLMakeProperty(self.documentViewController, localPageIndex),
                         BJLMakeProperty(self, pageCount)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        self.pageIndex = self.documentViewController.localPageIndex;
        NSInteger pageNumber = self.pageIndex + 1;
        self.pageNumberLabel.text = [NSString stringWithFormat:@"%td/%td", pageNumber, self.pageCount];
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, allDocuments)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        BJLDocument *document = [self.room.documentVM documentWithID:self.documentID];
        if (!document.pageInfo.isWebDoc) {
            return NO;
        }
        // 更新页码等UI显示
        if (document) {
            self.disablePageChange = document.pageInfo.isWebDoc && document.pageInfo.pageCount <= 1;
            self.pageCount = document.pageInfo.pageCount;
            [self updatePPTUserInteractionEnabled:self.documentViewController.webPPTInteractable];
        }
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.documentViewController, canStepForward)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.nextPageButton.enabled = self.documentViewController.canStepForward;
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.documentViewController, canStepBackward)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.prevPageButton.enabled = self.documentViewController.canStepBackward;
             return YES;
         }];
    [self bjl_kvo:BJLMakeProperty(self, state)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
             if (iPad) {
                 if (self.state == BJLWindowState_fullscreen) {
                     [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
                         make.height.equalTo(@40.0);
                     }];
                 }
                 else {
                     [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
                         make.height.equalTo(@([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight));
                     }];
                 }
             }
             return YES;
         }];

    // 学生课件授权
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, authorizedPPT)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.loginUser.isStudent) {
            [self updatePPTUserInteractionEnabled:self.room.documentVM.authorizedPPT];
        }
        return YES;
    }];
    
    // 助教课件权限
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveAssistantaAuthorityChanged)
             observer:^BOOL{
        bjl_strongify(self);
        if (self.room.loginUser.isAssistant) {
            [self updatePPTUserInteractionEnabled:[self.room.roomVM getAssistantaAuthorityWithDocumentControl]];
        }
        return YES;
    }];
}

#pragma mark - override

- (void)openWithoutRequest {
    [super openWithoutRequest];
    [self setWindowGesturesEnabled:!self.room.drawingVM.drawingEnabled];
    BOOL enabled = self.room.loginUser.isTeacherOrAssistant || self.room.documentVM.authorizedPPT;
    [self updatePPTUserInteractionEnabled:enabled];
}

- (void)close {
    if (self.documentWindowCloseCallback) {
        self.documentWindowCloseCallback(self.documentID);
    }
    [super close];
}

- (void)closeWithoutRequest {
    if (self.documentWindowCloseCallback) {
        self.documentWindowCloseCallback(self.documentID);
    }
    [super closeWithoutRequest];
}

#pragma mark - private

- (void)updatePPTUserInteractionEnabled:(BOOL)enabled {
    [self.documentViewController updateScrollEnabled:enabled];
    [self.documentViewController updateWebPPTInteractable:enabled];
    self.prevPageButton.hidden = self.disablePageChange || !enabled;
    self.nextPageButton.hidden = self.disablePageChange || !enabled;
    self.pageNumberLabel.hidden = self.disablePageChange;
}

- (void)switchShowPPTRemarkInfo {
    [self.documentViewController updateShowPPTRemarkInfo:!self.documentViewController.showPPTRemarkInfo];
}

- (void)prevPage {
    [self.documentViewController pageStepBackward];
}

- (void)nextPage {
    [self.documentViewController pageStepForward];
}

- (void)prepareToOpen {
    BJLDocument *document = [self.room.documentVM documentWithID:self.documentID];
    if (!document) {
        self.relativeRect = CGRectZero;
        return;
    }
    
    self.caption = document.fileName;

    self.relativeRect = [self windowRectWithDocument:document];
    BJLDocumentPageInfo *pageInfo = document.pageInfo;
    self.fixedAspectRatio = pageInfo.width > 0.0 && pageInfo.height > 0.0 ? ((CGFloat)pageInfo.width / pageInfo.height) : 16.0 / 9.0;
}

- (CGRect)windowRectWithDocument:(BJLDocument *)document {
    BJLDocumentPageInfo *pageInfo = document.pageInfo;
    CGSize pageSize = CGSizeMake(pageInfo.width > 0.0 ? pageInfo.width : 320, pageInfo.height > 0.0 ? pageInfo.height : 180);
    // 弹出后宽度为黑板区域的 7.5 / 16.0
    CGFloat relativeWidth = 7.5 / 16.0;
    CGFloat relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth width:pageSize.width height:pageSize.height];
    return [self rectInBounds:CGRectMake(0.0, 0.0, relativeWidth, relativeHeight)];
}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - laserPointView

- (void)startObserverForLaserPointView:(UIView *)laserPointView {
    bjl_weakify(self);
    bjl_weakify(laserPointView);
    self.laserPointObservation =
    [self bjl_kvoMerge:@[BJLMakeProperty(self.documentViewController, imageFrameInPPTView),
                         BJLMakeProperty(laserPointView, superview)]
              observer:^(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
                  bjl_strongify(self);
                  bjl_strongify(laserPointView);
                  UIView *superView = laserPointView.superview;
                  if (!superView) {
                      return;
                  }
                  
                  CGRect imageFrame = self.documentViewController.imageFrameInPPTView;
                  BJLIcLaserPointView *view = bjl_as(laserPointView, BJLIcLaserPointView);

                  [laserPointView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                      make.left.equalTo(superView).offset(imageFrame.origin.x);
                      make.top.equalTo(superView).offset(imageFrame.origin.y);
                      make.size.equal.sizeOffset(imageFrame.size);
                  }];
        
                  [view updateShapeShowSize:imageFrame.size];
              }];
}

- (void)stopObserverForLaserPointView {
    [self.laserPointObservation stopObserving];
    self.laserPointObservation = nil;
}

@end

NS_ASSUME_NONNULL_END
