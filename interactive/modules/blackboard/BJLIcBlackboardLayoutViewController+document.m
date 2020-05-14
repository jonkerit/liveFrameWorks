//
//  BJLIcBlackboardLayoutViewController+document.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import "BJLIcBlackboardLayoutViewController+document.h"
#import "BJLIcBlackboardLayoutViewController+protected.h"
#import "BJLIcBlackboardLayoutViewController+padUserVideoDownside.h"
#import "BJLIcBlackboardLayoutViewController+padUserVideoUpside.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcBlackboardLayoutViewController (document)

#pragma mark - make observer for document

- (void)makeObserverForDocument {
    bjl_weakify(self);
    // web 文档窗口位置更新
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didUpdateWebDocumentWindowWithModel:shouldReset:)
             observer:(BJLMethodObserver)^BOOL(BJLWindowUpdateModel *updateModel, BOOL shouldReset) {
                 bjl_strongify(self);
                 if (shouldReset) {
                     [self resetWebDocumentWindowsWithModel:updateModel];
                 }
                 else {
                     [self updateWebDocumentWindowWithModel:updateModel];
                 }
                 return YES;
             }];
}

#pragma mark - blackboard page number

- (void)updateBlackboardPageNumber:(CGFloat)pageNumber {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hidePageNumberLabel) object:nil];
    self.pageNumberLabel.hidden = NO;
    NSString *text = @"";
    if (fabs(pageNumber - round(pageNumber))  < 0.1) {
        text = [NSString stringWithFormat:@"%.0f / %.0f", round(pageNumber), (CGFloat)self.room.documentVM.blackboardContentPages];
    }
    else {
        text = [NSString stringWithFormat:@"%.1f / %.1f", pageNumber, (CGFloat)self.room.documentVM.blackboardContentPages];
    }
    if (fabs(pageNumber - 1) < 0.1 || fabs(pageNumber - self.room.documentVM.blackboardContentPages) < 0.1) {
        self.pageNumberLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    }
    else {
        self.pageNumberLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    }
    self.pageNumberLabel.text = text;
    [self performSelector:@selector(hidePageNumberLabel) withObject:nil afterDelay:0.5];
}

- (void)hidePageNumberLabel {
    self.pageNumberLabel.hidden = YES;
}

#pragma mark - document window

- (void)resetDocumentWindowsWithModel:(BJLWindowUpdateModel *)updateModel {
    [self closeDisplayingDocumentWindowsWithRequestUpdate:NO];
    self.documentWindowDisplayInfos = [NSArray array];
    self.mutableDocumentWindowDisplayInfos = [NSMutableArray array];
    
    BOOL foundStick = NO;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        NSString *documentID = displayInfo.ID;
        //reset窗口的时候，不应该直接使用action，应该把每一个displayinfo都展示成窗口, 区分窗口和最大化，全屏
        NSString *action = BJLWindowsUpdateAction_open;
        if(displayInfo.isFullScreen) {
            action = BJLWindowsUpdateAction_fullScreen;
        }
        else if(displayInfo.isMaximized) {
            action = BJLWindowsUpdateAction_maximize;
        }
        if(action == BJLWindowsUpdateAction_open && foundStick == NO) {
            //第一个窗户是stick
            action = BJLWindowsUpdateAction_stick;
            foundStick = YES;
        }

        [self setupDocumentWindowWithID:documentID action:action displayInfo:displayInfo];
    }
}

- (void)updateDocumentWindowWithModel:(BJLWindowUpdateModel *)updateModel {
    NSString *documentID = updateModel.ID;
    if (!documentID.length) {
        return;
    }
    
    BJLWindowDisplayInfo *newDisplayInfo;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        if ([displayInfo.ID isEqualToString:documentID]) {
            newDisplayInfo = displayInfo;
            break;
        }
    }
    
    BJLWindowDisplayInfo *oldDisplayInfo;
    for (BJLWindowDisplayInfo *displayInfo in [self.documentWindowDisplayInfos copy]) {
        if ([displayInfo.ID isEqualToString:documentID]) {
            oldDisplayInfo = displayInfo;
            break;
        }
    }
    if (oldDisplayInfo) {
        [self.mutableDocumentWindowDisplayInfos removeObject:oldDisplayInfo];
    }
    
    [self setupDocumentWindowWithID:documentID action:updateModel.action displayInfo:newDisplayInfo];
}

- (void)setupDocumentWindowWithID:(NSString *)documentID action:(NSString *)action displayInfo:(nullable BJLWindowDisplayInfo *)displayInfo {
    // 关闭
    if ([action isEqualToString:BJLWindowsUpdateAction_close]) {
        [self closeDisplayingDocumentWindowWithID:documentID requestUpdate:NO];
        self.documentWindowDisplayInfos = self.mutableDocumentWindowDisplayInfos;
        return;
    }
    
    BJLIcDocumentWindowViewController *window = [self.displayingDocumentWindows bjl_objectForKey:documentID
                                                                                           class:[BJLIcDocumentWindowViewController class]];
    // 打开
    if ([action isEqualToString:BJLWindowsUpdateAction_open]
        || !window) {
        window = (BJLIcDocumentWindowViewController *)[self displayDocumentWindowWithID:documentID requestUpdate:NO];
    }
    
    // 全屏 !!!: no else if
    if ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]) {
        [window fullScreenWithoutRequest];
    }
    // 最大化
    else if ([action isEqualToString:BJLWindowsUpdateAction_maximize]) {
        [window maximizeWithoutRequest];
    }
    // 还原
    else if ([action isEqualToString:BJLWindowsUpdateAction_restore]) {
        if (displayInfo) {
            [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
        }
        [window restoreWithoutRequest];
    }
    else {
        [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
    }
    [window bringToFrontWithoutRequest];
    if (displayInfo) {
        [self.mutableDocumentWindowDisplayInfos bjl_addObject:displayInfo];
    }
    self.documentWindowDisplayInfos = self.mutableDocumentWindowDisplayInfos;
}

#pragma mark - web document window

- (void)resetWebDocumentWindowsWithModel:(BJLWindowUpdateModel *)updateModel {
    [self closeDisplayingWebDocumentWindowsWithRequestUpdate:NO];
    self.webDocumentWindowDisplayInfos = [NSArray array];
    self.mutableWebDocumentWindowDisplayInfos = [NSMutableArray array];
    
    BOOL foundStick = NO;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        NSString *documentID = displayInfo.ID;
        //reset窗口的时候，不应该使用action，应该把all displayinfo都展示成窗口, 区分窗口和最大化，全屏
        NSString *action = BJLWindowsUpdateAction_open;
        if(displayInfo.isFullScreen) {
            action = BJLWindowsUpdateAction_fullScreen;
        }
        else if(displayInfo.isMaximized) {
            action = BJLWindowsUpdateAction_maximize;
        }
        if(action == BJLWindowsUpdateAction_open && foundStick == NO) {
            //第一个窗户是stick
            action = BJLWindowsUpdateAction_stick;
            foundStick = YES;
        }

        [self setupWebDocumentWindowWithID:documentID action:action displayInfo:displayInfo];
    }
}

- (void)updateWebDocumentWindowWithModel:(BJLWindowUpdateModel *)updateModel {
    NSString *documentID = updateModel.ID;
    if (!documentID.length) {
        return;
    }
    
    BJLWindowDisplayInfo *newDisplayInfo;
    for (BJLWindowDisplayInfo *displayInfo in updateModel.displayInfos) {
        if ([displayInfo.ID isEqualToString:documentID]) {
            newDisplayInfo = displayInfo;
            break;
        }
    }
    
    for (BJLWindowDisplayInfo *displayInfo in [self.mutableWebDocumentWindowDisplayInfos copy]) {
        if ([displayInfo.ID isEqualToString:documentID]) {
            [self.mutableWebDocumentWindowDisplayInfos removeObject:displayInfo];
            break;
        }
    }
    
    [self setupWebDocumentWindowWithID:documentID action:updateModel.action displayInfo:newDisplayInfo];
}

- (void)setupWebDocumentWindowWithID:(NSString *)documentID action:(NSString *)action displayInfo:(nullable BJLWindowDisplayInfo *)displayInfo {
    // 关闭
    if ([action isEqualToString:BJLWindowsUpdateAction_close]) {
        [self closeDisplayingWebDocumentWindowWithID:documentID requestUpdate:NO];
        self.webDocumentWindowDisplayInfos = self.mutableWebDocumentWindowDisplayInfos;
        return;
    }
    
    BJLIcWebDocumentWindowViewController *window = [self.displayingWebDocumentWindows bjl_objectForKey:documentID
                                                                                                 class:[BJLIcWebDocumentWindowViewController class]];
    // 打开
    if ([action isEqualToString:BJLWindowsUpdateAction_open]
        || !window) {
        window = (BJLIcWebDocumentWindowViewController *)[self displayWebDocumentWindowWithID:documentID requestUpdate:NO];
    }
    
    // 全屏 !!!: no else if
    if ([action isEqualToString:BJLWindowsUpdateAction_fullScreen]) {
        [window fullScreenWithoutRequest];
    }
    // 最大化
    else if ([action isEqualToString:BJLWindowsUpdateAction_maximize]) {
        [window maximizeWithoutRequest];
    }
    // 还原
    else if ([action isEqualToString:BJLWindowsUpdateAction_restore]) {
        [window restoreWithoutRequest];
    }
    else {
        [window updateWithRelativeRect:CGRectMake(displayInfo.x, displayInfo.y, displayInfo.width, displayInfo.height)];
    }
    [window bringToFrontWithoutRequest];
    if (displayInfo) {
        [self.mutableWebDocumentWindowDisplayInfos bjl_addObject:displayInfo];
    }
    self.webDocumentWindowDisplayInfos = self.mutableWebDocumentWindowDisplayInfos;
}

@end

NS_ASSUME_NONNULL_END
