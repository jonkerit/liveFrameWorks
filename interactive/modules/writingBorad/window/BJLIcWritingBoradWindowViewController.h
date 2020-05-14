//
//  BJLIcWritingBoradWindowViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/16.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcWindowViewController.h"
#import <BJLiveCore/BJLWritingBoard.h>

NS_ASSUME_NONNULL_BEGIN

@class BJLRoom;

@interface BJLIcWritingBoradWindowViewController : BJLIcWindowViewController

@property (nonatomic, readonly) BJLWritingBoard *writingBoard;

/** 窗口关闭回调 */
@property (nonatomic, nullable) void (^writingBoardWindowCloseCallback)(NSString *boardID, NSInteger pageIndex, NSString *userNumber);

/** 窗口分享回调 */
@property (nonatomic, nullable) void (^writingBoardWindowShareCallback)(BJLWritingBoard *writingBoard,  NSString *userNumber, CGRect relativeRect);

/** 老师分享的窗口是否显示昵称 */
@property (nonatomic, nullable) void (^teacherwillRenameWritingBoardCallback)(BJLWritingBoard *writingBoard, NSString *userNumber, NSString *name, CGRect relativeRect);

/** 窗口输入作答时间回调 */
@property (nonatomic) void(^showTimeInputCallBack)(void);

/** 老师重新编辑的回调, 需要关闭当前所有分享的窗口 */
@property (nonatomic, nullable) void (^teacherwillReEditWritingBoardCallback)(void);

- (instancetype)initWithRoom:(BJLRoom *)room
                writingBoard:(BJLWritingBoard *)writingBoard
                  userNumber:(NSString *)userNumber;

- (instancetype)init NS_UNAVAILABLE;

/** 小黑板的title */
- (void)updateCaptionWithName:(nullable NSString *)name groupInfo:(nullable BJLUserGroup *)groupInfo;

/** 提交小黑板*/
- (void)submitBoard;

/** 发布收回小黑板信令 + 关闭 */
- (void)teacherCloseWritingBoardWithGatherRequest;

/** 关闭小黑板窗口 */
- (void)closeWritingBoard;

/** 清空小黑板当前页面的所有shapes*/
- (nullable BJLError *)clearWritingBoard;

/** 分享的窗口关闭时, layer加回老师的管理窗口, 仅限老师的管理窗口可以调用 */
- (void)addParticipatedUserLayer:(NSString *)userLayer;

/** 窗口的时间输入回调,返回的时间,更新到窗口上 */
- (void)inputTimeString:(NSString *)timeString;

@end

NS_ASSUME_NONNULL_END
