//
//  BJLIcDocumentFileDisplayListView+private.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/30.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/NSObject+BJLObserving.h>

#import "BJLIcDocumentFileDisplayListView.h"
#import "BJLIcAppearance.h"
#import "BJLIcDocumentFileCell.h"
#import "BJLIcDocumentPreviewCell.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kFileCellReuseIdentifier = @"kFileCellReuseIdentifier";
static NSString * const kWebFileCellReuseIdentifier = @"kWebFileCellReuseIdentifier";
static NSString * const kPreviewCellReuseIdentifier = @"kPreviewCellReuseIdentifier";
static NSString * const kDetailPreviewCellReuseIdentifier = @"kDetailPreviewCellReuseIdentifier";

@interface BJLIcDocumentFileDisplayListView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, readwrite) BJLIcDocumentFileDisplayLayoutType type;
@property (nonatomic) NSMutableArray<BJLIcDocumentFile *> *documentFileList;
@property (nonatomic) NSMutableArray<BJLIcDocumentFile *> *webDocumentFileList;
@property (nonatomic) BOOL singleDisplay;

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIButton *hideFileListButton;
@property (nonatomic) UIButton *showFileListButton;

#pragma mark - singleDocumentWindow

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) BJLDocument *blackboardDocument;
@property (nonatomic) BOOL isAlbumDetail;
@property (nonatomic) NSInteger documentIndex;
@property (nonatomic) NSInteger albumIndex;
@property (nonatomic, nullable) BJLDocument *albumDocument;

@property (nonatomic) UIView *blackboardView;
@property (nonatomic) UIImageView *blackboardImageView;
@property (nonatomic) CAShapeLayer *blackboardBorderLayer;
@property (nonatomic) UILabel *blackboardTitleLabel;
@property (nonatomic) UILabel *documentTitleLabel;
@property (nonatomic) UIButton *backToAlbumDocumentButton;
@property (nonatomic) UIView *uploadDocumentView;
@property (nonatomic) UIButton *uploadDocumentButton;

#pragma mark - method

- (void)updateCollectionViewHidden;
- (void)backToAlbumDocument;
- (void)showDocumentFileManagerViewController;
- (void)hide;
- (void)didSelectDocument:(BJLDocument *)document index:(NSInteger)index isAlbum:(BOOL)isAlbum;
- (void)updateBlackboardBorderHidden;

@end

NS_ASSUME_NONNULL_END
