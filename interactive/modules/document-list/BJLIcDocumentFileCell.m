//
//  BJLIcDocumentFileCell.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/28.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcDocumentFileCell.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFileCellHeader ()

@property (nonatomic) UILabel *titleLabel;

@end

@implementation BJLIcDocumentFileCellHeader

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor whiteColor];
        label;
    });
    [self addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self).offset(16.0);
        make.top.bottom.equalTo(self);
    }];
}

- (void)updateWithTitle:(nullable NSString *)title {
    self.titleLabel.text = title;
}

@end

@interface BJLIcDocumentFileCell ()

@property (nonatomic) BJLIcDocumentFile *file;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIImageView *previewImageView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIImageView *editImageView;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic, nullable) UIView *errorView;
@property (nonatomic, nullable) id<BJLObservation> progressObserver;
@property (nonatomic) BOOL isLoadingImage;

@end

@implementation BJLIcDocumentFileCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)dealloc {
    [self stopProgressOberver];
}

#pragma mark - update

- (void)updateWithDocumentFile:(nullable BJLIcDocumentFile *)file {
    [self stopProgressOberver];
    [self.errorView removeFromSuperview];
    self.errorView = nil;
    self.isLoadingImage = NO;
    self.progressView.hidden = YES;
    self.previewImageView.hidden = YES;
    self.previewImageView.image = nil;
    self.imageView.image = nil;
    
    self.file = file;
    if (!file) {
        return;
    }
    // gesture
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTapGesture];
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleGesture)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTapGesture];
    // image
    UIImage *fileImage = nil;
    switch (self.file.type) {
        case BJLIcDocumentFileTXT:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_txt"];
            break;
            
        case BJLIcDocumentFileDOC:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_doc"];
            break;
            
        case BJLIcDocumentFilePDF:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_pdf"];
            break;
            
        case BJLIcDocumentFileXLS:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_xls"];
            break;
            
        case BJLIcDocumentFileNormalPPT:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_ppt"];
            break;
            
        case BJLIcDocumentFileAnimatedPPT:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_animatedppt"];
            break;
            
        case BJLIcDocumentFileWebPPT:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_webppt"];
            break;
            
        case BJLIcDocumentFileImage: {
            self.isLoadingImage = YES;
            self.previewImageView.hidden = NO;
            NSURL *url = self.file.localDocument ? nil : file.url;
            bjl_weakify(self);
            [self.previewImageView bjl_setImageWithURL:url placeholder:[UIImage bjlic_imageNamed:@"bjl_document_img"] completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
                bjl_strongify(self);
                self.isLoadingImage = NO;
            }];
        }
            break;
            
        case BJLIcDocumentFileAudio:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_audio"];
            break;
            
        case BJLIcDocumentFileVideo:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_video"];
            break;
            
        default:
            fileImage = [UIImage bjlic_imageNamed:@"bjl_document_txt"];
            break;
    }
    self.imageView.image = fileImage;
    // title
    switch (self.file.state) {
            // 普通状态
        case BJLIcDocumentFileNormal:
            self.titleLabel.text = self.file.name;
            break;
            
            // 错误状态
        case BJLIcDocumentFileError:
            self.titleLabel.text = self.file.name;
            self.previewImageView.image = nil;
            self.imageView.image = [UIImage bjlic_imageNamed:@"bjl_document_error"];
            break;
            
            // 上传中
        case BJLIcDocumentFileUploading:
            self.titleLabel.text = @"上传中...";
            [self startProgressObserver];
            break;

            // 转码中
        case BJLIcDocumentFileTranscoding:
            self.titleLabel.text = @"转码中...";
            [self startProgressObserver];
            break;
            
        default:
            self.titleLabel.text = self.file.name;
            break;
    }
    // edit mode
    UIImage *editImage = nil;
    switch (self.file.editMode) {
        case BJLIcDocumentFileNonEdit:
            editImage = nil;
            break;
            
        case BJLIcDocumentFileSelected:
            editImage = [UIImage bjlic_imageNamed:@"bjl_document_selected"];
            break;
            
        case BJLIcDocumentFileUnselected:
            editImage = [UIImage bjlic_imageNamed:@"bjl_document_unselected"];
            break;
            
        default:
            editImage = nil;
            break;
    }
    self.editImageView.image = editImage;
}

- (void)showErrorView {
    if (self.file.state == BJLIcDocumentFileError && !self.errorView) {
        [self makeErrorView];
    }
}

#pragma mark - gesture

- (void)handleTapGesture {
    if (self.singleTapCallback) {
        self.singleTapCallback(self.file, self.isLoadingImage ? nil : self.previewImageView.image);
    }
}

- (void)handleDoubleGesture {
    if (self.doubleTapCallback) {
        self.doubleTapCallback(self.file);
    }
}

#pragma mark - observer

- (void)startProgressObserver {
    [self stopProgressOberver];
    if (self.window && !self.hidden) {
        self.progressView.hidden = NO;
        [self.progressView setProgress:self.file.progress animated:NO];
    }
    bjl_weakify(self);
    self.progressObserver = [self bjl_kvo:BJLMakeProperty(self.file, progress)
                                 observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
                                     bjl_strongify(self);
                                     if (self.file.progress > 0.0) {
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             if (self.window && !self.hidden) {
                                                 self.progressView.hidden = NO;
                                                 [self.progressView setProgress:self.file.progress animated:([now floatValue] > [old floatValue])];
                                             }
                                         });
                                     }
                                     return YES;
                                 }];
}

- (void)stopProgressOberver {
    [self.progressObserver stopObserving];
    self.progressObserver = nil;
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 4.0;
    
    self.imageView = [UIImageView new];
    [self.contentView addSubview:self.imageView];
    [self.imageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView);
        make.width.equalTo(@58.0);
        make.height.equalTo(@72.0);
    }];
    
    self.previewImageView = ({
        UIImageView *imageView =[UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView;
    });
    [self.contentView addSubview:self.previewImageView];
    [self.previewImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].documentFileCellImageSize));
        make.top.centerX.equalTo(self);
    }];
    
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor whiteColor];
        label;
    });
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self).offset(75.0);
        make.height.equalTo(@20.0);
        make.width.lessThanOrEqualTo(self.contentView);
    }];
    
    self.editImageView = [UIImageView new];
    [self.contentView addSubview:self.editImageView];
    [self.editImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.right.equalTo(self.contentView);
        make.height.width.equalTo(@24.0);
    }];
    
    self.progressView = ({
        UIProgressView *progressView = [[UIProgressView alloc] init];
        progressView.layer.masksToBounds = YES;
        progressView.hidden = YES;
        progressView.progressTintColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        progressView.trackTintColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        progressView;
    });
    [self addSubview:self.progressView];
    [self.progressView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.equalTo(@72.0);
        make.height.equalTo(@2.0);
        make.centerX.equalTo(self);
        make.top.equalTo(self.titleLabel.bjl_bottom);
    }];
}

- (void)makeErrorView {
    self.errorView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:0.5];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 4.0;
        view;
    });
    [self.contentView addSubview:self.errorView];
    [self.errorView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self);
    }];
    UILabel *label = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.backgroundColor = [UIColor clearColor];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 6.0;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSDictionary *attributedDic = @{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                        NSForegroundColorAttributeName : [UIColor whiteColor],
                                        NSParagraphStyleAttributeName : paragraphStyle};
        label.attributedText = [[NSAttributedString alloc] initWithString:self.file.errorMessage attributes:attributedDic];
        label;
    });
    [self.errorView addSubview:label];
    [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self);
        make.centerY.equalTo(self);
    }];
}

@end

NS_ASSUME_NONNULL_END
