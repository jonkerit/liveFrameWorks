//
//  BJLIcDrawTextOptionView.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/11/12.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/NSObject+BJLObserving.h>
#import <BJLiveBase/BJL_EXTScope.h>
#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcDrawTextOptionView.h"
#import "BJLIcTextFontTableViewCell.h"

static CGFloat const buttonSpacing = 6.0;
static CGFloat const buttonSize = 32.0;
static CGFloat const cellSize = 46.0;

static NSString * const cellReuseIdentifier = @"textFontCell";

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDrawTextOptionView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) BJLIcRectPosition position;

@property (nonatomic) UIView *textOptionView;
@property (nonatomic) UIView *fontOptionView;
@property (nonatomic) UIButton *upButton;
@property (nonatomic) UIButton *downButton;
@property (nonatomic) UITableView *textFontsView;
@property (nonatomic) UIButton *boldButton;
@property (nonatomic) UIButton *italicButton;
@property (nonatomic) UIButton *fontButton;

@property (nonatomic) NSArray *textFonts;

@end

@implementation BJLIcDrawTextOptionView

- (void)dealloc {
    self.textFontsView.dataSource = nil;
    self.textFontsView.delegate = nil;
}

- (instancetype)initWithRoom:(id)room{
    self = [super init];
    if (self) {
        self->_room = room;
        self.position = BJLIcRectPosition_all;
        [self setupSubviews];
        [self setupObservers];
    }
    return self;
}

#pragma mark - subviews

- (void)setupSubviews {
    bjl_weakify(self);
    // text 选项视图
    self.textOptionView = [self createVisualEffectView];
    [self addSubview:self.textOptionView];
    // 粗体按钮
    self.boldButton = [self createButtonWithImageKey:@"bold" isBackgroundImage:NO handler:^(UIButton *button) {
        bjl_strongify(self);
        self.room.drawingVM.textBold = !button.selected;
    }];
    [self.textOptionView addSubview:self.boldButton];
    // 斜体按钮
    self.italicButton = [self createButtonWithImageKey:@"italic" isBackgroundImage:NO handler:^(UIButton *button) {
        bjl_strongify(self);
        self.room.drawingVM.textItalic = !button.selected;
    }];
    [self.textOptionView addSubview:self.italicButton];
    // 字体按钮
    self.fontButton = [self createButtonWithImageKey:@"font_bg" isBackgroundImage:YES handler:^(UIButton *button) {
        bjl_strongify(self);
        button.selected = !button.selected;
        self.fontOptionView.hidden = !button.selected;
    }];
    [self.textOptionView addSubview:self.fontButton];
    // 字体选择视图
    self.fontOptionView = [self createVisualEffectView];
    self.fontOptionView.hidden = YES;
    [self addSubview:self.fontOptionView];
    // up、down button
    self.upButton = [self createButtonWithImageKey:@"font_upside" isBackgroundImage:NO handler:^(UIButton *button) {
        bjl_strongify(self);
        self.textFontsView.contentOffset = bjl_set(self.textFontsView.contentOffset, {
            set.y -= cellSize * 4;
            set.y = MAX(set.y, 0.0);
        });
    }];
    [self.fontOptionView addSubview:self.upButton];
    self.downButton = [self createButtonWithImageKey:@"font_downside" isBackgroundImage:NO handler:^(UIButton *button) {
        bjl_strongify(self);
        self.textFontsView.contentOffset = bjl_set(self.textFontsView.contentOffset, {
            set.y += cellSize * 4;
            set.y = MIN(set.y, self.textFontsView.contentSize.height - cellSize);
        });
    }];
    [self.fontOptionView addSubview:self.downButton];
    // text fonts
    self.textFontsView = ({
        UITableView *view = [[UITableView alloc] init];
        view.backgroundColor = [UIColor clearColor];
        view.separatorStyle = UITableViewCellSeparatorStyleNone;
        view.rowHeight = cellSize;
        view.showsVerticalScrollIndicator = NO;
        view.showsHorizontalScrollIndicator = NO;
        view.clipsToBounds = YES;
        view.dataSource = self;
        view.delegate = self;
        [view registerClass:[BJLIcTextFontTableViewCell class] forCellReuseIdentifier:cellReuseIdentifier];
        bjl_return view;
    });
    [self.fontOptionView addSubview:self.textFontsView];
    [self remarkConstraintsWithPosition:BJLIcRectPosition_left];
    [self makeConstraints];
}

- (void)makeConstraints {
    [self.boldButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.equalTo(self.textOptionView).offset(buttonSpacing);
        make.right.equalTo(self.textOptionView).offset(-buttonSpacing);
        make.size.equal.sizeOffset(CGSizeMake(buttonSize, buttonSize));
    }];
    
    [self.italicButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.boldButton);
        make.top.equalTo(self.boldButton.bjl_bottom).offset(buttonSpacing);
        make.size.equal.sizeOffset(CGSizeMake(buttonSize, buttonSize));
    }];
    
    [self.fontButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.boldButton);
        make.top.equalTo(self.italicButton.bjl_bottom).offset(buttonSpacing);
        make.size.equal.sizeOffset(CGSizeMake(buttonSize, buttonSize));
    }];
    
    [self.upButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.fontOptionView);
        make.height.equalTo(@15.0);
    }];
    
    [self.downButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.bottom.right.equalTo(self.fontOptionView);
        make.height.equalTo(@15.0);
    }];
    
    [self.textFontsView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.fontOptionView);
        make.top.equalTo(self.upButton.bjl_bottom);
        make.bottom.equalTo(self.downButton.bjl_top);
    }];
}

// position 是视图相对于 toolbox 的位置
- (void)remarkConstraintsWithPosition:(BJLIcRectPosition)position {
    if (self.position == position) {
        return;
    }
    switch (position) {
        // 显示在左边或下边
        case BJLIcRectPosition_left:
        case BJLIcRectPosition_bottom: {
            [self.textOptionView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.top.right.equalTo(self);
                make.size.equal.sizeOffset(CGSizeMake(buttonSize + buttonSpacing * 2,
                                                      buttonSize * 3 + buttonSpacing * 4));
            }];
            [self.fontOptionView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.textOptionView.bjl_left).offset(-1.0);
                make.top.equalTo(self).offset(50.0);
                make.size.equal.sizeOffset(CGSizeMake(cellSize, cellSize * 4 + 30.0));
            }];
        }
            break;
            
        // 显示在右边
        case BJLIcRectPosition_right: {
            [self.textOptionView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.top.left.equalTo(self);
                make.size.equal.sizeOffset(CGSizeMake(buttonSize + buttonSpacing * 2,
                                                      buttonSize * 3 + buttonSpacing * 4));
            }];
            [self.fontOptionView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.left.equalTo(self.textOptionView.bjl_right).offset(1.0);
                make.top.equalTo(self).offset(50.0);
                make.size.equal.sizeOffset(CGSizeMake(cellSize, cellSize * 4 + 30.0));
            }];
        }
            break;
            
        // 显示在上边
        case BJLIcRectPosition_top: {
            [self.textOptionView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
                make.bottom.right.equalTo(self);
                make.size.equal.sizeOffset(CGSizeMake(buttonSize + buttonSpacing * 2,
                                                      buttonSize * 3 + buttonSpacing * 4));
            }];
            [self.fontOptionView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.right.equalTo(self.textOptionView.bjl_left).offset(-1.0);
                make.top.equalTo(self).offset(50.0);
                make.size.equal.sizeOffset(CGSizeMake(cellSize, cellSize * 4 + 30.0));
            }];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - observers

- (void)setupObservers {
    if (!self.room) {
        return;
    }
    
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, textBold)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.boldButton.selected = now.boolValue;
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, textItalic)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.boolValue != old.boolValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             self.italicButton.selected = now.boolValue;
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, textFontSize)
           filter:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
               // bjl_strongify(self);
               return now.doubleValue != old.doubleValue;
           }
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self.fontButton setTitle:[NSString stringWithFormat:@"%.f", now.doubleValue] forState:UIControlStateNormal];
             [self.textFontsView reloadData];
             return YES;
         }];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.textFonts.count;
}

#pragma mark - <UITableViewDelegate>

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger fontSize = [[self.textFonts bjl_objectAtIndex:indexPath.row] bjl_integerValue];
    BJLIcTextFontTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    BOOL selected = (fabs(self.room.drawingVM.textFontSize - fontSize) < FLT_MIN);
    [cell updateContentWithFont:fontSize selected:selected];
    bjl_weakify(self);
    [cell setSelectCallback:^(BOOL selected) {
        bjl_strongify(self);
        if (selected) {
            self.room.drawingVM.textFontSize = fontSize;
        }
    }];
    return cell;
}

#pragma mark - getters

- (NSArray *)textFonts {
    if (!_textFonts) {
        _textFonts = @[@12, @14, @16, @18, @20, @22, @24, @26, @28, @30, @40, @80];
    }
    return _textFonts;
}

- (CGSize)fitableSize {
    return CGSizeMake(buttonSize + buttonSpacing * 3 + cellSize,
                      buttonSize * 2 + buttonSpacing * 2 + cellSize * 4 + 5);
}

#pragma mark - private

- (UIView *)createVisualEffectView {
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.layer.masksToBounds = YES;
    effectView.layer.cornerRadius = 6.0;
    effectView.layer.borderWidth = 1.0;
    effectView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    view.layer.masksToBounds = NO;
    view.layer.shadowOpacity = 0.2;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    view.layer.shadowRadius = 10.0;
    [view addSubview:effectView];
    [effectView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(view);
    }];
    return view;
}

- (UIButton *)createButtonWithImageKey:(NSString *)imageKey isBackgroundImage:(BOOL)isBackgroundImage handler:(void (^)(UIButton *button))handler {
    NSString *imageName = [NSString stringWithFormat:@"bjl_toolbox_draw_text_%@", imageKey];
    UIImage *image = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"%@_normal", imageName]];
    UIImage *selectedImage = [UIImage bjlic_imageNamed:[NSString stringWithFormat:@"%@_selected", imageName]];
    
    UIButton *button = [[UIButton alloc] init];
    button.titleLabel.font = [UIFont systemFontOfSize:20.0];
    [button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.7] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    if (isBackgroundImage) {
        [button setBackgroundImage:image forState:UIControlStateNormal];
        [button setBackgroundImage:selectedImage forState:UIControlStateSelected];
    }
    else {
        [button setImage:image forState:UIControlStateNormal];
        [button setImage:selectedImage forState:UIControlStateSelected];
    }
    [button bjl_addHandler:handler];
    return button;
}

@end

NS_ASSUME_NONNULL_END
