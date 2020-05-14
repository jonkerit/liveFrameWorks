//
//  BJLIcDocumentFileDisplayListView+multipleDisplay.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/30.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileDisplayListView+multipleDisplay.h"
#import "BJLIcDocumentFileDisplayListView+private.h"

@implementation BJLIcDocumentFileDisplayListView (multipleDisplay)

- (void)makeMultipleDisplaySubviewsAndConstraints {
    self.collectionView = ({
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 2.0;
        layout.itemSize = CGSizeMake([BJLIcAppearance sharedAppearance].documentFileCellWidth, [BJLIcAppearance sharedAppearance].documentFileCellHeight);
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.accessibilityLabel = BJLKeypath(self, collectionView);
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.backgroundColor = [UIColor clearColor];
        [collectionView registerClass:[BJLIcDocumentFileCell class] forCellWithReuseIdentifier:kFileCellReuseIdentifier];
        [collectionView registerClass:[BJLIcDocumentPreviewCell class] forCellWithReuseIdentifier:kWebFileCellReuseIdentifier];
        collectionView;
    });
    [self.containerView addSubview:self.collectionView];
    [self.collectionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.bottom.equalTo(self.containerView).inset(12.0);
        make.left.equalTo(self.containerView).offset(12.0);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].documentFileCellWidth));
    }];
    
    self.hideFileListButton = ({
        UIButton *button = [UIButton new];
        button.accessibilityLabel = BJLKeypath(self, hideFileListButton);
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_document_collapse"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(updateCollectionViewHidden) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.containerView addSubview:self.hideFileListButton];
    [self.hideFileListButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(@24.0);
        make.height.equalTo(@64.0);
        make.right.centerY.equalTo(self.containerView);
    }];
    
    self.showFileListButton = ({
        UIButton *button = [BJLImageButton new];
        button.accessibilityLabel = BJLKeypath(self, showFileListButton);
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_document_expand"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(updateCollectionViewHidden) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self addSubview:self.showFileListButton];
    [self.showFileListButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.centerY.equalTo(self);
        make.width.equalTo(@24.0);
        make.height.equalTo(@64.0);
    }];
    
    // 隐藏
    [self hide];
}

@end
