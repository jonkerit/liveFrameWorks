//
//  BJLIcDocumentPreviewCell.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2019/3/29.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase+UIKit.h>
#import <BJLiveBase/BJLWebImageLoader.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcDocumentPreviewCell.h"
#import "BJLIcAppearance.h"
#import "BJLAppearance.h"

@interface BJLIcDocumentPreviewCell ()

@property (nonatomic, nullable) BJLDocument *document;
@property (nonatomic) UIImageView *previewImageView;
@property (nonatomic, nullable) CAShapeLayer *imageBorderLayer;
@property (nonatomic) BOOL imageBorderLayerHidden;
@property (nonatomic) UIImageView *tipImageView;
@property (nonatomic) UILabel *titleLabel;

@end

@implementation BJLIcDocumentPreviewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imageBorderLayerHidden = YES;
        [self makeSubviewsAndConstraints];
        [self makeObserving];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    
    self.previewImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.contentView addSubview:self.previewImageView];
    [self.previewImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.top.equalTo(self.contentView);
        make.width.equalTo(@140.0);
        make.height.equalTo(@70.0);
    }];
    
    self.tipImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.image = [UIImage bjlic_imageNamed:@"bjl_document_selected"];
        imageView.hidden = self.imageBorderLayerHidden;
        imageView;
    });
    [self.contentView addSubview:self.tipImageView];
    [self.tipImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.right.equalTo(self.previewImageView);
        make.width.height.equalTo(@16.0);
    }];
    
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:14.0];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label;
    });
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.previewImageView.bjl_bottom).offset(2.0);
        make.left.right.equalTo(self.previewImageView);
        make.height.equalTo(@20.0);
    }];
    
    // gesture
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTapGesture];
}

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.previewImageView, bounds)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.imageBorderLayer = [self.previewImageView bjlic_drawBorderWidth:1.0 borderColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] corners:UIRectCornerAllCorners cornerRadii:CGSizeZero];
             self.imageBorderLayer.hidden = self.imageBorderLayerHidden;
             return YES;
         }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.document = nil;
    self.imageBorderLayerHidden = YES;
    self.imageBorderLayer.hidden = YES;
    self.tipImageView.hidden = YES;
    self.previewImageView.image = nil;
    self.titleLabel.text = nil;
}

- (void)updateWithDocument:(BJLDocument *)document {
    self.document = document;
    
    NSString *urlString = (document.isWebDocument
                           ? document.webDocumentCoverURL
                           : BJLAliIMG_aspectFit(CGSizeMake(140.0, 100.0), 0.0, [document.pageInfo pageURLStringWithPageIndex:0], nil));
    [self.previewImageView bjl_setImageWithURL:[NSURL URLWithString:urlString] placeholder:[UIImage bjl_imageNamed:@"bjl_ppt_placeholder"] completion:nil];
    self.titleLabel.text = document.fileName;
}

- (void)updateImageViewBorderHidden:(BOOL)hidden {
    self.imageBorderLayerHidden = hidden;
    self.imageBorderLayer.hidden = hidden;
    self.tipImageView.hidden = hidden || !self.document.pageInfo.isAlbum;
}

- (void)removeBorderLayer {
    if (self.imageBorderLayer) {
        [self.imageBorderLayer removeFromSuperlayer];
        self.imageBorderLayer = nil;
    }
}

- (void)handleTapGesture {
    if (self.singleTapCallback) {
        // 一级文档，index 直接传0
        self.singleTapCallback(self.document, 0, YES);
    }
    [self updateImageViewBorderHidden:NO];
}

@end

@interface BJLIcDocumentDetailPreviewCell ()

@property (nonatomic, nullable) BJLDocument *document;
@property (nonatomic) NSInteger index;
@property (nonatomic) UILabel *indexLabel;
@property (nonatomic) UIImageView *previewImageView;
@property (nonatomic, nullable) CAShapeLayer *imageBorderLayer;
@property (nonatomic) BOOL imageBorderLayerHidden;
@property (nonatomic) UILabel *titleLabel;

@end

@implementation BJLIcDocumentDetailPreviewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.imageBorderLayerHidden = YES;
        [self makeSubviewsAndConstraints];
        [self makeObserving];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    
    self.previewImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.contentView addSubview:self.previewImageView];
    [self.previewImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.contentView);
        make.right.equalTo(self.contentView).offset(-2.0);
        make.height.equalTo(@68.0);
        make.width.equalTo(@123.0);
    }];
    
    self.indexLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont systemFontOfSize:12.0];
        label;
    });
    [self.contentView addSubview:self.indexLabel];
    [self.indexLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.contentView).offset(2.0);
        make.top.bottom.equalTo(self.previewImageView);
    }];
    
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:14.0];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label;
    });
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.previewImageView.bjl_bottom).offset(2.0);
        make.left.right.equalTo(self.previewImageView);
        make.height.equalTo(@20.0);
    }];
    
    // gesture
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTapGesture];
}

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.previewImageView, bounds)
         observer:^BOOL(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.imageBorderLayer = [self.previewImageView bjlic_drawBorderWidth:1.0 borderColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] corners:UIRectCornerAllCorners cornerRadii:CGSizeZero];
             self.imageBorderLayer.hidden = self.imageBorderLayerHidden;
             return YES;
         }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.document = nil;
    self.index = 0;
    self.indexLabel.text = nil;
    self.imageBorderLayerHidden = YES;
    self.imageBorderLayer.hidden = YES;
    self.previewImageView.image = nil;
    self.titleLabel.text = nil;
}


- (void)updateWithDocument:(BJLDocument *)document index:(NSInteger)index {
    self.document = document;
    self.index = index;
    
    self.indexLabel.text = [NSString stringWithFormat:@"%td", self.index + 1];
    NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake(140.0, 100.0), 0.0, [document.pageInfo pageURLStringWithPageIndex:index], nil);
    [self.previewImageView bjl_setImageWithURL:[NSURL URLWithString:urlString] placeholder:[UIImage bjl_imageNamed:@"bjl_ppt_placeholder"] completion:nil];
    self.titleLabel.text = [NSString stringWithFormat:@"第%td页", self.index + 1];
}

- (void)updateImageViewBorderHidden:(BOOL)hidden {
    self.imageBorderLayerHidden = hidden;
    self.imageBorderLayer.hidden = hidden;
}

- (void)removeBorderLayer {
    if (self.imageBorderLayer) {
        [self.imageBorderLayer removeFromSuperlayer];
        self.imageBorderLayer = nil;
    }
}

- (void)handleTapGesture {
    if (self.singleTapCallback) {
        // 二级文档，不存在三级文档，album 直接传 NO
        self.singleTapCallback(self.document, self.index, NO);
    }
    [self updateImageViewBorderHidden:NO];
}

@end
