//
//  BJLScToolView.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScToolView.h"
#import "BJLScAppearance.h"

@interface BJLScToolView ()

@property (nonatomic, weak) BJLRoom *room;

@property (nonatomic) UIButton *paintBrushButton, *eraserButton, *coursewareButton, *countDownButton;

@end

@implementation BJLScToolView

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super initWithFrame:CGRectZero]) {
        self.room = room;
        [self makeSubviews];
        [self remakeConstraints];
        [self makeObserving];
    }
    return self;
}

- (void)makeObserving {
    bjl_weakify(self);
    BJLPropertyFilter ifIntegerChanged = ^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
        // bjl_strongify(self);
        return now.bjl_integerValue != old.bjl_integerValue;
    };
    
    [self bjl_kvo:BJLMakeProperty(self.room, loadingVM)
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        [self updateButtonStates];
        return YES;
    }];

    [self bjl_kvo:BJLMakeProperty(self.room, state)
           filter:ifIntegerChanged
         observer:^BJLControlObserving(id  _Nullable value, id  _Nullable oldValue, BJLPropertyChange * _Nullable change) {
        bjl_strongify(self);
        if (self.room.state == BJLRoomState_connected) {
            [self remakeConstraints];
        }
        return YES;
    }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingGranted)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateButtonStates];
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(self.room.drawingVM, drawingEnabled)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateButtonStates];
             return YES;
         }];

    [self bjl_kvo:BJLMakeProperty(self.room.speakingRequestVM, speakingEnabled)
          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
           filter:ifIntegerChanged
         observer:^BOOL(NSNumber * _Nullable now, NSNumber * _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateButtonStates];
             return YES;
         }];
}

- (void)makeSubviews {
    self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    self.layer.cornerRadius = 8.0;
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.3;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.layer.shadowRadius = 2.0;
    
    self.paintBrushButton = [self makeButtonWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_paintbrush_normal"] seletedImage:[UIImage bjlsc_imageNamed:@"bjl_sc_paintbrush_selected"] action:@selector(updateDrawingEnabled:)];
    self.eraserButton = [self makeButtonWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_eraser_selected"] seletedImage:[UIImage bjlsc_imageNamed:@"bjl_sc_eraser_selected"] action:@selector(updateEraserEnabled:)];
    self.coursewareButton = [self makeButtonWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_courseware"] seletedImage:nil action:@selector(showCourseware)];
    self.countDownButton = [self makeButtonWithImage:[UIImage bjlsc_imageNamed:@"bjl_sc_timer"] seletedImage:nil action:@selector(showCountDown)];
}

- (void)remakeConstraints {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);

    NSArray<UIView *> *views = @[self.paintBrushButton, self.eraserButton];
    
    if (self.room.loginUser.isTeacher) {
        views = @[self.paintBrushButton, self.eraserButton, self.coursewareButton, self.countDownButton];
    }
    else if (self.room.loginUser.isAssistant) {
        views = @[self.paintBrushButton, self.eraserButton, self.coursewareButton];
    }

    UIView *last = nil;
    for (UIView *view in views) {
        [self addSubview:view];
        if (iPhone) {
            [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                if (last) {
                    make.top.equalTo(last.bjl_bottom).offset(8.0);
                    make.centerX.width.height.equalTo(last);
                }
                else {
                    make.top.equalTo(self).offset(8.0);
                    make.left.right.equalTo(self);
                    make.height.equalTo(view.bjl_width).priorityHigh();
                }
            }];
        }
        else {
            [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                if (last) {
                    make.left.equalTo(last.bjl_right).offset(8.0);
                    make.centerY.width.height.equalTo(last);
                }
                else {
                    make.left.equalTo(self).offset(8.0);
                    make.top.bottom.equalTo(self);
                    make.width.equalTo(view.bjl_height);
                }
            }];
        }
        last = view;
    }
    if (self.remakeConstraintsCallback) {
        self.remakeConstraintsCallback();
    }
}

- (CGSize)expectedSize {
    BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    NSInteger toolCount = self.room.loginUser.isTeacher ? 4 : (self.room.loginUser.isAssistant ? 3 : 2);
    if (iPhone) {
        return CGSizeMake(44.0, toolCount * 44.0 + (toolCount + 1) * 8.0);
    }
    else {
        return CGSizeMake(toolCount * 44.0 + (toolCount + 1) * 8.0, 44.0);
    }
}

#pragma mark - action

- (void)updateDrawingEnabled:(UIButton *)button {
    if (self.penCallback) {
        self.penCallback();
    }
}

- (void)updateEraserEnabled:(UIButton *)button {
    if (self.clearDrawingCallback) {
        self.clearDrawingCallback();
    }
}

- (void)showCourseware {
    if (self.showCoursewareCallback) {
        self.showCoursewareCallback();
    }
}

- (void)showCountDown {
    if (self.openCountDownCallback) {
        self.openCountDownCallback();
    }
}

#pragma mark - brush

- (void)updateButtonStates {
    BOOL is1toN = self.room.roomInfo.roomType == BJLRoomType_1vNClass;
    BOOL drawingEnabled = self.room.drawingVM.drawingEnabled;
    // 大班课未上麦和授权画笔的学生，试听用户，加载状态隐藏画笔工具
    BOOL hidden = (is1toN && !self.room.loginUser.isTeacherOrAssistant && !(self.room.speakingRequestVM.speakingEnabled && self.room.drawingVM.drawingGranted)) || self.room.loginUser.isAudition || self.room.loadingVM;
    self.paintBrushButton.selected = drawingEnabled;
    if (self.hiddenCallback) {
        self.hiddenCallback(hidden);
    }
}

- (UIButton *)makeButtonWithImage:(UIImage *)image seletedImage:(UIImage *)selectedImage action:(SEL)seletor {
    UIButton *button = [UIButton new];
    button.backgroundColor = [UIColor clearColor];
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    if (selectedImage) {
        [button setImage:selectedImage forState:UIControlStateSelected];
        [button setImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
    }
    [button addTarget:self action:seletor forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end
