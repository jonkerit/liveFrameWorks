//
//  BJLRainEffectViewController.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/7/2.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLAppearance.h"
#import "BJLRainEffectViewController.h"
#import "BJLRainSence.h"
#import "BJLEnvelopeResultCell.h"

@interface BJLRainEffectViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) SKView *rainView;
@property (nonatomic) BJLRainSence *rainSence;
@property (nonatomic) CGSize senceSize;
@property (nonatomic) NSString *rainImageName;
@property (nonatomic) NSInteger rainCount;
@property (nonatomic) CGSize rainSize;
@property (nonatomic) NSInteger envelopeID;
@property (nonatomic) NSInteger rainDuration;
@property (nonatomic) NSMutableArray<NSString *> *coinImageNames;

@property (nonatomic) NSString *openEnvelopeImageName;
@property (nonatomic) NSString *openEnvelopeEmptyImageName;
@property (nonatomic) CGSize openEnvelopeSize;
@property (nonatomic) CGSize openEnvelopeEmptySize;
// start delay
@property (nonatomic) UIView *delayRainTipView;
@property (nonatomic) UILabel *delayRainLabel;
@property (nonatomic) UILabel *delayRainTipLabel;
@property (nonatomic) NSTimer *delayRainTimer;

// personalResult
@property (nonatomic) UIView *scoreResultView;

// end result
@property (nonatomic) NSArray<BJLEnvelopeRank *> *rankList;
@property (nonatomic) UIView *envelopeResultView;
@property (nonatomic) UITableView *resultTableView;
@property (nonatomic) UIView *emptyRankResultView;
@property (nonatomic) UIView *resultTableViewHeader;
@property (nonatomic) UIImageView *resultImageView;
@property (nonatomic) UIButton *closeButton;

@end

@implementation BJLRainEffectViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self->_room = room;
    }
    return self;
}

- (instancetype)initWithRoom:(BJLRoom *)room envelopeID:(NSInteger)envelopeID duration:(NSInteger)duration {
    if (self = [self initWithRoom:room]) {
        self.envelopeID = envelopeID;
        self.rainDuration = duration;
        self.coinImageNames = [NSMutableArray new];
        for (NSInteger i = 1; i <= 14; i ++) {
            NSString *imageName = [NSString stringWithFormat:@"bjl_ic_envelope_open%ld", (long)i];
            UIImage *image = [UIImage bjl_imageNamed:imageName];
            NSData *imageData = UIImagePNGRepresentation(image);
            NSString *imageFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:imageName];
            [imageData writeToFile:imageFilePath atomically:YES];
            [self.coinImageNames bjl_addObject:imageFilePath];
        }
    }
    return self;
}

- (void)dealloc {
    [self stopDelayRainTimer];
    self.resultTableView.delegate = nil;
    self.resultTableView.dataSource = nil;
}

- (void)setupRainEffectSize:(CGSize)size rainImageName:(NSString *)imageName rainCount:(NSInteger)count rainSize:(CGSize)rainSize {
    // 没有设置图片资源的情况下，取默认图片资源，转成 nsdata 后写入 APP temp 文件夹内，然后红包雨读取这个数据
    NSString *imageFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bjl_ic_envelope_run.png"];
    if (!imageName.length) {
        UIImage *image = [UIImage bjl_imageNamed:@"bjl_ic_envelope_run"];
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:imageFilePath atomically:YES];
        imageName = imageFilePath;
    }
    self.senceSize = size;
    self.rainImageName = imageName;
    self.rainCount = count;
    self.rainSize = rainSize;
}

- (void)setOpenEnvelopeImageName:(nullable NSString *)imageName emptyImageName:(nullable NSString *)emptyImageName size:(CGSize)size emptySize:(CGSize)emptySize {
    UIImage *image = [UIImage imageNamed:imageName];
    if (!image) {
        imageName = nil;
    }
    UIImage *emptyImage = [UIImage imageNamed:emptyImageName];
    if (!emptyImage) {
        emptyImageName = nil;
    }
    NSString *imageFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bjl_ic_envelope_run.png"];
    if (!imageName.length) {
        UIImage *image = [UIImage bjl_imageNamed:@"bjl_ic_envelope_run"];
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:imageFilePath atomically:YES];
        imageName = imageFilePath;
        emptyImageName = imageFilePath;
    }
    self.openEnvelopeImageName = imageName;
    self.openEnvelopeEmptyImageName = emptyImageName;
    self.openEnvelopeSize = size;
    self.openEnvelopeEmptySize = emptySize;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    
    [self makeSubviewsAndConstraints];
}

- (void)makeSubviewsAndConstraints {
    BOOL iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    self.delayRainTipView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    [self.view addSubview:self.delayRainTipView];
    [self.delayRainTipView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    UIImageView *envelopeView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.image = [UIImage bjl_imageNamed:@"bjl_ic_envelope_start"];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView;
    });
    [self.delayRainTipView addSubview:envelopeView];
    [envelopeView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.delayRainTipView);
        make.width.height.lessThanOrEqualTo(self.view).multipliedBy(0.8);
        make.width.equalTo(envelopeView.bjl_height).multipliedBy(envelopeView.image.size.width / envelopeView.image.size.height);
        make.width.equalTo(@(envelopeView.image.size.width)).priorityHigh();
        make.height.equalTo(@(envelopeView.image.size.height)).priorityHigh();
    }];
    self.delayRainLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:iPad ? 80.0 : 56.0];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [envelopeView addSubview:self.delayRainLabel];
    [self.delayRainLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(envelopeView.bjl_centerX);
        make.centerY.equalTo(envelopeView.bjl_bottom).multipliedBy(0.41);
    }];
    self.delayRainTipLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"抢红包啦";
        label.font = [UIFont systemFontOfSize:iPad ? 36.0 : 28.0];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [envelopeView addSubview:self.delayRainTipLabel];
    [self.delayRainTipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(envelopeView.bjl_centerX);
        make.centerY.equalTo(envelopeView.bjl_bottom).multipliedBy(0.69);
    }];
    // fire
    [self startDelayRainTimer];
}

#pragma mark - timer

- (void)startDelayRainTimer {
    [self stopDelayRainTimer];
    [self updateDelayLabel];
    bjl_weakify(self);
    self.delayRainTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1.0
                                                              repeats:YES
                                                                block:^(NSTimer * _Nonnull timer) {
                                                                    bjl_strongify_ifNil(self) {
                                                                        [timer invalidate];
                                                                        return;
                                                                    }
                                                                    [self updateDelayLabel];
                                                                }];
}

- (void)stopDelayRainTimer {
    if (self.delayRainTimer) {
        [self.delayRainTimer invalidate];
        self.delayRainTimer = nil;
    }
}

- (void)updateDelayLabel {
    static NSInteger delay = BJLRainDelay;
    self.delayRainLabel.text = [NSString stringWithFormat:@"%td", delay];
    if (delay == 0) {
        [self stopDelayRainTimer];
        [self.delayRainTipView removeFromSuperview];
        [self makeRainSence];
        delay = BJLRainDelay;
    }
    else {
        delay --;
    }
}

#pragma mark - sence

- (void)makeRainSence {
    if (self.rainView) {
        return;
    }
    self.rainView = [SKView new];
    [self.view addSubview:self.rainView];
    self.rainView.allowsTransparency = YES;
    self.rainView.backgroundColor = [UIColor clearColor];
    [self.rainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
#if DEBUG
    self.rainView.showsFPS = YES;
    self.rainView.showsNodeCount = YES;
    self.rainView.showsDrawCount = YES;
    self.rainView.showsQuadCount = YES;
    self.rainView.showsFields = YES;
#endif
    self.rainView.ignoresSiblingOrder = YES;
    self.rainSence = [BJLRainSence senceWithSize:self.senceSize rainImageName:self.rainImageName rainCount:self.rainCount rainSize:self.rainSize];
    self.rainSence.userInteractionEnabled = self.room.loginUser.isStudent;
    bjl_weakify(self);
    [self.rainSence setRequestOpenEnvelopeScoreCallback:^(BJLOpenEnvelopeScoreCompletion _Nonnull completion) {
        bjl_strongify(self);
        [self.room.roomVM grapEnvelopeWithID:self.envelopeID completion:^(NSInteger score, BJLError * _Nullable error) {
            completion(score);
        }];
    }];
    self.rainSence.coinImageNames = self.coinImageNames;
    [self.rainView presentScene:self.rainSence];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.rainDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.rainSence removeFromParent];
        [self.rainView removeFromSuperview];
        if (self.room.loginUser.isStudent) {
            [self makeEnvelopeResultViewAndConstraints:self.rainSence.totalScore];
        }
        else {
            [self makeEnvelopeRankResultViewAndConstraints];
        }
        self.rainSence = nil;
        self.rainView = nil;
    });
}

- (void)makeEnvelopeResultViewAndConstraints:(NSInteger)score {
    self.scoreResultView = [UIView new];
    [self.view addSubview:self.scoreResultView];
    [self.scoreResultView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    UIImageView *imageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.image = score > 0 ? [UIImage bjl_imageNamed:@"bjl_ic_envelope"] : [UIImage bjl_imageNamed:@"bjl_ic_envelope_empty"];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView;
    });
    [self.scoreResultView addSubview:imageView];
    [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.scoreResultView);
        make.width.height.lessThanOrEqualTo(self.view).multipliedBy(0.8);
        make.width.equalTo(imageView.bjl_height).multipliedBy(imageView.image.size.width / imageView.image.size.height);
        make.width.equalTo(@(imageView.image.size.width)).priorityHigh();
        make.height.equalTo(@(imageView.image.size.height)).priorityHigh();
    }];
    UIButton *confirmButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        button.layer.cornerRadius = 22.0;
        button.layer.masksToBounds = YES;
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:score > 0 ? @"完成" : @"再接再厉" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(makeEnvelopeRankResultViewAndConstraints) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.scoreResultView addSubview:confirmButton];
    [confirmButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@44.0);
        make.width.equalTo(@220.0).priorityHigh();
        make.width.lessThanOrEqualTo(imageView);
        make.centerX.equalTo(imageView);
        make.bottom.equalTo(imageView.bjl_bottom).multipliedBy(0.94);
    }];
    if (score > 0) {
        UILabel *label = ({
            UILabel *label = [UILabel new];
            label.numberOfLines = 2;
            label.backgroundColor = [UIColor clearColor];
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 10.0;
            paragraphStyle.paragraphSpacing = 10.0;
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            paragraphStyle.alignment = NSTextAlignmentCenter;
            NSMutableAttributedString *attributeString = [NSMutableAttributedString new];
            NSAttributedString *first = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%td", score]
                                                                        attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:96.0],
                                                                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                     NSParagraphStyleAttributeName: paragraphStyle
                                                                                     }];
            NSAttributedString *follow = [[NSAttributedString alloc] initWithString:@" 学分"
                                                                         attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:24.0],
                                                                                      NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                      NSParagraphStyleAttributeName: paragraphStyle
                                                                                      }];
            NSAttributedString *last = [[NSAttributedString alloc] initWithString:@"\n抢到学分红包啦"
                                                                       attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:24.0],
                                                                                    NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                    NSParagraphStyleAttributeName: paragraphStyle
                                                                                    }];
            [attributeString appendAttributedString:first];
            [attributeString appendAttributedString:follow];
            [attributeString appendAttributedString:last];
            label.attributedText = attributeString;
            label;
        });
        [imageView addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(imageView);
            make.centerY.equalTo(imageView.bjl_bottom).multipliedBy(0.38);
        }];
    }
    else {
        UIImageView *emoticonView = ({
            UIImageView *imageView = [UIImageView new];
            imageView.image = [UIImage bjl_imageNamed:@"bjl_ic_envelope_emoticon"];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView;
        });
        [imageView addSubview:emoticonView];
        [emoticonView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerY.equalTo(imageView.bjl_bottom).multipliedBy(0.326);
            make.centerX.equalTo(imageView);
            make.width.equalTo(@(136.0));
            make.height.equalTo(emoticonView.bjl_width);
        }];
        
        UILabel *label = ({
            UILabel *label = [UILabel new];
            label.backgroundColor = [UIColor clearColor];
            label.text = @"一个都没抢到～";
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:24.0];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        });
        [imageView addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(imageView);
            make.height.equalTo(@33.0).priorityHigh();
            make.top.equalTo(emoticonView.bjl_bottom).offset(11.0);
        }];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.scoreResultView) {
            // 存在代表未触发点击消失，此时自动消失
            [self makeEnvelopeRankResultViewAndConstraints];
        }
    });
}

- (void)reloadRankList {
    static NSInteger totalReloadTimes = 3;
    bjl_weakify(self);
    [self.room.roomVM requestRankListWithEnvelopeID:self.envelopeID completion:^(NSArray<BJLEnvelopeRank *> * _Nullable rankList, BJLError * _Nullable error) {
        bjl_strongify(self);
        if (!self) {
            return;
        }
        if (!error) {
            self.rankList = rankList;
            [self updateEmptyRankResultViewHidden:rankList.count];
            [self.resultTableView reloadData];
        }
        totalReloadTimes --;
        if (totalReloadTimes <= 0) {
            totalReloadTimes = 3;
        }
        else {
            // 各端可能不同时开始结束，排行榜显示后最多刷新2次，如果存在更慢的端也不处理
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self reloadRankList];
            });
        }
    }];
}

- (void)makeEnvelopeRankResultViewAndConstraints {
    [self.scoreResultView removeFromSuperview];
    self.scoreResultView = nil;
    
    self.envelopeResultView = ({
        UIView *view = [UIView new];
        view;
    });
    [self.view addSubview:self.envelopeResultView];
    [self.envelopeResultView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    UIImageView *envelopeResultImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.userInteractionEnabled = YES;
        imageView.image = [UIImage bjl_imageNamed:@"bjl_ic_envelope_result"];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView;
    });
    [self.envelopeResultView addSubview:envelopeResultImageView];
    [envelopeResultImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.envelopeResultView);
        make.width.height.lessThanOrEqualTo(self.view).multipliedBy(0.8);
        make.width.equalTo(@(envelopeResultImageView.image.size.width)).priorityHigh();
        make.height.equalTo(@(envelopeResultImageView.image.size.height)).priorityHigh();
        make.width.equalTo(envelopeResultImageView.bjl_height).multipliedBy(envelopeResultImageView.image.size.width / envelopeResultImageView.image.size.height);
    }];
    self.resultTableView = ({
        UITableView *tableView = [UITableView new];
        tableView.backgroundColor = [UIColor clearColor];
        tableView.showsVerticalScrollIndicator = NO;
        tableView.showsHorizontalScrollIndicator = NO;
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [tableView registerClass:[BJLEnvelopeResultCell class] forCellReuseIdentifier:BJLEnvelopeResultCellReuseIdentifier];
        tableView;
    });
    [envelopeResultImageView addSubview:self.resultTableView];
    [self.resultTableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(envelopeResultImageView.bjl_right).multipliedBy(0.13);
        make.right.equalTo(envelopeResultImageView.bjl_right).multipliedBy(0.81);
        make.height.equalTo(envelopeResultImageView.bjl_height).multipliedBy(0.458);
        make.top.equalTo(envelopeResultImageView.bjl_bottom).multipliedBy(0.394);
    }];
    self.emptyRankResultView = ({
        UIView *view = [UIView new];
        view.hidden = YES;
        view.backgroundColor = [UIColor whiteColor];
        UIImageView *emoticonView = ({
            UIImageView *imageView = [UIImageView new];
            imageView.image = [UIImage bjl_imageNamed:@"bjl_ic_envelope_emoticon"];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView;
        });
        [view addSubview:emoticonView];
        [emoticonView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(view.bjl_top);
            make.centerX.equalTo(view);
            make.height.equalTo(@(136.0)).priorityHigh();
            make.width.equalTo(emoticonView.bjl_height);
        }];
        
        UILabel *label = ({
            UILabel *label = [UILabel new];
            label.backgroundColor = [UIColor clearColor];
            label.text = @"没人抢到～";
            label.textColor = [UIColor blackColor];
            label.font = [UIFont systemFontOfSize:24.0];
            label.textAlignment = NSTextAlignmentCenter;
            label;
        });
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.equalTo(view);
            make.height.equalTo(@33.0).priorityHigh();
            make.top.equalTo(emoticonView.bjl_bottom);
        }];
        view;
    });
    [envelopeResultImageView addSubview:self.emptyRankResultView];
    [self.emptyRankResultView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.resultTableView);
    }];
    self.resultTableViewHeader = [self makeHeaderForRankTableView];
    [envelopeResultImageView addSubview:self.resultTableViewHeader];
    [self.resultTableViewHeader bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(self.resultTableView.bjl_top).offset(-13.0);
        make.height.equalTo(@20.0).priorityHigh();
        make.right.equalTo(self.resultTableView);
        make.left.equalTo(self.resultTableView).offset(2.0);
    }];
    self.closeButton = ({
        UIButton *button = [UIButton new];
        button.backgroundColor = [UIColor clearColor];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_envelope_close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [envelopeResultImageView addSubview:self.closeButton];
    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.width.height.equalTo(@44.0);
        make.right.top.equalTo(envelopeResultImageView);
    }];
    
    [self reloadRankList];
}

- (void)updateEmptyRankResultViewHidden:(BOOL)hidden {
    self.emptyRankResultView.hidden = hidden;
    self.resultTableViewHeader.hidden = !hidden;
}

- (void)hide {
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rankList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BJLEnvelopeResultCell *cell = [tableView dequeueReusableCellWithIdentifier:BJLEnvelopeResultCellReuseIdentifier forIndexPath:indexPath];
    BJLEnvelopeRank *rank;
    for (BJLEnvelopeRank *r in self.rankList) {
        if (r.rank == indexPath.row + 1) {
            rank = r;
            break;
        }
    }
    [cell configureWithRank:rank.rank
                   userName:[BJLUser displayNameOfName:rank.userName]
                      score:rank.score];
    return cell;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.frame.size.height / 5.0;
}

- (UIView *)makeHeaderForRankTableView {
    UIView *view = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view;
    });
    UILabel *rankLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:13.0];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"排名";
        label;
    });
    [view addSubview:rankLabel];
    [rankLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(view);
        make.top.bottom.equalTo(view);
    }];
    UILabel *userNameLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:13.0];
        label.textColor = [UIColor whiteColor];
        label.text = @"用户";
        label.textAlignment = NSTextAlignmentCenter;
        label;
    });
    [view addSubview:userNameLabel];
    [userNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(view);
        make.top.bottom.equalTo(view);
    }];
    UILabel *scoreLabel = ({
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:13.0];
        label.textColor = [UIColor whiteColor];
        label.text = @"金币";
        label.textAlignment = NSTextAlignmentRight;
        label;
    });
    [view addSubview:scoreLabel];
    [scoreLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.equalTo(view);
        make.top.bottom.equalTo(view);
    }];
    return view;
}

@end
