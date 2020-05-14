//
//  BJLScPPTCell.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/9/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScPPTCell.h"
#import "BJLScAppearance.h"

NSString * const BJLScPPTCellIdentifier_uploading = @"uploading", * const BJLScPPTCellIdentifier_document = @"document";

static const CGFloat iconSize = 24.0;

@interface BJLScPPTCell ()

@property (nonatomic) UIImageView *iconView;
@property (nonatomic) UILabel *nameLabel, *stateLabel;
@property (nonatomic) UIView *progressView;

@end

@implementation BJLScPPTCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self makeSubviews];
        [self makeConstraints];
        [self prepareForReuse];
    }
    return self;
}

- (void)makeSubviews {
    self.iconView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.backgroundColor = [UIColor bjlsc_grayImagePlaceholderColor];
        imageView.layer.cornerRadius = BJLScButtonCornerRadius;
        imageView.layer.masksToBounds = YES;
        [self.contentView addSubview:imageView];
        imageView;
    });
    
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor bjlsc_darkGrayTextColor];
        label.font = [UIFont systemFontOfSize:15.0];
        [self.contentView addSubview:label];
        label;
    });
    
    self.stateLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentRight;
        label.textColor = [UIColor bjlsc_lightGrayTextColor];
        label.font = [UIFont systemFontOfSize:13.0];
        [self.contentView addSubview:label];
        label;
    });
    
    self.progressView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjlsc_lightGrayBackgroundColor];
        [self.contentView insertSubview:view atIndex:0];
        view;
    });
}

- (void)makeConstraints {
    [self.iconView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.contentView).with.offset(BJLScViewSpaceL);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(iconSize));
    }];
    
    [self.nameLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.iconView.bjl_right).with.offset(BJLScViewSpaceM);
        make.centerY.equalTo(self.contentView);
    }];
    
    [self.stateLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.horizontal.hugging.compressionResistance.required();
        make.left.greaterThanOrEqualTo(self.nameLabel.bjl_right).with.offset(BJLScViewSpaceM);
        make.right.equalTo(self.contentView).with.offset(- BJLScViewSpaceM);
        make.centerY.equalTo(self.contentView);
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.iconView.image = nil;
    self.nameLabel.text = nil;
    
    self.stateLabel.hidden = YES;
    self.stateLabel.text = nil;
    
    self.progressView.hidden = YES;
}

- (void)updateWithUploadingTask:(BJLScPPTUploadingTask *)uploadingTask {
    self.iconView.image = [self iconWithImageFile:uploadingTask.imageFile];
    self.nameLabel.text = uploadingTask.imageFile.fileName;
    
    self.stateLabel.hidden = NO;
    self.stateLabel.text = ({
        NSString *stateText = nil;
        switch (uploadingTask.state) {
            case BJLUploadState_waiting:
                stateText = uploadingTask.error ? @"上传失败" : @"等待上传";
                break;
            case BJLUploadState_uploading:
                stateText = @"上传中";
                break;
            case BJLUploadState_uploaded:
                stateText = @"等待添加";
                break;
            default:
                break;
        }
        stateText;
    });
    
    self.progressView.hidden = NO;
    [self.progressView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.top.bottom.right.equalTo(self.contentView);
        // left 0.1 for adding state
        make.width.equalTo(self.contentView).multipliedBy(1.0 - uploadingTask.progress * 0.95);
    }];
}

- (void)updateWithDocument:(BJLDocument *)document {
    self.iconView.image = [self iconWithDocument:document];
    self.nameLabel.text = document.fileName;
    self.stateLabel.text = nil;
    self.stateLabel.hidden = YES;
    self.progressView.hidden = YES;
}

- (UIImage *)iconWithImageFile:(ICLImageFile *)imageFile {
    return [UIImage bjlsc_imageNamed:@"bjl_sc_file_jpg"]; // thumbnail
}

- (UIImage *)iconWithDocument:(BJLDocument *)document {
    NSString *imageName = nil;
    if (document.pageInfo.isAlbum) {
        NSString *fileExtension = (document.fileExtension.length
                                   ? [document.fileExtension lowercaseString]
                                   : [document.fileName.pathExtension lowercaseString]);
        if ([fileExtension isEqualToString:@"pdf"]
            || [fileExtension isEqualToString:@".pdf"]) {
            imageName = @"bjl_sc_file_PDF";
        }
        else if ([fileExtension isEqualToString:@"ppt"]
                 || [fileExtension isEqualToString:@"pptx"]
                 || [fileExtension isEqualToString:@".ppt"]
                 || [fileExtension isEqualToString:@".pptx"]) {
            imageName = @"bjl_sc_file_PPT";
        }
    }
    return [UIImage bjlsc_imageNamed:imageName ?: @"bjl_sc_file_jpg"]; // thumbnail
}

@end
