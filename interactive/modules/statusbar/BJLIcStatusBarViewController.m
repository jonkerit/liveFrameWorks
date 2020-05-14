//
//  BJLIcStatusBarViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2018-09-13.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcStatusBarViewController.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcStatusBarViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) NSString *classTitle;
@property (nonatomic) NSDate *classStartDate;
@property (nonatomic, nullable) NSTimer *updateClassElapsedTimeTimer;
@property (nonatomic) dispatch_queue_t headerHandleQueue;

@property (nonatomic) UIView *backgroundView;
@property (nonatomic, readwrite) UIButton *exitButton;
@property (nonatomic) UILabel *classTitleLabel, *classElapsedTimeLabel;
@property (nonatomic) UIButton *upPackageLossRateButton, *downPackageLossRateButton;
@property (nonatomic) NSString *upPackageLossRateString, *downPackageLossRateString, *upNetworkStatusString, *downNetworkStatusString;

#pragma mark - weak network

// < userNumber, < time, loss rate > >
@property (nonatomic) NSMutableDictionary<NSString *, NSArray<NSDictionary<NSNumber *, NSNumber *> *> *> *lossRateDictionary;
@property (nonatomic, nullable) NSTimer *lossRateObservingTimer;
@property (nonatomic) CGFloat lossRateObservingTimeInterval;

@end

@implementation BJLIcStatusBarViewController

- (instancetype)initWithRoom:(id)room {
    if (self = [super init]) {
        self.upPackageLossRateString = @"--";
        self.downPackageLossRateString = @"--";
        self.upNetworkStatusString = @"优秀";
        self.downNetworkStatusString = @"优秀";
        self.lossRateDictionary = [NSMutableDictionary new];
        self.room = room;
        self.lossRateObservingTimeInterval = (self.room.featureConfig.lossRateRetainTime > 0) ? self.room.featureConfig.lossRateRetainTime : 10;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    
    [self makeSubviewsAndConstraints];
    [self makeObserving];
    
    // fire
    [self updateUploadPackageLossRateString:self.upPackageLossRateString networkStatusString:self.upNetworkStatusString];
    [self updateDownloadPackageLossRateString:self.downPackageLossRateString networkStatusString:self.downNetworkStatusString];
    [self updateClassTitle:self.room.roomInfo.title classStartDate:[NSDate dateWithTimeIntervalSince1970:self.room.roomInfo.startTimeInterval]];
    
    //[self restartUpdateClassElapsedTimeTimer];
    [self restartLossRateObservingTimer];
}

- (void)dealloc {
    [self stopUpdateClassElapsedTimeTimer];
    [self stopLossRateObservingTimer];
}

- (void)makeSubviewsAndConstraints {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    // 毛玻璃效果
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    self.backgroundView.accessibilityLabel = @"backgroundView";
    [self.view addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    if (BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) {
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    }
    
    BOOL needExitButton = ((BJLIcTemplateType_1v1 == self.room.roomInfo.interactiveClassTemplateType) && iPhone)
    || BJLIcTemplateType_userVideoUpside == self.room.roomInfo.interactiveClassTemplateType;
    if (needExitButton) {
        self.exitButton = ({
            UIButton *button = [BJLImageButton new];
            button.accessibilityLabel = BJLKeypath(self, exitButton);
            [button setImage:[UIImage bjlic_imageNamed:@"bjl_statusbar_exit"] forState:UIControlStateNormal];
            [self.view addSubview:button];
            bjl_return button;
        });
        
        // 按照顺序从右向左添加
        UIButton *last = nil;
        for (UIButton *button in @[self.exitButton]) {
            [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
                make.top.bottom.equalTo(self.view);
                make.right.equalTo(last.bjl_left ?: self.view);
                make.width.equalTo(button.bjl_height);
            }];
            last = button;
        }
    }
    
    // 课程标题 居中显示
    UIView *classInfoView = [UIView new];
    [self.view addSubview:classInfoView];
    [classInfoView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.equalTo(self.view);
        make.centerX.equalTo(self.view);
        make.width.equalTo(self.view.bjl_width).multipliedBy(2.0/5);
    }];
    
    self.classTitleLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentRight;
        label.numberOfLines = 1;
        label.text = self.classTitle;
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        [classInfoView addSubview:label];
        bjl_return label;
    });
    [self.classTitleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.equalTo(classInfoView);
        make.center.equalTo(classInfoView);
    }];
    
    // 经过时间标签
    self.classElapsedTimeLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentLeft;
        label.numberOfLines = 1;
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        [self.view addSubview:label];
        bjl_return label;
    });
    [self.classElapsedTimeLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.equalTo(classInfoView);
        make.right.equalTo(self.view);
        make.width.equalTo(@0.0);
    }];
    
    UIView *networkInfoView = ({
        UIView *view = [UIView new];
        [self.view addSubview:view];
        view;
    });
    [networkInfoView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.view);
    }];
    
    self.upPackageLossRateButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, upPackageLossRateButton);
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_statusbar_uplossrate"] forState:UIControlStateNormal];
        [button setAttributedTitle:[self packageLossRateAttributedStringWithString:self.upPackageLossRateString networkStatusString:self.upNetworkStatusString] forState:UIControlStateNormal];
        [networkInfoView addSubview:button];
        button.userInteractionEnabled = NO;
        bjl_return button;
    });
    [self.upPackageLossRateButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(@[networkInfoView, self.view]);
        make.left.equalTo(networkInfoView).offset(12.0);
    }];
    
    self.downPackageLossRateButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, downPackageLossRateButton);
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_statusbar_downlossrate"] forState:UIControlStateNormal];
        [button setAttributedTitle:[self packageLossRateAttributedStringWithString:self.downPackageLossRateString networkStatusString:self.downNetworkStatusString] forState:UIControlStateNormal];
        [networkInfoView addSubview:button];
        button.userInteractionEnabled = NO;
        bjl_return button;
    });
    [self.downPackageLossRateButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.upPackageLossRateButton.bjl_right).offset(12.0);
        make.top.bottom.equalTo(self.upPackageLossRateButton);
        make.right.equalTo(networkInfoView);
    }];
}

#pragma mark - observer

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room, featureConfig)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.backgroundView.hidden = self.room.featureConfig.backgroundURLString.length;
             self.view.backgroundColor = self.room.featureConfig.backgroundURLString.length ? [UIColor clearColor] : [[UIColor darkGrayColor] colorWithAlphaComponent:0.5];
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.mediaVM, mediaLossRateDidUpdateWithUser:videoLossRate:audioLossRate:)
             observer:(BJLMethodObserver)^BOOL(BJLMediaUser *user, CGFloat videoLossRate, CGFloat audioLossRate){
                 bjl_strongify(self);
                 // 目前只统计所有用户主摄流的丢包
                 if (user.mediaSource != BJLMediaSource_mainCamera) {
                     return YES;
                 }
                 
                 // 记录每个用户不同时间的丢包率数据
                 NSString *userNumber = user.number;
                 CGFloat packageLossRate = MIN(MAX(0.0, videoLossRate), 100.0);
                 NSString *userKey = [self userLossRateKeyWithUserNumber:userNumber mediaSource:user.mediaSource];
                dispatch_async(self.headerHandleQueue, ^{
                    NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                    if (!lossRateArray) {
                        lossRateArray = [NSMutableArray new];
                    }
                    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                    NSDictionary<NSNumber *, NSNumber *> *lossRateDic = [NSDictionary dictionaryWithObject:@(packageLossRate) forKey:@(timeInterval)];
                    [lossRateArray bjl_addObject:lossRateDic];
                    [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
                });
                 return YES;
             }];
}

#pragma mark - actions
- (NSString *)userLossRateKeyWithUserNumber:(NSString *)userNumber mediaSource:(BJLMediaSource)mediaSource {
    return [NSString stringWithFormat:@"%@-%td", userNumber, mediaSource];
}

- (BJLMediaSource)mediaSourceForUserLossRateKey:(NSString *)key{
    NSString *separator = @"-";
    BJLMediaSource mediaSource = BJLMediaSource_mainCamera;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        mediaSource = [key substringFromIndex:separatorRange.location + separatorRange.length].integerValue;
    }
    return mediaSource;
}
- (nullable NSString *)userNumberForUserLossRateKey:(NSString *)key{
    NSString *separator = @"-";
    NSString *userNumber = nil;
    NSRange separatorRange = [key rangeOfString:separator];
    if (separatorRange.location != NSNotFound) {
        userNumber = [key substringToIndex:separatorRange.location];
    }
    return userNumber;
}

// 更新上行丢包率和网络状况
- (void)updateUploadPackageLossRateString:(NSString *)packageLossRateString networkStatusString:(NSString *)networkStatusString {
    // 只有标签存在, 并且网络状态或丢包率的状态变化了, 才会更新
    dispatch_async(self.headerHandleQueue, ^{
        
        if (![self.upPackageLossRateString isEqualToString:packageLossRateString]) {
            self.upPackageLossRateString = packageLossRateString;
            if (self.upPackageLossRateButton) {
                NSAttributedString *packageLossRateAttributedString = [self packageLossRateAttributedStringWithString:packageLossRateString networkStatusString:networkStatusString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.upPackageLossRateButton setAttributedTitle:packageLossRateAttributedString forState:UIControlStateNormal];
                });
            }
        }
    });
}

// 更新下行丢包率和网络状态
- (void)updateDownloadPackageLossRateString:(NSString *)packageLossRateString networkStatusString:(NSString *)networkStatusString {
    // 只有标签存在, 并且网络状态或丢包率的状态变化了, 才会更新
    dispatch_async(self.headerHandleQueue, ^{
        
        if (![self.downPackageLossRateString isEqualToString:packageLossRateString]) {
            self.downPackageLossRateString = packageLossRateString;
            if (self.downPackageLossRateButton) {
                NSAttributedString *packageLossRateAttributedString = [self packageLossRateAttributedStringWithString:packageLossRateString networkStatusString:networkStatusString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.downPackageLossRateButton setAttributedTitle:packageLossRateAttributedString forState:UIControlStateNormal];
                });
            }
        }
    });
}

// !!!TODO: 目前不显示上课时长。课程没有任何超时相关提示
- (void)updateClassTitle:(NSString *)classTitle classStartDate:(NSDate *)classStartDate {
    if (![self.classTitle isEqualToString:classTitle]) {
        self.classTitle = classTitle;
        if (self.classTitleLabel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.classTitleLabel.text = classTitle;
            });
        }
    }
    if (!self.classStartDate || ![self.classStartDate isEqualToDate:classStartDate]) {
        self.classStartDate = classStartDate;
        //[self restartUpdateClassElapsedTimeTimer];
    }
}

#pragma mark - timer

- (void)restartUpdateClassElapsedTimeTimer {
    [self stopUpdateClassElapsedTimeTimer];
    bjl_weakify(self);
    self.updateClassElapsedTimeTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self || !self.classStartDate) {
            [timer invalidate];
            return;
        }
        dispatch_async(self.headerHandleQueue, ^{
            NSDate *currentDate = [NSDate date];
            NSTimeInterval elapsedTime = [currentDate timeIntervalSinceDate:self.classStartDate];
            NSString *elapsedTimeString = [self elapsedTimeStringWithTimeInterval:elapsedTime];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.classElapsedTimeLabel.text = elapsedTimeString;
            });
        });
        
    }];
}

- (void)stopUpdateClassElapsedTimeTimer {
    if (self.updateClassElapsedTimeTimer || [self.updateClassElapsedTimeTimer isValid]) {
        [self.updateClassElapsedTimeTimer invalidate];
        self.updateClassElapsedTimeTimer = nil;
    }
}

- (void)restartLossRateObservingTimer {
    [self stopLossRateObservingTimer];
    bjl_weakify(self);
    self.lossRateObservingTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify_ifNil(self) {
            [timer invalidate];
            return;
        }
        dispatch_async(self.headerHandleQueue, ^{
            CGFloat downloadLossRate = 0.0f;
            CGFloat uploadLossRate = 0.0f;
            BOOL hasCurrentLoginUser = NO;
            NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
            for (NSString *userKey in [self.lossRateDictionary.allKeys copy]) {
                // 读取每个用户的丢包率数据
                NSMutableArray<NSDictionary *> *lossRateArray = [[self.lossRateDictionary bjl_arrayForKey:userKey] mutableCopy];
                NSString *userNumber = [self userNumberForUserLossRateKey:userKey];
                NSInteger count = lossRateArray.count;
                
                if (count > 0) {
                    CGFloat totalLossRate = 0.0f;
                    for (NSDictionary<NSNumber *, NSNumber *> *lossRateDic in [lossRateArray copy]) {
                        // 读取用户丢包率数据中的时间，去掉 lossRateObservingTimeInterval 之外的时间
                        for (NSNumber *timeInterval in [lossRateDic.allKeys copy]) {
                            if (nowTimeInterval - [timeInterval bjl_doubleValue] > self.lossRateObservingTimeInterval) {
                                // 大于 lossRateObservingTimeInterval 的数据移除
                                [lossRateArray removeObject:lossRateDic];
                            }
                            else {
                                // 否则加入计算
                                totalLossRate += [lossRateDic bjl_floatForKey:timeInterval];
                            }
                        }
                    }
                    // 更新丢包率的字典
                    [self.lossRateDictionary bjl_setObject:lossRateArray forKey:userKey];
                    
                    if([userNumber isEqualToString:self.room.loginUser.number]) {
                        uploadLossRate = (lossRateArray.count > 0) ? totalLossRate / lossRateArray.count : 0.0f;
                        hasCurrentLoginUser = YES;
                    }
                    else {
                        downloadLossRate += (lossRateArray.count > 0) ? totalLossRate / lossRateArray.count : 0.0f;
                    }
                    // 超过边界认为是弱网
//                    if (totalLossRate / lossRateArray.count >= self.room.featureConfig.lossRateBoundary) {
//                        weakNetwork = YES;
//                        // 更新全部的丢包率字典，no break
//                    }
                }
            }
            
            if([self.lossRateDictionary.allKeys count]) {
                if(hasCurrentLoginUser && [self.lossRateDictionary.allKeys count] > 1) {
                    downloadLossRate = downloadLossRate / ([self.lossRateDictionary.allKeys count] - 1);
                }
                else if(!hasCurrentLoginUser){
                    downloadLossRate = downloadLossRate / ([self.lossRateDictionary.allKeys count]);
                }
                else {
                    downloadLossRate = 0.0f;
                }
            }
            else {
                downloadLossRate = 0.0f;
            }
            
            // 记录处理时间
            BJLNetworkStatus uploadNetWork = [self netWorkStatusWithLossRate:uploadLossRate];
            BJLNetworkStatus downloadNetWork = [self netWorkStatusWithLossRate:downloadLossRate];
            NSString *upPackageLossRateString = [NSString stringWithFormat:@"%.2f%%", uploadLossRate];
            NSString *downPackageLossRateString = [NSString stringWithFormat:@"%.2f%%", downloadLossRate];
            NSString *upNetworkStatusString = [self networkStatusStringWithNetworkingStatus:uploadNetWork];
            NSString *downNetworkStatusString = [self networkStatusStringWithNetworkingStatus:downloadNetWork];
            [self updateUploadPackageLossRateString:upPackageLossRateString networkStatusString:upNetworkStatusString];
            [self updateDownloadPackageLossRateString:downPackageLossRateString networkStatusString:downNetworkStatusString];

            // 提示
//            if (weakNetwork && self.showWeakNetworkTipCallback) {
//                bjl_dispatch_async_main_queue(^{
//                    self.showWeakNetworkTipCallback([BJLIcAppearance sharedAppearance].promptDuration);
//                });
//            }
        });
    }];
}

- (void)stopLossRateObservingTimer {
    if (self.lossRateObservingTimer || [self.lossRateObservingTimer isValid]) {
        [self.lossRateObservingTimer invalidate];
        self.lossRateObservingTimer = nil;
    }
}

#pragma mark - wheel

- (nullable NSAttributedString *)packageLossRateAttributedStringWithString:(NSString *)packageLossRateString networkStatusString:(NSString *)networkStatusString {
    if (!packageLossRateString.length) {
        return nil;
    }
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
    NSAttributedString *packageLossRateAttributedString = [[NSAttributedString alloc] initWithString:packageLossRateString
                                                                                          attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                                                                                        NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                                                        }];
    NSAttributedString *networkStatusAttributedString = [[NSAttributedString alloc] initWithString:networkStatusString
                                                                                        attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                                                                                      NSForegroundColorAttributeName : [self colorWithNetworkStatusString:networkStatusString],
                                                                                                      }];
    [mutableAttributedString appendAttributedString:packageLossRateAttributedString];
    [mutableAttributedString appendAttributedString:networkStatusAttributedString];
    return mutableAttributedString;
}

- (BJLNetworkStatus)netWorkStatusWithLossRate:(CGFloat)lossRate {
    NSArray *lossRateArray = [self.room.featureConfig.lossRateLevelArray copy];
    
    BJLNetworkStatus preLossRateLevel = BJLNetworkStatus_normal;
    BJLNetworkStatus currentLossRateLevel = BJLNetworkStatus_normal;
    for (NSInteger index = 0 ; index < [lossRateArray count]; index++) {
        NSNumber *nmber = [lossRateArray objectAtIndex:index];
        CGFloat lossRateLevel = nmber.floatValue;
        if(preLossRateLevel == BJLNetworkStatus_normal && lossRateLevel > 0 && lossRateLevel <= 100) {
            preLossRateLevel = (BJLNetworkStatus)index;
        }
        
        if(lossRateLevel <= 0 || lossRateLevel > 100) {
            continue;
        }
        
        if(lossRateLevel <= lossRate) {
            preLossRateLevel = (BJLNetworkStatus)index;
            continue;
        }
        
        if(lossRateLevel > lossRate) {
            currentLossRateLevel = (BJLNetworkStatus)index;
            break;
        }
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal && preLossRateLevel == BJLNetworkStatus_normal) {
        return BJLNetworkStatus_normal;
    }
    
    if(currentLossRateLevel == BJLNetworkStatus_normal) {
        currentLossRateLevel = (preLossRateLevel + 1 <= BJLNetworkStatus_Bad_level5) ? (preLossRateLevel + 1) : BJLNetworkStatus_Bad_level5;
    }
    else {
        currentLossRateLevel = (currentLossRateLevel <= BJLNetworkStatus_Bad_level5) ? currentLossRateLevel : BJLNetworkStatus_Bad_level5;
    }
    return currentLossRateLevel;
}

- (NSString *)networkStatusStringWithNetworkingStatus:(BJLNetworkStatus)status {
    NSString *networkStatusString = @"优秀";
    switch (status) {
        case BJLNetworkStatus_normal:
            networkStatusString = @"优秀";
            break;
            
        case BJLNetworkStatus_Bad_level1:
            networkStatusString = @"良好";
            break;
            
        case BJLNetworkStatus_Bad_level2:
            networkStatusString = @"差";
            break;
            
        case BJLNetworkStatus_Bad_level3:
        case BJLNetworkStatus_Bad_level4:
        case BJLNetworkStatus_Bad_level5:
            networkStatusString = @"极差";
            break;
            
        default:
            break;
    }
    return networkStatusString;
}

- (UIColor *)colorWithNetworkStatusString:(NSString *)networkStatusString {
    if ([networkStatusString isEqualToString:@"优秀"]) {
        return [UIColor bjl_colorWithHexString:@"#88FF00" alpha:1.0];
    }
    else if ([networkStatusString isEqualToString:@"良好"]) {
        return [UIColor bjl_colorWithHexString:@"#1199FF" alpha:1.0];
    }
    else if ([networkStatusString isEqualToString:@"差"]) {
        return [UIColor bjl_colorWithHexString:@"#FFBB33" alpha:1.0];
    }
    else if ([networkStatusString isEqualToString:@"极差"]) {
        return [UIColor bjl_colorWithHexString:@"#FF0000" alpha:1.0];
    }
    else {
        return [UIColor whiteColor];
    }
}


- (NSString *)elapsedTimeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    NSInteger elapsedTime = round(timeInterval);
    NSInteger second = elapsedTime % 60;
    NSInteger minute = (elapsedTime / 60) % 60;
    NSInteger hour = elapsedTime / 3600;
    NSString *secondString = second >= 10 ? [NSString stringWithFormat:@"%ld", (long)second] : [NSString stringWithFormat:@"0%ld", (long)second];
    NSString *minuteString = minute >= 10 ? [NSString stringWithFormat:@"%ld", (long)minute] : [NSString stringWithFormat:@"0%ld", (long)minute];
    NSString *hourString = hour >= 10 ? [NSString stringWithFormat:@"%ld", (long)hour] : [NSString stringWithFormat:@"0%ld", (long)hour];
    return [NSString stringWithFormat:@"已上课:  %@:%@:%@", hourString, minuteString, secondString];
}

- (dispatch_queue_t)headerHandleQueue {
    if (!_headerHandleQueue) {
        _headerHandleQueue =  dispatch_queue_create("header_handle_queue", DISPATCH_QUEUE_SERIAL);
    }
    return _headerHandleQueue;
}

@end

NS_ASSUME_NONNULL_END
