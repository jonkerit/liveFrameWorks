//
//  BJLIcQuestionResponderWindowViewController+protected.h
//  BJLiveUI
//
//  Created by 凡义 on 2020/1/19.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import "BJLIcQuestionRecordCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcQuestionResponderWindowViewController ()

@property (nonatomic, weak) BJLRoom *room;

@property (nonatomic) UIView *bottomGapLine, *topGapLine, *overlayView;

@property (nonatomic) UIView *editContainerView, *bottomEditContainerView;
@property (nonatomic) UIButton *minusButton, *plusButton, *resetButton, *publishButton, *editHistoryButton;
@property (nonatomic) UITextField *timeTextField;

@property (nonatomic) UIView *publishingContainerView, *bottomPublishignContainerView;
@property (nonatomic) UIButton *revokeButton, *endButton, *publishingHistoryButton;

@property (nonatomic) UIView *resultContainerView, *bottomResultContainerView;
@property (nonatomic) UIButton *reeditButton, *resultHistoryButton;
@property (nonatomic) UILabel *userNameLabel, *noneSuccessLabel, *groupColorLabel, *groupNameLabel;
@property (nonatomic) UIImageView *successImageView;

//本次课节所有抢答记录
@property (nonatomic, nullable) NSArray<NSDictionary *> *questionResponderList;
@property (nonatomic) UITableView *questionRecordView;

@end

NS_ASSUME_NONNULL_END
