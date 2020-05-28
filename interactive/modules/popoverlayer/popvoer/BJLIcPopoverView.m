//
//  BJLIcPopoverView.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/20.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcPopoverView.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcPopoverView ()

@property (nonatomic) BJLIcPopoverViewType type;
@property (nonatomic, readwrite) CGSize viewSize;
@property (nonatomic, nullable) UIView *backgroundView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic, readwrite) UILabel *messageLabel;
@property (nonatomic, readwrite) UIButton *cancelButton;
@property (nonatomic, readwrite) UIButton *confirmButton;
@property (nonatomic, readwrite, nullable) UIButton *appendButton;

@end

@implementation BJLIcPopoverView

- (instancetype)init {
    return [self initWithType:BJLIcPopoverViewDefaultType];
}

- (instancetype)initWithType:(BJLIcPopoverViewType)type {
    if (self = [super init]) {
        self.type = type;
        self.viewSize = CGSizeMake([BJLIcAppearance sharedAppearance].popoverViewWidth, [BJLIcAppearance sharedAppearance].popoverViewHeight);
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    [self makeCommonView];

    switch (self.type) {
        case BJLIcExitViewNormal:
            [self makeNormalExitView];
            break;
            
        case BJLIcExitViewKickOut:
            [self makeKickOutExitView];
            break;
            
        case BJLIcExitViewTimeOut:
            [self makeTimeOutExitView];
            break;
            
        case BJLIcExitViewConnectFail:
            [self makeConnectFailExitView];
            break;
            
        case BJLIcExitViewAppend:
            [self makeAppendExitView];
            break;
            
        case BJLIcKickOutUser:
            [self makeKickOutUserView];
            break;
            
        case BJLIcSwitchStage:
            [self makeSwitchStageView];
            break;
            
        case BJLIcFreeBlockedUser:
            [self makeFreeAllBlockedUserView];
            break;
            
        case BJLIcStartCloudRecord:
            [self makeStartCloudRecordView];
            break;
            
        case BJLIcDisBandGroup:
            [self makeDisBandGroupView];
            break;
            
        case BJLIcRevokeWritingBoard:
            [self makeRevokeWritingBoardView];
            break;
            
        case BJLIcClearWritingBoard:
            [self makeClearWritingBoardView];
            break;

        case BJLIcCloseWritingBoard:
            [self makeCloseWritingBoardView];
            break;

        case BJLIcCloseWebPage:
            [self makeCloseWebPageView];
            break;
            
        case BJLIcCloseQuiz:
            [self makeCloseQuizView];
            break;
            
        case BJLIcHighLoassRate:
            [self makeHighLoassRateView];
            break;
            
        default:
            break;
    }
}

#pragma mark - exit

- (void)makeNormalExitView {
    [self makeSingleMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(96.0, 40.0) space:32.0 positive:NO];
    self.titleLabel.text = @"关闭教室";
    self.imageView.image = [UIImage bjlic_imageNamed:@"bjl_popover_exit"];
    self.messageLabel.text = @"正在关闭教室, 是否结束授课?";
    
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
    [self.confirmButton setTitle:@"关闭教室" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeKickOutExitView {
    [self makeSingleMessageView];
    [self makePassiveExitButtonViewWithButtonSize:CGSizeMake(160.0, 40.0)];
    self.titleLabel.text = @"关闭教室";
    self.imageView.image = [UIImage bjlic_imageNamed:@"bjl_popover_kickout"];
    self.messageLabel.text = @"您已被移出教室";
}

- (void)makeTimeOutExitView {
    [self makeSingleMessageView];
    [self makePassiveExitButtonViewWithButtonSize:CGSizeMake(160.0, 40.0)];
    self.titleLabel.text = @"关闭教室";
    self.imageView.image = [UIImage bjlic_imageNamed:@"bjl_popover_timeout"];
    self.messageLabel.text = @"严重超时! 教室已自动关闭";
}

- (void)makeConnectFailExitView {
    [self makeSingleMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(160.0, 40.0) space:16.0 positive:NO];
    self.titleLabel.text = @"重新登录";
    self.imageView.image = [UIImage bjlic_imageNamed:@"bjl_popover_timeout"];
    self.messageLabel.text = @"连接超时! 请尝试重新登录";
    
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"退出教室" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.confirmButton setTitle:@"继续连接" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeAppendExitView {
    [self makeSingleMessageView];
    [self makeAppendButtonView];
    self.viewSize = CGSizeMake(422.0, 287.0);
    self.titleLabel.text = @"关闭教室";
    self.imageView.image = [UIImage bjlic_imageNamed:@"bjl_popover_exit"];
    self.messageLabel.text = @"正在关闭教室, 是否结束授课?";
    
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
    [self.confirmButton setTitle:@"关闭教室" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.appendButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.appendButton setTitle:@"下课并查看表情报告" forState:UIControlStateNormal];
    [self.appendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

#pragma mark - actions

- (void)makeKickOutUserView {
    [self makeDoubleMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(96.0, 40.0) space:32.0 positive:NO];
    self.titleLabel.text = @"移出教室";
    self.imageView.image = [UIImage bjlic_imageNamed:@"bjl_popover_kickout"];
    self.messageLabel.text = @"是否将用户移出教室? \n 移出后将无法再次进入教室";
    
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0];
    [self.confirmButton setTitle:@"移出教室" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeSwitchStageView {
    [self makeNoImageMessageView:20.0];
    [self makeDoubleVerticalButtonViewWithButtonSize:CGSizeMake(250.0, 40.0) space:12.0 topInCenterOffset:0.0];
    // 不使用毛玻璃效果
    [self.backgroundView removeFromSuperview];
    self.backgroundView = nil;
    self.backgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#40424A" alpha:0.8];
        view;
    });
    [self addSubview:self.backgroundView];
    [self sendSubviewToBack:self.backgroundView];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    
    self.titleLabel.text = @"切换上下台";
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4.0;
    paragraphStyle.paragraphSpacing = 4.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:@"坐席已满\n请设置下台后继续操作"
                                                                         attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18.0],
                                                                                      NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                                      NSParagraphStyleAttributeName : paragraphStyle}];
    self.messageLabel.attributedText = attributedText;
    
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.confirmButton setTitle:@"去设置下台" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"取消操作" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0] forState:UIControlStateNormal];
}

- (void)makeFreeAllBlockedUserView {
    [self makeNoImageMessageView:30.0];
    [self makeDoubleVerticalButtonViewWithButtonSize:CGSizeMake(250.0, 40.0) space:12.0 topInCenterOffset:-20.0];
    // 不使用毛玻璃效果
    [self.backgroundView removeFromSuperview];
    self.backgroundView = nil;
    self.backgroundView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#40424A" alpha:0.8];
        view;
    });
    [self addSubview:self.backgroundView];
    [self sendSubviewToBack:self.backgroundView];
    [self.backgroundView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    
    self.titleLabel.text = @"解除黑名单";
    self.viewSize = CGSizeMake(300, 196);
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4.0;
    paragraphStyle.paragraphSpacing = 4.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:@"是否将黑名单全部成员解禁？"
                                                                         attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16.0],
                                                                                      NSForegroundColorAttributeName : [UIColor whiteColor],
                                                                                      NSParagraphStyleAttributeName : paragraphStyle}];
    self.messageLabel.attributedText = attributedText;
    
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.confirmButton setTitle:@"再想想" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"全部解禁" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor bjl_colorWithHexString:@"#9B9B9B" alpha:1.0] forState:UIControlStateNormal];
}

- (void)makeStartCloudRecordView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(160.0, 32.0) space:22.0 positive:NO];
    self.titleLabel.text = @"云端录制";
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 14.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                    NSParagraphStyleAttributeName : paragraphStyle};
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:@"重新开启云端录制 \n 继续前一次云端录制还是开启新的云端录制?" attributes:attributedDic];
    
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"新的录制" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.confirmButton setTitle:@"继续录制" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeDisBandGroupView {
    [self makeSingleMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(96.0, 40.0) space:32.0 positive:NO];
    self.titleLabel.text = @"全部解散";
    self.imageView.image = [UIImage bjlic_imageNamed:@"bjl_popover_warn"];
    self.messageLabel.text = @"是否解散全部分组";
    
    self.cancelButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#ECF0F2" alpha:1.0];
    [self.confirmButton setTitle:@"全部解散" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

- (void)makeRevokeWritingBoardView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(160.0, 32.0) space:22.0 positive:NO];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 14.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                    NSParagraphStyleAttributeName : paragraphStyle};
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:@"撤销小黑板将不保留学生数据\n是否继续撤销" attributes:attributedDic];
    
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeClearWritingBoardView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(160.0, 32.0) space:22.0 positive:NO];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 14.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                    NSParagraphStyleAttributeName : paragraphStyle};
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:@"清空小黑板无法恢复\n是否继续清空" attributes:attributedDic];
    
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeCloseWritingBoardView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(160.0, 32.0) space:22.0 positive:NO];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 14.0;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName : [UIColor whiteColor],
                                    NSParagraphStyleAttributeName : paragraphStyle};
    self.messageLabel.attributedText = [[NSAttributedString alloc] initWithString:@"关闭窗口将收回学生页面, 是否继续?" attributes:attributedDic];
    
    self.cancelButton.backgroundColor = [UIColor whiteColor];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.confirmButton setTitle:@"确定" forState:UIControlStateNormal];
}

- (void)makeCloseWebPageView {
    [self makePureMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(120.0, 32.0) space:24.0 positive:NO];
    self.titleLabel.text = @"关闭网页";
    self.messageLabel.text = @"学生端将同步关闭窗口 是否继续？";
    
    self.cancelButton.backgroundColor = [UIColor clearColor];
    self.cancelButton.layer.borderColor = [UIColor bjl_colorWithHexString:@"#979797" alpha:0.5].CGColor;
    self.cancelButton.layer.borderWidth = 1.0;
    [self.cancelButton setTitle:@"关闭" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.confirmButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)makeCloseQuizView {
    [self makeSingleMessageView];
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(96.0, 40.0) space:32.0 positive:NO];
    self.titleLabel.text = @"关闭测验";
    self.imageView.image = [UIImage bjlic_imageNamed:@"bjl_popover_warn"];
    self.messageLabel.text = @"确认关闭测验？";
    
    self.cancelButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.cancelButton setTitle:@"关闭" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#ECF0F2" alpha:1.0];
    [self.confirmButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

- (void)makeHighLoassRateView {
    [self makePureMessageView];
    [self makePassiveExitButtonViewWithButtonSize:CGSizeMake(160.0, 40.0)];
    self.messageLabel.text = @"哎呀，您的网络开小差了，检测网络后重新进入教室";
    self.confirmButton.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    [self.confirmButton setTitle:@"好的" forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

#pragma mark - wheel

- (void)makeCommonView {
    // shadow
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    self.layer.shadowRadius = 10.0;
    // 毛玻璃效果
    self.backgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        // border && corner
        view.layer.cornerRadius = 4.0;
        view.layer.masksToBounds = YES;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        view;
    });
    [self addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    // title 
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self).offset(12.0);
        make.top.equalTo(self);
        // version 1
//        make.height.equalTo(@24.0);
        // version 2
        make.height.equalTo(@0.0);
    }];
    
    // shadow line
    UIView *singleLine = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        // shadow
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.2;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
        view.layer.shadowRadius = 10.0;
        view;
    });
    [self addSubview:singleLine];
    // 因为设置了不裁切, 所以左右在设置约束的时候减少 1.0, 使得显示时不会到达边界
    [singleLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self).offset(1.0);
        make.right.equalTo(self).offset(-1.0);
        make.top.equalTo(self.titleLabel.bjl_bottom);
        // version 1
//        make.height.equalTo(@(1.0));
        // version 2
        make.height.equalTo(@0.0);
    }];
}

// 提示message为一行
- (void)makeSingleMessageView {
    // image
    self.imageView = [UIImageView new];
    [self addSubview:self.imageView];
    [self.imageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.titleLabel.bjl_bottom).offset(42.0);
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].popoverImageSize));
    }];
    
    // message
    self.messageLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self addSubview:self.messageLabel];
    [self.messageLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.imageView.bjl_bottom).offset([BJLIcAppearance sharedAppearance].popoverViewSpace);
        make.height.equalTo(@14.0);
    }];
}

// 提示message为两行
- (void)makeDoubleMessageView {
    // image
    self.imageView = [UIImageView new];
    [self addSubview:self.imageView];
    [self.imageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.titleLabel.bjl_bottom).offset([BJLIcAppearance sharedAppearance].popoverViewSpace);
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].popoverImageSize));
    }];
    
    // message
    self.messageLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 2;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self addSubview:self.messageLabel];
    [self.messageLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.imageView.bjl_bottom).offset([BJLIcAppearance sharedAppearance].popoverViewSpace);
        make.height.equalTo(@40.0);
    }];
}

- (void)makeNoImageMessageView:(CGFloat)topOffset {
    self.messageLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.adjustsFontSizeToFitWidth = YES;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:18.0];
        label;
    });
    [self addSubview:self.messageLabel];
    [self.messageLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self).offset(topOffset);
        make.left.right.equalTo(self);
        make.bottom.lessThanOrEqualTo(self.bjl_centerY);
    }];
}

- (void)makePureMessageView {
    self.messageLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self addSubview:self.messageLabel];
    [self.messageLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.bjl_centerY);
    }];
}

- (void)makeDoubleHorizontalButtonViewWithButtonSize:(CGSize)size space:(CGFloat)space positive:(BOOL)positive {
    UIButton *leftButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button;
    });
    [self addSubview:leftButton];
    [leftButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.greaterThanOrEqualTo(self);
        make.right.equalTo(self.bjl_centerX).offset(-space/2);
        make.top.equalTo(self.messageLabel.bjl_bottom).offset([BJLIcAppearance sharedAppearance].popoverViewSpace);
        make.height.equalTo(@(size.height));
        make.width.equalTo(@(size.width));
    }];
    
    UIButton *rightButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button;
    });
    [self addSubview:rightButton];
    [rightButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.lessThanOrEqualTo(self);
        make.left.equalTo(self.bjl_centerX).offset(space/2);
        make.top.equalTo(leftButton);
        make.height.equalTo(@(size.height));
        make.width.equalTo(@(size.width));
    }];
    if (positive) {
        self.confirmButton = leftButton;
        self.cancelButton = rightButton;
    }
    else {
        self.cancelButton = leftButton;
        self.confirmButton = rightButton;
    }
}

- (void)makeDoubleVerticalButtonViewWithButtonSize:(CGSize)size space:(CGFloat)space topInCenterOffset:(CGFloat)topInCenterOffset {
    // confirm
    self.confirmButton = ({
        UIButton *button = [UIButton new];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 4.0;
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button;
    });
    [self addSubview:self.confirmButton];
    [self.confirmButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.greaterThanOrEqualTo(self);
        make.right.lessThanOrEqualTo(self);
        make.top.equalTo(self.bjl_centerY).offset(topInCenterOffset);
        make.centerX.equalTo(self);
        make.height.equalTo(@(size.height));
        make.width.equalTo(@(size.width));
    }];
    
    // cancel
    self.cancelButton = ({
        UIButton *button = [UIButton new];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 4.0;
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button;
    });
    [self addSubview:self.cancelButton];
    [self.cancelButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.greaterThanOrEqualTo(self);
        make.right.lessThanOrEqualTo(self);
        make.top.equalTo(self.confirmButton.bjl_bottom).offset(space);
        make.centerX.equalTo(self);
        make.height.equalTo(@(size.height));
        make.width.equalTo(@(size.width));
    }];
}

- (void)makeAppendButtonView {
    [self makeDoubleHorizontalButtonViewWithButtonSize:CGSizeMake(96.0, 40.0) space:32.0 positive:NO];
    
    // append
    self.appendButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button;
    });
    [self addSubview:self.appendButton];
    [self.appendButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.cancelButton.bjl_bottom).offset(24.0);
        make.centerX.equalTo(self);
        make.left.height.equalTo(self.cancelButton);
        make.right.equalTo(self.confirmButton.bjl_right);
    }];
}

- (void)makePassiveExitButtonViewWithButtonSize:(CGSize)size {
    // confirm
    self.confirmButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        button.layer.cornerRadius = 8.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"关闭" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button;
    });
    [self addSubview:self.confirmButton];
    [self.confirmButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.messageLabel.bjl_bottom).offset([BJLIcAppearance sharedAppearance].popoverViewSpace);
        make.height.equalTo(@(size.height));
        make.width.equalTo(@(size.width));
    }];
}

@end

NS_ASSUME_NONNULL_END
