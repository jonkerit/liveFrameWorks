//
//  BJLScVideosViewController.h
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLScAppearance.h"
#import "BJLScMediaInfoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScVideosViewController : UIViewController

@property (nonatomic, nullable) void (^replaceMajorWindowCallback)(BJLScMediaInfoView * _Nullable mediaInfoView, NSInteger index, BJLScWindowType majorWindowType, BOOL recording); // 点击的视频，点击的视频索引，全屏视图将要替换成的类型
@property (nonatomic, nullable) void (^resetPPTCallback)(void);
@property (nonatomic, nullable) void (^updateVideoCallback)(BJLMediaUser *user, BOOL on);


- (instancetype)initWithRoom:(BJLRoom *)room;
// 重置视频列表，收回在全屏区域的视频
- (void)resetVideo;
// 替换视频列表 index 位置的内容替换到大屏，如果存在老师辅助摄像头，则替换老师辅助摄像头
- (void)replaceMajorContentViewAtIndex:(NSInteger)index recording:(BOOL)recording teacherExtraMediaInfoView:(nullable BJLScMediaInfoView *)teacherExtraMediaInfoView;

@end

NS_ASSUME_NONNULL_END
