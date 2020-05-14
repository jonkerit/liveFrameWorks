//
//  BJLScChatCell.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/25.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>
#import "BJLChatUploadingTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScChatCell : UITableViewCell

@property (nonatomic, readonly) UIImageView *iconImageView;

@property (nonatomic, copy, nullable) void (^updateConstraintsCallback)(BJLScChatCell * _Nullable cell);

@property (nonatomic, copy, nullable) void (^retryUploadingCallback)(BJLScChatCell * _Nullable cell);

@property (nonatomic, copy, nullable) BOOL (^linkURLCallback)(BJLScChatCell * _Nullable cell, NSURL *url);

@property (nonatomic, nullable) void (^longPressCallback)(BJLMessage *message, UIImage * _Nullable image, CGPoint pointInCell);

@property (nonatomic, copy, nullable) void (^userSelectCallback)(BJLScChatCell * _Nullable cell);

@property (nonatomic, copy, nullable) void (^imageSelectCallback)(BJLScChatCell * _Nullable cell);

- (void)updateWithMessage:(BJLMessage *)message
            fromLoginUser:(BOOL)fromLoginUser
               chatStatus:(BJLChatStatus)chatStatus
                 isSender:(BOOL)isSender;

- (void)updateWithUploadingTask:(BJLChatUploadingTask *)task
                     chatStatus:(BJLChatStatus)chatStatus
                       fromUser:(BJLUser *)fromUser;

+ (NSArray<NSString *> *)allCellIdentifiers;
+ (NSString *)cellIdentifierForUploadingImage;

+ (NSString *)cellIdentifierForMessageType:(BJLMessageType)type
                            hasTranslation:(BOOL)hasTranslation;

@end

NS_ASSUME_NONNULL_END
