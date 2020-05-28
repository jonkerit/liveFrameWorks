//
//  BJLIcWritingBoardBottomToolBarViewController.h
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/19.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BJLIcAppearance.h"
#import <BJLiveCore/BJLWritingBoard.h>

@class BJLRoom;

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcWritingBoardBottomToolBarViewController : UIViewController

@property (nonatomic, readonly) UIButton
*clearButton,                 //清空画笔
*nextPageButton,              //下一页
*prevPageButton,              //上一页
*revokeButton,                //撤销小黑板
*gatherButton,                //收回小黑板
*submitButton,                //提交
*publishButton,               //发布
*closeButton,                 //关闭
*reEditButton,                //重新编辑
*rePublishButton,             //再次发布
*restrictTimeButton,          //作答时间
*showNickNameButton           //显示昵称
;

@property (nonatomic, readonly) UILabel *pageNumberLabel, *timeForStuLabel, *timeForTeachLabel;

//老师设置的限制时间
@property (nonatomic, readonly) NSString *restrictTime;

@property (nonatomic) void(^showErrorMessage)(NSString *error);

- (instancetype)initWithRoom:(BJLRoom *)room;

- (instancetype)init NS_UNAVAILABLE;

- (void)updateViewConstraintsWithStatus:(BJLIcWriteBoardStatus)status shouldshareUserName:(BOOL)shouldshareUserName;

- (void)updateInputTimeString:(nullable NSString *)timeString;

@end

NS_ASSUME_NONNULL_END
