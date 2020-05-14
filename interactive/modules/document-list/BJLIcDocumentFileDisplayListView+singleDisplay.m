//
//  BJLIcDocumentFileDisplayListView+singleDisplay.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/30.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileDisplayListView+singleDisplay.h"
#import "BJLIcDocumentFileDisplayListView+private.h"

@implementation BJLIcDocumentFileDisplayListView (singleDisplay)

- (void)makeSingleDisplaySubviewsAndConstraints {
    self.blackboardView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, blackboardView);
        view;
    });
    [self.containerView addSubview:self.blackboardView];
    [self.blackboardView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.top.equalTo(self.containerView);
        make.left.equalTo(self.containerView).offset(10.0);
        make.right.equalTo(self.containerView).offset(-10.0);
        make.height.equalTo(@115.0);
    }];
    self.blackboardImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.accessibilityLabel = BJLKeypath(self, blackboardImageView);
        imageView;
    });
    [self.blackboardView addSubview:self.blackboardImageView];
    [self.blackboardImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.blackboardView);
        make.height.equalTo(@70.0);
        make.top.equalTo(self.blackboardView.bjl_top).offset(10.0);
    }];
    self.blackboardTitleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, blackboardTitleLabel);
        label;
    });
    [self.blackboardView addSubview:self.blackboardTitleLabel];
    [self.blackboardTitleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.blackboardView);
        make.top.equalTo(self.blackboardImageView.bjl_bottom);
        make.height.equalTo(@20.0);
    }];
    UIView *blackboardLine = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        view.accessibilityLabel = @"blackboardLine";
        view;
    });
    [self.blackboardView addSubview:blackboardLine];
    [blackboardLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.blackboardTitleLabel).offset(2.0);
        make.height.equalTo(@1.0);
    }];
    self.backToAlbumDocumentButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjlic_imageNamed:@"bjl_popover_close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(backToAlbumDocument) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.containerView addSubview:self.backToAlbumDocumentButton];
    [self.backToAlbumDocumentButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(blackboardLine);
        make.right.equalTo(self.containerView);
        make.width.height.equalTo(@32.0);
    }];
    self.documentTitleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor whiteColor];
        label;
    });
    [self.containerView addSubview:self.documentTitleLabel];
    [self.documentTitleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.containerView).offset(10.0);
        make.centerY.equalTo(self.backToAlbumDocumentButton);
        make.height.equalTo(@20.0);
        make.right.equalTo(self.backToAlbumDocumentButton.bjl_left);
    }];
    self.uploadDocumentView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, uploadDocumentView);
        view;
    });
    [self.containerView addSubview:self.uploadDocumentView];
    [self.uploadDocumentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.containerView);
        make.height.equalTo(@58.0);
    }];
    UIView *uploadDocumentLine = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        view.accessibilityLabel = @"uploadDocumentLine";
        view;
    });
    [self.uploadDocumentView addSubview:uploadDocumentLine];
    [uploadDocumentLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.uploadDocumentView);
        make.height.equalTo(@1.0);
    }];
    self.uploadDocumentButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        button.accessibilityLabel = BJLKeypath(self, uploadDocumentButton);
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [button setTitle:@"添加课件" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showDocumentFileManagerViewController) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.uploadDocumentView addSubview:self.uploadDocumentButton];
    [self.uploadDocumentButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.uploadDocumentView);
        make.left.equalTo(self.containerView).offset(10.0);
        make.right.equalTo(self.containerView).offset(-10.0);
        make.height.equalTo(@36.0);
    }];
    self.collectionView = ({
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 2.0;
        layout.itemSize = CGSizeMake(140.0, 100.0);
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.accessibilityLabel = BJLKeypath(self, collectionView);
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.backgroundColor = [UIColor clearColor];
        [collectionView registerClass:[BJLIcDocumentPreviewCell class] forCellWithReuseIdentifier:kWebFileCellReuseIdentifier];
        [collectionView registerClass:[BJLIcDocumentPreviewCell class] forCellWithReuseIdentifier:kPreviewCellReuseIdentifier];
        [collectionView registerClass:[BJLIcDocumentDetailPreviewCell class] forCellWithReuseIdentifier:kDetailPreviewCellReuseIdentifier];
        collectionView;
    });
    [self.containerView addSubview:self.collectionView];
    [self.collectionView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.blackboardView.bjl_bottom).offset(0.0);
        make.bottom.equalTo(self.uploadDocumentView.bjl_top).offset(0.0);
        make.left.equalTo(self.containerView);
        make.right.equalTo(self.containerView);
    }];
    
    self.containerView.backgroundColor = [UIColor bjl_colorWithHexString:@"#222222" alpha:0.5];
    [self makeObservingForDocument];
    [self updateCollectionViewHidden];
    [self updateAlbumViewHidden:YES];
}

- (void)updateAlbumViewHidden:(BOOL)hidden {
    if (hidden) {
        self.documentTitleLabel.hidden = YES;
        self.backToAlbumDocumentButton.hidden = YES;
        self.uploadDocumentView.hidden = NO;
        self.documentTitleLabel.text = nil;
    }
    else {
        self.documentTitleLabel.hidden = NO;
        self.backToAlbumDocumentButton.hidden = NO;
        self.uploadDocumentView.hidden = YES;
        self.documentTitleLabel.text = self.albumDocument.fileName;
    }
}

- (void)updateSingleDisplayConstraints {
    if (self.isAlbumDetail) {
        [self updateAlbumViewHidden:NO];
        [self.collectionView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.blackboardView.bjl_bottom).offset(32.0);
            make.bottom.equalTo(self.uploadDocumentView.bjl_top).offset(58.0);
        }];
    }
    else {
        [self updateAlbumViewHidden:YES];
        [self.collectionView bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.blackboardView.bjl_bottom).offset(0.0);
            make.bottom.equalTo(self.uploadDocumentView.bjl_top).offset(0.0);
        }];
    }
}

- (void)makeObservingForDocument {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, allDocuments)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateBlackboardView];
             [self.collectionView reloadData];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.blackboardImageView, bounds)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.blackboardBorderLayer = [self.blackboardImageView bjlic_drawBorderWidth:1.0 borderColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] corners:UIRectCornerAllCorners cornerRadii:CGSizeZero];
             if (self.isAlbumDetail) {
                 self.blackboardBorderLayer.hidden = !(self.albumIndex < 0);
             }
             else {
                 self.blackboardBorderLayer.hidden = !(self.documentIndex < 0);
             }
             return YES;
         }];
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, currentSlidePage)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.room.documentVM.currentSlidePage) {
                 BJLDocument *document = [self.room.documentVM documentWithID:self.room.documentVM.currentSlidePage.documentID];
                 if (document) {
                     // 黑板特别判断，当前页面为黑板的时候不需要处理
                     if ([document.documentID isEqualToString:BJLBlackboardID]) {
                         if (self.documentIndex < 0 && self.albumIndex < 0) {
                             return YES;
                         }
                         self.documentIndex = -1;
                         self.albumIndex = -1;
                         [self.collectionView reloadData];
                         [self updateBlackboardBorderHidden];
                         return YES;
                     }
                     NSInteger documentIndex = [self.room.documentVM.allDocuments indexOfObject:document];
                     NSInteger albumIndex = self.room.documentVM.currentSlidePage.slidePageIndex;
                     BOOL change = NO;
                     if (self.documentIndex != documentIndex - 1) {
                         change = YES;
                         self.documentIndex = documentIndex - 1;
                         self.albumIndex = albumIndex;
                         self.albumDocument = document;
                     }
                     if (self.albumIndex != albumIndex) {
                         change = self.isAlbumDetail;
                         self.albumIndex = albumIndex;
                     }
                     if (change) {
                         [self.collectionView reloadData];
                         [self updateBlackboardBorderHidden];
                     }
                 }
             }
             return YES;
         }];
}

- (void)updateBlackboardView {
    if (!self.blackboardDocument) {
        self.blackboardDocument = [self.room.documentVM.allDocuments bjl_objectAtIndex:0];
        if (!self.blackboardDocument) {
            return;
        }
        NSURL *blackboardURL = [NSURL URLWithString:[self.blackboardDocument.pageInfo pageURLStringWithPageIndex:0]];
        [self.blackboardImageView bjl_setImageWithURL:blackboardURL];
        self.blackboardTitleLabel.text = self.blackboardDocument.fileName;
        bjl_weakify(self);
        UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
            bjl_strongify(self);
            [self didSelectDocument:self.blackboardDocument index:-1 isAlbum:NO];
        }];
        [self.blackboardView addGestureRecognizer:tapGesture];
    }
}

@end
