//
//  BJLIcWritingBoardTopToolBarViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcWritingBoardTopToolBarViewController.h"

@interface BJLIcWritingBoardTopToolBarViewController ()

@property (nonatomic, weak) BJLRoom *room;

@property (nonatomic) BJLIcWriteBoardStatus barStyle;

@property (nonatomic) UIView *containView;
@property (nonatomic, readwrite) UILabel *studentNameLabel;
@property (nonatomic, readwrite) UIButton *screenShotButton;
@property (nonatomic, readwrite) UIButton *shareBoardButton;
@property (nonatomic, readwrite) UILabel *groupColorLabel, *groupNameLabel;

@end

@implementation BJLIcWritingBoardTopToolBarViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if(self) {
        self.room = room;
        self.barStyle = BJLIcWriteBoardStatus_None;
    }
    return self;
}

- (void)loadView {
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        if ([hitView isKindOfClass:[UIButton class]]) {
            return hitView;
        }
        return nil;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    
    [self makeSubviews];

}

- (void)updateViewConstraintsWithStatus:(BJLIcWriteBoardStatus)status {
    [self.containView removeFromSuperview];
    for (UIView *subView in self.containView.subviews) {
        [subView removeFromSuperview];
    }

    self.barStyle = status;
    if(status == BJLIcWriteBoardStatus_teacherPublished || status == BJLIcWriteBoardStatus_teacherGathered) {
        [self makeConstraints];
    }
}

#pragma mark - private
- (void)makeSubviews {
    self.containView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, containView);
        bjl_return view;
    });
    
    self.studentNameLabel = ({
        UILabel *label = [UILabel new];
        label.accessibilityLabel = BJLKeypath(self, studentNameLabel);
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = [UIColor whiteColor];
        label.text = @"当前查看: ";
        bjl_return label;
    });
    
    self.groupColorLabel = ({
        UILabel *label = [UILabel new];
        label.layer.cornerRadius = 6.0;
        label.layer.masksToBounds = YES;
        label.accessibilityLabel = BJLKeypath(self, groupColorLabel);
        bjl_return label;
    });
    self.groupNameLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"--";
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor bjl_colorWithHex:0X9B9B9B];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, groupNameLabel);
        bjl_return label;
    });

    self.screenShotButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_ic_boardScreenshot_normal"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_ic_boardScreenshot_selected"]];
    [self.screenShotButton addTarget:self action:@selector(screenShot) forControlEvents:UIControlEventTouchUpInside];

    self.shareBoardButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_ic_boardShare_normal"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_ic_boardShare_selected"]];
    [self.shareBoardButton addTarget:self action:@selector(shareBoard) forControlEvents:UIControlEventTouchUpInside];
}

- (void)makeConstraints {
    [self.view addSubview:self.containView];
    [self.containView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.containView addSubview:self.studentNameLabel];
    [self.containView addSubview:self.groupColorLabel];
    [self.containView addSubview:self.groupNameLabel];
    [self.studentNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.compressionResistance.defaultLow();
        make.centerY.equalTo(self.containView);
        make.centerX.equalTo(self.containView).offset(-16);
        make.left.greaterThanOrEqualTo(self.containView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
        make.right.equalTo(self.groupColorLabel.bjl_left).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
    }];
    
    [self.groupColorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.width.height.equalTo(@(12.0));
    }];
    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.left.equalTo(self.groupColorLabel.bjl_right).offset(5);
    }];

    if(self.barStyle == BJLIcWriteBoardStatus_teacherPublished) {
        [self.containView addSubview:self.screenShotButton];
        [self.screenShotButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.containView);
            make.right.equalTo(self.containView).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
            make.left.greaterThanOrEqualTo(self.groupNameLabel.bjl_right).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
        }];

    }
    else if(self.barStyle == BJLIcWriteBoardStatus_teacherGathered) {
        [self.containView addSubview:self.shareBoardButton];
        [self.containView addSubview:self.screenShotButton];
        [self.screenShotButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.containView);
            make.right.equalTo(self.containView).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
        }];

        [self.shareBoardButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(self.screenShotButton);
            make.right.equalTo(self.screenShotButton.bjl_left).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
            make.left.greaterThanOrEqualTo(self.studentNameLabel.bjl_right).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
        }];
    }
}

#pragma mark - action

- (void)shareBoard {
    if(self.shareBoardCallback) {
        self.shareBoardCallback();
    }
}

- (void)screenShot {
    if(self.screenShotCallback) {
        self.screenShotCallback();
    }
}

- (UIButton *)makeImageButton:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage {
    UIButton *button = [BJLImageButton new];
    button.layer.masksToBounds = YES;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    [button setImage:selectedImage forState:UIControlStateHighlighted];
    [button setImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    
    return button;
}


@end
