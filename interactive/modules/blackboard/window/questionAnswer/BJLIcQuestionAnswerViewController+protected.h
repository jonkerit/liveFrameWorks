//
//  BJLIcQuestionAnswerViewController+protected.h
//  BJLiveUI
//
//  Created by fanyi on 2019/5/28.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcQuestionAnswerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcQuestionAnswerViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) BJLAnswerSheet *answerSheet;
@property (nonatomic, nullable) NSTimer *countDownTimer;
@property (nonatomic) UIView *bottomGapLine, *topGapLine, *overlayView;

#pragma mark - 编辑题目界面
@property (nonatomic) UIView *editContainerView, *bottomEditContainerView;
//题目类型
@property (nonatomic) UIView *topChoosenContainView;
@property (nonatomic) UIButton *choosenButton, *judgementButton, *shuoldShowCorrectAnswerButton;

//选项 ：选择题
@property (nonatomic) UIView *optionsContainView;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIButton *minusOptionButton, *plusOptionButton;
@property (nonatomic) UILabel *optionTipLabel;

//选项 ：是非题
@property (nonatomic) UIView *judgementContainView, *judgementTitleContainView;
@property (nonatomic) UIButton *judgeTitleButton, *judgeTitleIconButton;
@property (nonatomic) UIView *rightButtonView, *wrongButtonView;
@property (nonatomic) UIButton *rightButton, *wrongButton;
@property (nonatomic) UIImageView *selectedRightIconImageView, *selectedWrongIconImageView;
@property (nonatomic) UITableView *judgeTitleTableView;
@property (nonatomic) UITextField *rightTextField, *wrongTextField;
@property (nonatomic) UILabel *judgementTipLabel;
@property (nonatomic) NSMutableArray <NSDictionary *> *judgeTitleArray;
//备注
@property (nonatomic) UIView *commentsContainView;
@property (nonatomic) UITextView *commentsTextView;
@property (nonatomic) UILabel *commentsTextCountLabel;

//底部
@property (nonatomic) UIButton *minusTimeButton, *plusTimeButton, *resetButton, *publishButton;
@property (nonatomic) UITextField *timeTextField;


#pragma mark - 发布界面
@property (nonatomic) UIView *publishContainerView, *bottomPublishContainerView;
@property (nonatomic) UILabel *countDownTimeLabel, *publishedCommentsLabel, *answerSituationLabel;
@property (nonatomic) UIButton *endButton, *revokeButton;
@property (nonatomic) UICollectionView *answerOptionsCollectionView;


#pragma mark - 结束界面
@property (nonatomic) UIView *endContainerView, *bottomEndContainerView, *detailContainerView;
@property (nonatomic) UILabel *answerUseTimeLabel, *publishNumberLabel, *endCommentsLabel;
@property (nonatomic) UIButton *detailButton, *reeditButton, *backButton;

@property (nonatomic) UIView *chartContainView, *statisticsLine, *chartView;
@property (nonatomic) UILabel *participatedNumberLabel, *correctRateLabel, *correctAnswerLabel;

// 答题详情页码
@property (nonatomic) UITableView *detailTableView;
@property (nonatomic) NSMutableArray<BJLUser *> *onlineUserList;

@end

NS_ASSUME_NONNULL_END
