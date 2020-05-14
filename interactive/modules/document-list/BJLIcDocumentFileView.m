//
//  BJLIcDocumentFileVIew.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/26.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcDocumentFileView.h"
#import "BJLIcDocumentFileCell.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileView ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *topSingleLine, *bottomSingleLine;
@property (nonatomic, readwrite) UIButton *closeButton;
@property (nonatomic, readwrite) UIButton *addAnimatedDocumentFileButton;
@property (nonatomic, readwrite) UIButton *addNormalDocumentFileButton;

// 如果存在文档, 显示 collection view
@property (nonatomic, readwrite) UICollectionView *collectionView;
@property (nonatomic, readwrite) UIButton *editDocumentFileButton;
@property (nonatomic, readwrite) UIButton *deleteDocumentFileButton;
@property (nonatomic, readwrite) UIButton *cancelEditStateButton;

// 如果不存在文档, 显示 empty view, 所有内容都加到这个视图上
@property (nonatomic, readwrite) UIScrollView *emptyView;
@property (nonatomic, readwrite) UIButton *addAnimatedDocumentFileEmptyButton;
@property (nonatomic, readwrite) UIButton *addNormalDocumentFileEmptyButton;

@end

@implementation BJLIcDocumentFileView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    // shadow
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    self.layer.shadowRadius = 10.0;
    // 毛玻璃效果
    UIView *backgroundView = ({
        UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIView *view = [[UIVisualEffectView alloc] initWithEffect:effect];
        // border && corner
        view.layer.cornerRadius = 8.0;
        view.layer.masksToBounds = YES;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        view;
    });
    [self addSubview:backgroundView];
    [backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    // title
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"课件管理";
        label.textColor = [UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self).offset(16.0);
        make.top.equalTo(self);
        make.height.equalTo(@32.0);
    }];
    // close button
    self.closeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_popover_close"] forState:UIControlStateNormal];
        button;
    });
    [self addSubview:self.closeButton];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self).offset(-12.0);
        make.top.bottom.equalTo(self.titleLabel);
        make.width.equalTo(self.closeButton.bjl_height);
    }];
    // top shadow line
    self.topSingleLine = [self createShadowSingleLine];
    [self addSubview:self.topSingleLine];
    // 因为设置了不裁切, 所以左右在设置约束的时候减少 1.0, 使得显示时不会到达边界
    [self.topSingleLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self).offset(1.0);
        make.right.equalTo(self).offset(-1.0);
        make.top.equalTo(self.titleLabel.bjl_bottom);
        make.height.equalTo(@(1.0));
    }];
    // bottom single line
    self.bottomSingleLine = [self createShadowSingleLine];
    [self addSubview:self.bottomSingleLine];
    [self.bottomSingleLine bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self).offset(1.0);
        make.right.equalTo(self).offset(-1.0);
        make.bottom.equalTo(self).offset(-48.0);
        make.height.equalTo(@1.0);
    }];
    // add document files
    self.addNormalDocumentFileButton = [self createLargeBlueButton];
    [self.addNormalDocumentFileButton setTitle:@"添加普通课件" forState:UIControlStateNormal];
    [self addSubview:self.addNormalDocumentFileButton];
    [self.addNormalDocumentFileButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self).offset(-16.0);
        make.top.equalTo(self.bottomSingleLine.bjl_bottom).offset(8.0);
        make.bottom.equalTo(self).offset(-8.0);
        make.width.equalTo(@144.0);
    }];
    self.addAnimatedDocumentFileButton = [self createLargeBlueButton];
    [self.addAnimatedDocumentFileButton setTitle:@"添加动效课件" forState:UIControlStateNormal];
    [self addSubview:self.addAnimatedDocumentFileButton];
    [self.addAnimatedDocumentFileButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.addNormalDocumentFileButton.bjl_left).offset(-11.0);
        make.width.top.bottom.equalTo(self.addNormalDocumentFileButton);
    }];
    [self makeDocumentsCollectionView];
    [self makeEmptyView];
    [self makeEditView];
}

#pragma mark - actions

- (void)updateEditViewHidden:(BOOL)hidden {
    if (hidden) {
        // hidden
        self.deleteDocumentFileButton.hidden = YES;
        self.cancelEditStateButton.hidden = YES;
        // show
        self.editDocumentFileButton.hidden = NO;
        self.addNormalDocumentFileButton.hidden = NO;
        self.addAnimatedDocumentFileButton.hidden = NO;
    }
    else {
        // hide
        self.editDocumentFileButton.hidden = YES;
        self.addNormalDocumentFileButton.hidden = YES;
        self.addAnimatedDocumentFileButton.hidden = YES;
        // show
        self.deleteDocumentFileButton.hidden = NO;
        self.cancelEditStateButton.hidden = NO;
    }
}

- (void)updateDocumentFileViewHidden:(BOOL)hidden {
    // 如果不存在文档
    if (hidden) {
        // 隐藏文档视图
        self.collectionView.hidden = YES;
        // 隐藏编辑视图
        [self updateEditViewHidden:YES];
        // 隐藏编辑按钮
        self.editDocumentFileButton.hidden = YES;
        // 显示 empty view
        self.emptyView.hidden = NO;
    }
    // 如果存在文档
    else {
        // 隐藏 empty 视图
        self.emptyView.hidden = YES;
        // 显示文档视图
        self.collectionView.hidden = NO;
        // 隐藏编辑视图
        [self updateEditViewHidden:YES];
    }
}

#pragma mark - wheel

- (UIView *)createShadowSingleLine {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    // shadow
    view.layer.masksToBounds = NO;
    view.layer.shadowOpacity = 0.2;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    view.layer.shadowRadius = 10.0;
    return view;
}

- (UIButton *)createLargeBlueButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 4.0;
    button.layer.masksToBounds = YES;
    button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return button;
}

- (void)makeEditView {
    // delete button
    self.deleteDocumentFileButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:@"删除" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithWhite:0.0 alpha:0.5] forState:UIControlStateDisabled];
        button;
    });
    [self addSubview:self.deleteDocumentFileButton];
    [self.deleteDocumentFileButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.editDocumentFileButton);
    }];
    // cancel edit button
    self.cancelEditStateButton = [self createLargeBlueButton];
    [self.cancelEditStateButton setTitle:@"取消多选" forState:UIControlStateNormal];
    [self addSubview:self.cancelEditStateButton];
    [self.cancelEditStateButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.addNormalDocumentFileButton);
    }];
}

// 存在文档时显示的视图
- (void)makeDocumentsCollectionView {
    // edit button
    self.editDocumentFileButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.backgroundColor = [UIColor whiteColor];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateNormal];
        [button setTitle:@"多选" forState:UIControlStateNormal];
        button;
    });
    [self addSubview:self.editDocumentFileButton];
    [self.editDocumentFileButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.equalTo(self.addNormalDocumentFileButton);
        make.left.equalTo(self).offset(15.0);
        make.width.equalTo(@64.0);
    }];
    // collection view
    self.collectionView = ({
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        // 垂直滑动
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        // 行间距
        layout.minimumInteritemSpacing = 4.0;
        // 列间距
        layout.minimumLineSpacing = 12.0;
        layout.itemSize = CGSizeMake([BJLIcAppearance sharedAppearance].documentFileCellWidth, [BJLIcAppearance sharedAppearance].documentFileCellHeight);
        layout.sectionInset = UIEdgeInsetsMake(0, 16.0, 0.0, 16.0);
        layout.headerReferenceSize = CGSizeMake(self.bounds.size.width, 40.0);
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        [collectionView registerClass:[BJLIcDocumentFileCell class] forCellWithReuseIdentifier:kIcDocumentFileCellReuseIdentifier];
        [collectionView registerClass:[BJLIcDocumentFileCellHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kIcDocumentFileCellHeaderReuseIdentifier];
        collectionView;
    });
    [self addSubview:self.collectionView];
    [self.collectionView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.width.equalTo(self);
        make.top.equalTo(self.topSingleLine.bjl_bottom);
        make.bottom.equalTo(self.bottomSingleLine.bjl_top);
    }];
}

// 不存在文档时显示的视图
- (void)makeEmptyView {
    // empty view
    self.emptyView = ({
        UIScrollView *scrollView = [UIScrollView new];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView;
    });
    [self addSubview:self.emptyView];
    [self.emptyView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self.topSingleLine.bjl_bottom);
        make.bottom.equalTo(self.bottomSingleLine.bjl_top);
    }];
    // containerView
    UIView *containerView = [UIView new];
    [self.emptyView addSubview:containerView];
    [containerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.equalTo(self.emptyView);
        make.left.right.equalTo(@[self, self.emptyView]);
    }];
    // empty image
    UIImageView *emptyImageView = [UIImageView new];
    emptyImageView.image = [UIImage bjlic_imageNamed:@"bjl_document_empty"];
    [containerView addSubview:emptyImageView];
    [emptyImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(containerView);
        make.height.greaterThanOrEqualTo(@50.0);
        make.height.equalTo(@94.0).priorityHigh();
        make.width.equalTo(emptyImageView.bjl_height).multipliedBy(emptyImageView.image.size.width / emptyImageView.image.size.height);
        make.top.greaterThanOrEqualTo(containerView);
        make.top.equalTo(containerView).offset(76.0).priorityHigh();
    }];
    // empty label
    UILabel *emptyLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"课件资源, 空空如也哦～";
        label.textColor = [UIColor bjl_colorWithHexString:@"#9D9D9E" alpha:1.0];
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [containerView addSubview:emptyLabel];
    [emptyLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(containerView);
        make.height.equalTo(@16.0);
        make.top.greaterThanOrEqualTo(emptyImageView.bjl_bottom);
        make.top.equalTo(emptyImageView.bjl_bottom).offset(22.0).priorityHigh();
    }];
    // tip label
    UILabel *tipLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentRight;
        label.text = @"请选择转换类型上传课件";
        label.textColor = [UIColor bjl_colorWithHexString:@"#EDEDEE" alpha:1.0];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [containerView addSubview:tipLabel];
    [tipLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(emptyImageView.bjl_left);
        make.height.equalTo(@16.0);
        make.top.greaterThanOrEqualTo(emptyLabel.bjl_bottom);
        make.top.equalTo(emptyLabel.bjl_bottom).offset(60.0).priorityHigh();
    }];
    // normal file image
    UIImageView *normalFileImageView = [UIImageView new];
    normalFileImageView.image = [UIImage bjlic_imageNamed:@"bjl_document_normalfile"];
    [containerView addSubview:normalFileImageView];
    [normalFileImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(containerView.bjl_centerX).offset(24.0);
        make.height.greaterThanOrEqualTo(@38.0);
        make.height.equalTo(@72.0).priorityHigh();
        make.width.equalTo(normalFileImageView.bjl_height).multipliedBy(normalFileImageView.image.size.width / normalFileImageView.image.size.height);
        make.top.greaterThanOrEqualTo(tipLabel.bjl_bottom);
        make.top.equalTo(tipLabel.bjl_bottom).offset(27.0).priorityHigh();
    }];
    // normal file label
    UILabel *normalFileLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"添加普通课件";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [containerView addSubview:normalFileLabel];
    [normalFileLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(normalFileImageView.bjl_centerY).offset(-3.0);
        make.left.equalTo(normalFileImageView.bjl_right);
        make.height.equalTo(@16.0);
    }];
    // normal file detail label
    UILabel *normalFileDetailLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"转码时间短";
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [containerView addSubview:normalFileDetailLabel];
    [normalFileDetailLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(normalFileImageView.bjl_centerY).offset(3.0);
        make.left.height.equalTo(normalFileLabel);
    }];
    self.addNormalDocumentFileEmptyButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        button;
    });
    [containerView addSubview:self.addNormalDocumentFileEmptyButton];
    [self.addNormalDocumentFileEmptyButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.top.bottom.equalTo(normalFileImageView);
        make.right.equalTo(normalFileLabel);
    }];
    // animate file label
    UILabel *animatedFileLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentRight;
        label.text = @"添加动效课件";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [containerView addSubview:animatedFileLabel];
    [animatedFileLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(normalFileImageView.bjl_centerY).offset(-3.0);
        make.right.equalTo(containerView.bjl_centerX).offset(-24.0);
        make.height.equalTo(@16.0);
    }];
    // animate file detail label
    UILabel *animatedFileDetailLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"转码时间长";
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [containerView addSubview:animatedFileDetailLabel];
    [animatedFileDetailLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(normalFileImageView.bjl_centerY).offset(3.0);
        make.left.height.equalTo(animatedFileLabel);
    }];
    // animate file image
    UIImageView *animatedFileImageView = [UIImageView new];
    animatedFileImageView.image = [UIImage bjlic_imageNamed:@"bjl_document_animatedfile"];
    [containerView addSubview:animatedFileImageView];
    [animatedFileImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.width.equalTo(normalFileImageView);
        make.right.equalTo(animatedFileLabel.bjl_left);
    }];
    self.addAnimatedDocumentFileEmptyButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        button;
    });
    [containerView addSubview:self.addAnimatedDocumentFileEmptyButton];
    [self.addAnimatedDocumentFileEmptyButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.top.bottom.equalTo(animatedFileImageView);
        make.right.equalTo(animatedFileLabel);
    }];
    // notice label
    UILabel *noticeLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.lineBreakMode =  NSLineBreakByTruncatingTail;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        label.font = [UIFont systemFontOfSize:14.0];
        label.text = @"1. 动效PPT支持ppt、pptx格式的内容，上传后还原源文件中的动效\n"
                     "2. 普通课件支持ppt、pptx、doc、docx、jpg、pdf格式的内容\n"
                     "3. WPS编辑的文档请转换成PDF后上传\n";
        label;
    });
    [containerView addSubview:noticeLabel];
    [noticeLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(tipLabel);
        make.width.equalTo(containerView).multipliedBy(0.95);
        make.top.greaterThanOrEqualTo(animatedFileImageView.bjl_bottom);
        make.top.equalTo(animatedFileImageView.bjl_bottom).offset(27.0).priorityHigh();
        make.bottom.lessThanOrEqualTo(containerView);
        make.bottom.equalTo(containerView).offset(-41.0).priorityHigh();
    }];
}

@end

NS_ASSUME_NONNULL_END
