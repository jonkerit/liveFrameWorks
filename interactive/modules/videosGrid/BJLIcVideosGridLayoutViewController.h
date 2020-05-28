//
//  BJLIcVideosGridLayoutViewController.h
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcVideosGridLayoutViewController : UICollectionViewController

@property (nonatomic, nullable) void(^dataSourceEmptyCallback)(void);
@property (nonatomic, nullable) void(^receiveLikeCallback)(BJLUser *user, UIButton *button);
@property (nonatomic, nullable) void (^showErrorMessageCallback)(NSString *message);
@property (nonatomic, nullable) void (^updateVideoCallback)(BJLMediaUser *user, BOOL on);
@property (nonatomic, nullable) BOOL (^blockUserCallback)(BJLUser *user);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (void)updateContentWithUsers:(NSArray<BJLUser *> *)users room:(BJLRoom *)room;

@end

NS_ASSUME_NONNULL_END
