//
//  BJLIcDocumentFileDisplayListView.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/27.
//  Copyright © 2018 BaijiaYun. All rights reserved.
//

#import "BJLIcDocumentFileDisplayListView.h"
#import "BJLIcDocumentFileDisplayListView+private.h"
#import "BJLIcDocumentFileDisplayListView+multipleDisplay.h"
#import "BJLIcDocumentFileDisplayListView+singleDisplay.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcDocumentFileDisplayListView

- (instancetype)initWithRoom:(nullable BJLRoom *)room singleDisplay:(BOOL)singleDisplay {
    if (self = [super initWithFrame:CGRectZero]) {
        self.singleDisplay = singleDisplay;
        if (singleDisplay && room) {
            self.room = room;
            self.documentIndex = -1;
            self.albumIndex = -1;
            self.type = BJLIcDocumentFileDisplayLayoutTypeLayoutMaximized;
            self.singleDisplay = YES;
            [self makeSubviewsAndConstraints];
        }
        else {
            self.documentFileList = [NSMutableArray new];
            self.type = BJLIcDocumentFileDisplayLayoutTypeLayoutNormal;
            self.singleDisplay = NO;
            [self makeSubviewsAndConstraints];
        }
        self.webDocumentFileList = [NSMutableArray new];
        [self makeObservingForWebDocument];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.backgroundView bjlic_drawRectCorners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(8.0, 8.0)];
    [self.backgroundView bjlic_drawBorderWidth:1.0 borderColor:[UIColor colorWithWhite:1.0 alpha:0.1] corners:UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii:CGSizeMake(8.0, 8.0)];
    bjl_weakify(self);
    self.hitTestBlock = ^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        bjl_strongify(self);
        if (   (self.containerView.hidden && [hitView isEqual:self.showFileListButton])
            || !self.containerView.hidden) {
            return hitView;
        }
        return nil;
    };
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
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
        view.layer.masksToBounds = YES;
        view.accessibilityLabel = BJLKeypath(self, backgroundView);
        view;
    });
    [self addSubview:self.backgroundView];
    [self.backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    self.containerView = ({
        UIView *view  = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        view;
    });
    [self addSubview:self.containerView];
    [self.containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    
    if (self.singleDisplay) {
        [self makeSingleDisplaySubviewsAndConstraints];
    }
    else {
        [self makeMultipleDisplaySubviewsAndConstraints];
    }
}

- (void)makeObservingForWebDocument {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, allWebDocuments)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self.webDocumentFileList removeAllObjects];
             for (BJLDocument *document in self.room.documentVM.allWebDocuments) {
                 BJLIcDocumentFile *documentFile = [[BJLIcDocumentFile alloc] initWithRemoteDocument:document];
                 [self.webDocumentFileList bjl_addObject:documentFile];
             }
             [self.collectionView reloadData];
             return YES;
         }];
}

#pragma mark - actions

- (void)updateWithDocumentFileList:(NSArray<BJLIcDocumentFile *> *)documentFileList layoutType:(BJLIcDocumentFileDisplayLayoutType)type {
    // 需要显示视图
    if (type != BJLIcDocumentFileDisplayLayoutTypeLayoutNormal && self.type == BJLIcDocumentFileDisplayLayoutTypeLayoutNormal) {
        [self updateCollectionViewHidden];
    }
    // 需要隐藏视图
    else if (type == BJLIcDocumentFileDisplayLayoutTypeLayoutNormal) {
        [self hide];
    }
    self.type = type;
    [self.documentFileList removeAllObjects];
    [self.documentFileList addObjectsFromArray:documentFileList];
    if (self.superview && self.collectionView && !self.collectionView.hidden) {
        [self.collectionView reloadData];
    }
}

- (void)hide {
    [self removeFromSuperview];
}

- (void)updateCollectionViewHidden {
    if (self.type != BJLIcDocumentFileDisplayLayoutTypeLayoutNormal && self.containerView.hidden) {
        [self showContainerView];
    }
    else {
        [self hideContainerView];
    }
}

- (void)showContainerView {
    self.containerView.hidden = NO;
    self.backgroundView.hidden = NO;
    self.showFileListButton.hidden = YES;
    [self.collectionView reloadData];
}

- (void)hideContainerView {
    self.containerView.hidden = YES;
    self.backgroundView.hidden = YES;
    self.showFileListButton.hidden = NO;
}

- (void)showDocumentFileManagerViewController {
    if (self.uploadDocumentCallback) {
        self.uploadDocumentCallback();
    }
}

- (void)didSelectDocument:(BJLDocument *)document index:(NSInteger)index isAlbum:(BOOL)isAlbum {
    if (!document) {
        return;
    }
    if (index < 0) {
        // 黑板，置空当前选中文档，刷新的一级视图还是二级视图沿用上次的设置
        self.albumIndex = -1;
        self.documentIndex = -1;
        if (self.selectDocumentCallback) {
            self.selectDocumentCallback(self.blackboardDocument, 0);
        }
        [self updateBlackboardBorderHidden];
    }
    else {
        // 只要选中文档，一定将是展示文档细节，但是单个图片文档不必展示细节，传过来的参数只是代表当前将要选中的是文档还是文档内容
        self.isAlbumDetail = document.pageInfo.isAlbum; // 控制刷新的时候刷新一级视图还是二级视图
        if (isAlbum) {
            // 只改变文档索引
            NSInteger documentIndex = [self.room.documentVM.allDocuments indexOfObject:document];
            self.documentIndex = documentIndex - 1;
            self.albumDocument = document;
            [self updateSingleDisplayConstraints];
            if (!self.isAlbumDetail) {
                // 点击的是文档，但是实际只有一页，这时直接跳转，改变文档内容页码
                self.albumIndex = index;
                if (self.selectDocumentCallback) {
                    self.selectDocumentCallback(document, index);
                }
                [self updateBlackboardBorderHidden];
            }
        }
        else {
            // 只改变文档内容页码
            self.albumIndex = index;
            self.albumDocument = document;
            if (self.selectDocumentCallback) {
                self.selectDocumentCallback(document, index);
            }
            [self updateBlackboardBorderHidden];
        }
    }
    [self.collectionView reloadData];
}

- (void)backToAlbumDocument {
    self.isAlbumDetail = NO;
    [self updateSingleDisplayConstraints];
    [self.collectionView reloadData];
    [self updateBlackboardBorderHidden];
}

- (void)updateBlackboardBorderHidden {
    BOOL hidden = YES;
    if (self.isAlbumDetail) {
        hidden = self.albumIndex >= 0;
    }
    else {
        hidden = self.documentIndex >= 0;
    }
    self.blackboardBorderLayer.hidden = hidden;
}

#pragma mark - collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.singleDisplay) {
            if (self.isAlbumDetail) {
                return self.albumDocument.pageInfo.pageCount ?: 1;
            }
            else {
                // 黑板单独处理，不随 collectionview 滑动
                return self.room.documentVM.allDocuments.count - 1;
            }
        }
        else {
            return self.documentFileList.count;
            
        }
    }
    else {
        return self.webDocumentFileList.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    if (indexPath.section == 0) {
        if (self.singleDisplay) {
            if (self.isAlbumDetail) {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:kDetailPreviewCellReuseIdentifier forIndexPath:indexPath];
            }
            else {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPreviewCellReuseIdentifier forIndexPath:indexPath];
            }
        }
        else {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:kFileCellReuseIdentifier forIndexPath:indexPath];
        }
    }
    else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:kWebFileCellReuseIdentifier forIndexPath:indexPath];
    }
    
    return cell;
}

#pragma mark - collection view delegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.singleDisplay) {
            if (self.isAlbumDetail) {
                BJLIcDocumentDetailPreviewCell *documentDetailCell = bjl_as(cell, BJLIcDocumentDetailPreviewCell);
                [documentDetailCell updateWithDocument:self.albumDocument index:indexPath.row];
                bjl_weakify(self);
                [documentDetailCell setSingleTapCallback:^(BJLDocument * _Nullable document, NSInteger index, BOOL isAlbum) {
                    bjl_strongify(self);
                    [self didSelectDocument:self.albumDocument index:index isAlbum:isAlbum];
                }];
                // 根据本地的文档信息去显示或者隐藏选中状态，文档索引由于除去了黑板，因此要 +1
                if (self.albumIndex == indexPath.row
                    && [self.albumDocument.documentID isEqualToString:[self.room.documentVM.allDocuments bjl_objectAtIndex:self.documentIndex + 1].documentID]) {
                    [documentDetailCell updateImageViewBorderHidden:NO];
                }
                else {
                    [documentDetailCell updateImageViewBorderHidden:YES];
                }
            }
            else {
                BJLIcDocumentPreviewCell *documentPreviewCell = bjl_as(cell, BJLIcDocumentPreviewCell);
                // 黑板单独处理，不随 collectionview 滑动，因此此处除去了黑板，索引需要 +1
                BJLDocument *document = [self.room.documentVM.allDocuments bjl_objectAtIndex:indexPath.row + 1];
                [documentPreviewCell updateWithDocument:document];
                bjl_weakify(self);
                [documentPreviewCell setSingleTapCallback:^(BJLDocument * _Nullable document, NSInteger index, BOOL isAlbum) {
                    bjl_strongify(self);
                    [self didSelectDocument:document index:index isAlbum:isAlbum];
                }];
                if (self.documentIndex == indexPath.row) {
                    [documentPreviewCell updateImageViewBorderHidden:NO];
                }
                else {
                    [documentPreviewCell updateImageViewBorderHidden:YES];
                }
            }
        }
        else {
            BJLIcDocumentFile *file = [self.documentFileList bjl_objectAtIndex:indexPath.row];
            BJLIcDocumentFileCell *documentFileCell = bjl_as(cell, BJLIcDocumentFileCell);
            [documentFileCell updateWithDocumentFile:file];
            if (indexPath.row == 0) {
                cell.backgroundColor = [UIColor bjl_colorWithHexString:@"#FFFFFF" alpha:0.1];
            }
            bjl_weakify(self);
            [documentFileCell setSingleTapCallback:^(BJLIcDocumentFile * _Nonnull documentFile, UIImage * _Nullable image) {
                bjl_strongify(self);
                if (self.selectDocumentFileCallback) {
                    self.selectDocumentFileCallback(file);
                }
            }];
        }
    }
    else {
        BJLIcDocumentPreviewCell *documentPreviewCell = bjl_as(cell, BJLIcDocumentPreviewCell);
        // 黑板单独处理，不随 collectionview 滑动
        BJLIcDocumentFile *file = [self.webDocumentFileList bjl_objectAtIndex:indexPath.row];
        BJLDocument *document = file.remoteDocument;
        [documentPreviewCell updateWithDocument:document];
        bjl_weakify(self);
        [documentPreviewCell setSingleTapCallback:^(BJLDocument * _Nullable document, NSInteger index, BOOL isAlbum) {
            bjl_strongify(self);
            if (self.selectDocumentFileCallback) {
                self.selectDocumentFileCallback(file);
            }
        }];
    }
}

@end

NS_ASSUME_NONNULL_END
