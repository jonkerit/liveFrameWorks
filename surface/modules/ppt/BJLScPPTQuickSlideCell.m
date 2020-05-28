//
//  BJLScPPTQuickSlideCell.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScPPTQuickSlideCell.h"
#import "BJLScAppearance.h"

static const CGSize labelSize = {16.0, 16.0};
static const CGSize pptSize = {80.0, 60.0};

@interface BJLScPPTQuickSlideCell ()

@property (nonatomic, nullable) BJLSlidePage *slidePage;
@property (nonatomic) UIImageView *pptView;
@property (nonatomic) UILabel *numberLabel;
@property (nonatomic) UIButton *deleteButton;

@end

@implementation BJLScPPTQuickSlideCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpContentView];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.slidePage = nil;
    self.deleteButton.hidden = YES;
    self.selected = NO;
    self.pptView.image = nil;
    self.numberLabel.text = nil;
}

#pragma mark - setUp contentView

- (void)setUpContentView {
    self.selectedBackgroundView.backgroundColor = [UIColor bjlsc_blueBrandColor];
    self.contentView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self.contentView addGestureRecognizer:tapGesture];
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress)];
    [self.contentView addGestureRecognizer:longPressGesture];
    [tapGesture requireGestureRecognizerToFail:longPressGesture];
    // pptView
    self.pptView = ({
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        imageView;
    });
    [self.contentView addSubview:self.pptView];
    [self.pptView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.contentView);
        make.width.equalTo(@(pptSize.width));
        make.height.equalTo(@(pptSize.height));
    }];
    
    // numberLabel
    self.numberLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor bjlsc_dimColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [self.contentView addSubview:self.numberLabel];
    [self.numberLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.right.equalTo(self.pptView);
        make.width.greaterThanOrEqualTo(@(labelSize.width));
        make.width.lessThanOrEqualTo(self.pptView.bjl_width);
        make.height.equalTo(@(labelSize.height));
    }];
    
    // editing
    self.deleteButton = ({
        UIButton *button = [UIButton new];
        button.hidden = YES;
        button.backgroundColor = [UIColor clearColor];
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_ppt_delete"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(deletePage) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.contentView addSubview:self.deleteButton];
    [self.deleteButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(self.pptView.bjl_right).offset(4.0);
        make.top.equalTo(self.pptView.bjl_top).offset(-4.0);
        make.width.height.equalTo(@18.0);
    }];
}

#pragma mark - update content

- (void)updateContentWithSlidePage:(BJLSlidePage *)slidePage whiteboardCount:(NSInteger)whiteboardCount imageSize:(CGSize)imageSize {
    self.slidePage = slidePage;
    // ppt
    NSString *format = BJLWebImageLoader.sharedImageLoader.supportsWebP ? @"webp" : nil;
    NSURL *pageURL = [slidePage pageURLWithSize:imageSize
                                          scale:1.0
                                           fill:NO
                                         format:format];
    NSURL *cdnURL = [BJLSlidePage pageURLWithCurrentCDNHost:pageURL];
    [self.pptView bjl_setImageWithURL:cdnURL
                          placeholder:[UIImage bjl_imageNamed:@"bjl_ppt_placeholder"]
                           completion:nil];
    
    // number
    NSString *numberText;
    if ([slidePage.documentID isEqualToString:BJLBlackboardID]) {
        numberText = whiteboardCount > 1 ? [NSString stringWithFormat:@"白板%td", slidePage.documentPageIndex] : @"白板";
    }
    else {
        numberText = [NSString stringWithFormat:@"%td", slidePage.documentPageIndex - whiteboardCount];
    }
    self.numberLabel.text = numberText;
}

- (void)singleTap {
    if (self.singleTapCallback) {
        self.singleTapCallback();
    }
}

- (void)longPress {
    if (self.longPressCallback) {
        self.longPressCallback();
    }
}

- (void)deletePage {
    if (self.deletePageCallback) {
        self.deletePageCallback(self.slidePage.documentID, self.slidePage.slidePageIndex);
    }
}

- (void)updateEditing:(BOOL)editing {
    self.deleteButton.hidden = !editing;
}

#pragma mark - overwrite

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.pptView.layer.borderWidth = selected ? 2.0 : BJLScOnePixel;
    self.pptView.layer.borderColor = selected ? [[UIColor bjlsc_blueBrandColor] CGColor] : [[UIColor bjlsc_grayLineColor] CGColor];
}

@end
