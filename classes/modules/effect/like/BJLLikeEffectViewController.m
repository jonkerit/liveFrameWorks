//
//  BJLLikeEffectViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2018/10/22.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "BJLLikeEffectViewController.h"
#import "BJLViewControllerImports.h"
#import "BJLAppearance.h"

@interface BJLLikeEffectViewController ()

@property (nonatomic) NSString *name;
@property (nonatomic) BOOL isForInteractiveClass;
@property (nonatomic) CGPoint endPoint;
@property (nonatomic) NSMutableArray<UIImage *> *starImages;
@property (nonatomic) UIView *scaleView;
@property (nonatomic) UIImageView *awardBackgroundImageView;
@property (nonatomic) UIImageView *awardImageView;
@property (nonatomic) UIImageView *starImageView;
@property (nonatomic) UILabel *nameLabel;

@property (nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation BJLLikeEffectViewController

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        self.name = name;
        self.starImages = [NSMutableArray new];
        for (NSInteger i = 1; i <= 20; i ++) {
            UIImage *image = [UIImage bjl_imageNamed:[NSString stringWithFormat:@"bjl_like_star%ld", (long)i]];
            [self.starImages bjl_addObject:image];
        }
    }
    return self;
}

- (instancetype)initForInteractiveClassWithName:(NSString *)name endPoint:(CGPoint)endPoint {
    self = [self initWithName:name];
    self.isForInteractiveClass = YES;
    self.endPoint = endPoint;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeSubviewsAndConstraints];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
    gesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:gesture];
    // start animate
    [self startScaleAnimation:YES];
    [self startShineAnimation:0];
    [self.starImageView startAnimating];
    
    CGFloat duration = self.isForInteractiveClass ? 2.0 : 3.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startScaleAnimation:NO];
    });
    
    // audio player
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self playLikeAudio];
    });
}

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    BOOL isHorizontal = BJLIsHorizontalUI(self);
    
    self.scaleView = [UIView new];
    [self.view addSubview:self.scaleView];
    [self.scaleView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.awardBackgroundImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.image = [UIImage bjl_imageNamed:@"bjl_like_shine"];
        imageView;
    });
    [self.scaleView addSubview:self.awardBackgroundImageView];
    [self.awardBackgroundImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.scaleView);
        if (self.isForInteractiveClass || isHorizontal) {
            make.height.equalTo(self.scaleView).multipliedBy(25.0 / 32.0);
            make.width.equalTo(self.awardBackgroundImageView.bjl_height);
        }
        else {
            make.width.equalTo(self.scaleView);
            make.height.equalTo(self.awardBackgroundImageView.bjl_width);
        }
    }];
    
    self.starImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.animationImages = self.starImages;
        imageView;
    });
    [self.scaleView addSubview:self.starImageView];
    [self.starImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.awardBackgroundImageView);
    }];
    
    self.awardImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.image = [UIImage bjl_imageNamed:@"bjl_like_award"];
        imageView;
    });
    [self.scaleView addSubview:self.awardImageView];
    [self.awardImageView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.starImageView);
    }];
    
    self.nameLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:16.0];
        label.textColor = [UIColor whiteColor];
        label.text = self.name;
        label;
    });
    [self.awardImageView addSubview:self.nameLabel];
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.awardImageView, bounds)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.awardImageView.bounds.size.height) {
                 CGFloat bottomOffset = self.awardImageView.bounds.size.height * 0.3;
                 CGFloat height = self.awardImageView.bounds.size.height * (13.0 /180.0);
                 [self.nameLabel bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                     make.centerX.equalTo(self.awardImageView);
                     make.width.lessThanOrEqualTo(self.awardImageView.bjl_width).multipliedBy(0.4);
                     make.bottom.equalTo(self.awardImageView).offset(-bottomOffset);
                     make.height.greaterThanOrEqualTo(@(height));
                 }];
             }
             return YES;
         }];
}

- (void)startShineAnimation:(CGFloat)angle {
    __block float nextAngle = angle + 10;
    CGAffineTransform endAngle = CGAffineTransformMakeRotation(angle * (M_PI / 180.0f));
    [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        if (self.awardBackgroundImageView && !self.awardBackgroundImageView.hidden) {
            self.awardBackgroundImageView.transform = endAngle;
        }
    } completion:^(BOOL finished) {
        if (finished) {
            [self startShineAnimation:nextAngle];
        }
    }];
}

- (void)startScaleAnimation:(BOOL)zoom {
    if (zoom) {
        self.scaleView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        CGAffineTransform zoom = CGAffineTransformMakeScale(1.0, 1.0);
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (self.scaleView && !self.scaleView.hidden) {
                self.scaleView.transform = zoom;
            }
        } completion:nil];
    }
    else {
        if (self.isForInteractiveClass) {
            CGFloat targetSize = 30.0;
            CGFloat scaleRate = targetSize / self.awardImageView.frame.size.height;
            CGFloat xScaleValue = (self.awardImageView.frame.size.width - targetSize) / 2 + self.awardImageView.frame.origin.x;
            CGFloat yScaleValue = (self.awardImageView.frame.size.height - targetSize) / 2 + self.awardImageView.frame.origin.y;
            CGFloat xOffset = self.endPoint.x - xScaleValue;
            CGFloat yOffset = self.endPoint.y - yScaleValue;
            CGAffineTransform translation = CGAffineTransformMakeTranslation(xOffset, yOffset);
            translation = CGAffineTransformScale(translation, scaleRate, scaleRate);
            [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                if (self.scaleView && !self.scaleView.hidden) {
                    self.scaleView.transform = translation;
                }
            } completion:^(BOOL finished) {
                [self hide];
            }];
        }
        else {
            CGAffineTransform zoomOut = CGAffineTransformMakeScale(0.5, 0.5);
            [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                if (self.scaleView && !self.scaleView.hidden) {
                    self.scaleView.transform = zoomOut;
                }
            } completion:^(BOOL finished) {
                [self hide];
            }];
        }
    }
}

- (void)hide {
    [self stopLikeAudio];
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

#pragma mark - audio player

- (void)playLikeAudio {
    if (!self.audioPlayer) {
        NSBundle *classBundle = [NSBundle bundleForClass:[BJLLikeEffectViewController class]];
        NSString *bundlePath = [classBundle pathForResource:@"BJLiveUIMedia" ofType:@"bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *audioPath = [bundle pathForResource:@"like" ofType:@"mp3"];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:audioPath] error:nil];
        [self.audioPlayer prepareToPlay];
    }
    self.audioPlayer.volume = 1;
    [self.audioPlayer play];
    
}

- (void)stopLikeAudio {
    [self.audioPlayer stop];
    self.audioPlayer = nil;
}

- (void)dealloc {
    if (self.audioPlayer) {
        [self stopLikeAudio];
    }
}

@end
