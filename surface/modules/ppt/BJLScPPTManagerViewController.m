//
//  BJLScPPTManagerViewController.m
//  BJLiveUI
//
//  Created by fanyi on 2019/9/18.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScPPTManagerViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "BJLScPPTUploadingTask.h"
#import "BJLScAppearance.h"
#import "BJLScPPTCell.h"
#import "BJLPlaceholderView.h"

typedef NS_ENUM(NSInteger, BJLScPPTSection) {
    BJLScPPTSection_document,
    BJLScPPTSection_uploading,
    _BJLScPPTSection_count
};

@interface BJLScPPTManagerViewController () <
UITableViewDataSource,
UITableViewDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
QBImagePickerControllerDelegate_iCloudLoading>

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, copy) NSArray<BJLDocument *> *allDocuments;
@property (nonatomic, readonly) NSMutableArray<BJLScPPTUploadingTask *> *uploadingTasks;

@property (nonatomic) UIView *topContainerView, *bottomContainerView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *editButton, *doneButton;
@property (nonatomic) BOOL interruptedRecordingVideo;

@end

@implementation BJLScPPTManagerViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self->_room = room;
        self->_uploadingTasks = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
           self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
#endif

    [self bjl_setUpCommonTableView];

    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    for (NSString *cellIdentifier in @[BJLScPPTCellIdentifier_uploading, BJLScPPTCellIdentifier_document]) {
        [self.tableView registerClass:[BJLScPPTCell class]
               forCellReuseIdentifier:cellIdentifier];
    }
    
    [self makeSubviews];
    [self makeActions];
    [self makeObserving];
}

#pragma mark -

- (void)makeSubviews {
    self.topContainerView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, topContainerView);
        [self.view addSubview:view];
        bjl_return view;
    });
    
    UIView *separatorLine = ({
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor bjlsc_grayLineColor];
        [self.topContainerView addSubview:line];
        bjl_return line;
    });
    
    self.titleLabel = ({
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:16.0];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = @"设置";
        label.textColor = [UIColor blackColor];
        label.accessibilityLabel = BJLKeypath(self, titleLabel);
        [self.topContainerView addSubview:label];
        bjl_return label;
    });
    
    self.bottomContainerView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, bottomContainerView);
        [self.view addSubview:view];
        bjl_return view;
    });

    [self.tableView bjl_removeAllConstraints];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.right.left.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.top.equalTo(self.topContainerView.bjl_bottom);
        make.bottom.equalTo(self.bottomContainerView.bjl_top);
    }];

    [self.bottomContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.height.equalTo(@(BJLScControlSize));
    }];

    [self.topContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.view.bjl_safeAreaLayoutGuide ?: self.view);
        make.height.equalTo(@(BJLScControlSize));
    }];
    
    [separatorLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.topContainerView);
        make.height.equalTo(@(BJLScOnePixel));
    }];
    
    [self.titleLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.topContainerView.bjl_safeAreaLayoutGuide ?: self.topContainerView).with.offset(BJLScViewSpaceL);
        make.top.bottom.equalTo(self.topContainerView.bjl_safeAreaLayoutGuide ?: self.topContainerView);
    }];

    self.editButton = ({
        UIButton *button = [BJLButton makeTextButtonDestructive:NO];
        NSString *title = @"编辑", *selectedTitle = @"取消";
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitle:title forState:UIControlStateNormal | UIControlStateHighlighted];
        [button setTitle:selectedTitle forState:UIControlStateSelected];
        [button setTitle:selectedTitle forState:UIControlStateSelected | UIControlStateHighlighted];
        [button setTitle:title forState:UIControlStateDisabled];
        [self.topContainerView addSubview:button];
        button;
    });
    
    [self.editButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.topContainerView);;
        make.right.equalTo(self.topContainerView.bjl_right).offset(- BJLScViewSpaceL);
        make.left.greaterThanOrEqualTo(self.titleLabel.bjl_right);
    }];
    
    self.doneButton = ({
        UIButton *button = [UIButton new];
        button.titleLabel.font = [UIFont systemFontOfSize:17.0];
        NSString *title = @"添加", *selectedTitle = @"移除";
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitle:title forState:UIControlStateNormal | UIControlStateHighlighted];
        [button setTitle:selectedTitle forState:UIControlStateSelected];
        [button setTitle:selectedTitle forState:UIControlStateSelected | UIControlStateHighlighted];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        UIImage *normalBackgroundImage = [UIImage bjl_imageWithColor:[UIColor bjlsc_blueBrandColor]];
        [button setBackgroundImage:normalBackgroundImage forState:UIControlStateNormal];
        [button setBackgroundImage:normalBackgroundImage forState:UIControlStateNormal | UIControlStateHighlighted];
        UIImage *selectedBackgroundImage = [UIImage bjl_imageWithColor:[UIColor bjlsc_redColor]];
        [button setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected];
        [button setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected | UIControlStateHighlighted];
        UIImage *disabledBackgroundImage = [UIImage bjl_imageWithColor:[UIColor bjlsc_grayBorderColor]];
        [button setBackgroundImage:disabledBackgroundImage forState:UIControlStateDisabled];
        [self.bottomContainerView addSubview:button];
        button;
    });
    [self.doneButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.bottomContainerView);
    }];
}

- (void)makeActions {
    bjl_weakify(self);
    
    [self.editButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        BOOL isEditing = self.tableView.editing;
        if (self.room.loginUser.isAssistant && ![self.room.roomVM getAssistantaAuthorityWithDocumentUpload] && !isEditing) {
            [self showProgressHUDWithText:@"文档权限已被禁用"];
            return ;
        }
        [self setTableViewEditing:!isEditing animated:YES];
    }];
    
    [self.doneButton bjl_addHandler:^(__kindof UIControl * _Nullable sender) {
        bjl_strongify(self);
        if (self.room.loginUser.isAssistant && ![self.room.roomVM getAssistantaAuthorityWithDocumentUpload]) {
            [self showProgressHUDWithText:@"文档权限已被禁用"];
            return ;
        }
        
        BOOL isEditing = self.tableView.editing;
        if (!isEditing) {
            [self chooseImagePickerSourceTypeFromButton:sender];
        }
        else {
            [self tryToRemoveSelectedRowsFromSender:sender];
        }
    }];
}

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.documentVM, allDocuments)
         observer:^BOOL(NSArray<BJLDocument *> * _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             NSMutableArray<BJLDocument *> *allDocuments = [now mutableCopy];
             for (BJLDocument *document in now) {
                 if (![document isSyncedWithServer] || [document isWhiteBoard]) {
                     [allDocuments removeObject:document];
                 }
             }
             self.allDocuments = allDocuments;
             [self.tableView reloadData];
             [self updateViewsForDataCount];
             return YES;
         }];
    
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didAddDocument:)
             observer:^(BJLDocument *document) {
                 bjl_strongify(self);
                 BJLScPPTUploadingTask *task = self.uploadingTasks.firstObject;
                 BOOL matched = (task
                                 && task.state == BJLUploadState_uploaded
                                 && [task.result.fileID isEqualToString:document.fileID]);
                 if (matched) {
                     [self.uploadingTasks removeObject:task];
                 }
                 // else added by other
                 [self.tableView reloadData];
                 [self updateViewsForDataCount];
                 if (matched) {
                     [self tryToAddFistDocument]; // next
                 }
                 return YES;
             }];
    
    /* called
    [self bjl_observe:BJLMakeMethod(self.room.BJLDocumentVM, didDeleteDocument:)
             observer:^(BJLDocument *document) {
                 bjl_strongify(self);
                 [self.tableView reloadData];
                 return YES;
             }]; */
}

- (void)updateViewsForDataCount {
    BOOL hasData = ({
        NSInteger numberOfRows = 0;
        for (NSInteger section = 0; section < self.tableView.numberOfSections; section++) {
            numberOfRows += [self.tableView numberOfRowsInSection:section];
        }
        numberOfRows > 0;
    });
    
    if (hasData) {
        [BJLPlaceholderView removeAllFromSuperview:self.view];
    }
    else {
        bjl_weakify(self);
        [BJLPlaceholderView showInSuperview:self.view
                                      image:[UIImage bjlsc_imageNamed:@"bjl_sc_ppt_empty"]
                                       text:@"课件都不给，上课全靠嘴？"
                                   tapBlock:^(BJLPlaceholderView * _Nonnull placeholder) {
                                       bjl_strongify(self);
                                       [self chooseImagePickerSourceTypeFromButton:self.doneButton];
                                   }];
    }

    self.editButton.enabled = hasData;
    if (!hasData && self.tableView.editing) {
        [self setTableViewEditing:NO animated:YES];
    }
}

- (void)tryToRemoveSelectedRowsFromSender:(nullable UIControl *)sender {
    __block NSArray<NSIndexPath *> * indexPaths = [self.tableView indexPathsForSelectedRows];
    bjl_weakify(self);
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:indexPaths.count ? @"你确定要移除课件吗？" : @"你确定要移除全部课件吗？"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    [alert bjl_addActionWithTitle:@"确定"
                            style:UIAlertActionStyleDestructive
                          handler:^(UIAlertAction * _Nonnull action) {
                              bjl_strongify(self);
                              [self deleteRowsAtIndexPaths:indexPaths.count ? indexPaths : ({
                                  NSMutableArray<NSIndexPath *> *allIndexPaths = [NSMutableArray new];
                                  NSInteger numberOfSections = [self.tableView numberOfSections];
                                  for (NSInteger section = 0; section < numberOfSections; section++) {
                                      NSInteger numberOfRows = [self.tableView numberOfRowsInSection:section];
                                      for (NSInteger row = 0; row < numberOfRows; row++) {
                                          [allIndexPaths bjl_addObject:[NSIndexPath indexPathForRow:row inSection:section]];
                                      }
                                  }
                                  allIndexPaths;
                              })];
                          }];
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    
    alert.popoverPresentationController.sourceView = sender;
    alert.popoverPresentationController.sourceRect = sender.bounds;
    alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableArray<NSString *> *documentIDs = [NSMutableArray new];
    NSMutableIndexSet *taskIndices = [NSMutableIndexSet new];
    NSMutableArray<NSIndexPath *> *taskIndexPaths = [NSMutableArray new];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.section == BJLScPPTSection_document) {
            BJLDocument *document = [self.allDocuments bjl_objectAtIndex:indexPath.row];
            [documentIDs bjl_addObject:document.documentID];
        }
        else { // if (indexPath.section == BJLScPPTSection_uploading)
            BJLScPPTUploadingTask *task = [self.uploadingTasks bjl_objectAtIndex:indexPath.row];
            [task cancel];
            [taskIndices addIndex:indexPath.row];
            [taskIndexPaths bjl_addObject:indexPath];
        }
    }
    
    [self.uploadingTasks removeObjectsAtIndexes:taskIndices];
    [self.tableView deleteRowsAtIndexPaths:taskIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    for (NSString *documentID in documentIDs) {
        BJLError *error = [self.room.documentVM deleteDocumentWithID:documentID];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }
    
    [self setTableViewEditing:NO animated:YES];
}

- (void)updateDoneButtonWhileEditing {
    if (!self.tableView.editing) {
        return;
    }
    NSArray<NSIndexPath *> *indexPaths = [self.tableView indexPathsForSelectedRows];
    [self.doneButton setTitle:indexPaths.count > 0 ? @"移除" : @"移除全部" forState:UIControlStateSelected];
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    self.editButton.selected = editing;
    self.doneButton.selected = editing;
    [self.tableView setEditing:editing animated:animated];
    
    if (editing) {
        [self updateDoneButtonWhileEditing];
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _BJLScPPTSection_count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == BJLScPPTSection_document) {
        return self.allDocuments.count;
    }
    if (section == BJLScPPTSection_uploading) {
        return self.uploadingTasks.count;
    }
    return 0;
}

#pragma mark - <UITableViewDelegate>

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = nil;
    if (indexPath.section == BJLScPPTSection_document) {
        cellIdentifier = BJLScPPTCellIdentifier_document;
    }
    else { // if (indexPath.section == BJLScPPTSection_uploading)
        cellIdentifier = BJLScPPTCellIdentifier_uploading;
    }
    
    BJLScPPTCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == BJLScPPTSection_document) {
        BJLDocument *document = [self.allDocuments bjl_objectAtIndex:indexPath.row];
        [cell updateWithDocument:document];
    }
    else { // if (indexPath.section == BJLScPPTSection_uploading)
        BJLScPPTUploadingTask *task = [self.uploadingTasks bjl_objectAtIndex:indexPath.row];
        [cell updateWithUploadingTask:task];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isEditing = self.tableView.editing;
    if (isEditing) {
        [self updateDoneButtonWhileEditing];
        return;
    }
    
    if (indexPath.section != BJLScPPTSection_uploading) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    BJLScPPTUploadingTask *task = [self.uploadingTasks bjl_objectAtIndex:indexPath.row];
    if (task.state == BJLUploadState_waiting) {
        [task upload];
    }
    else if (task.state == BJLUploadState_uploaded) {
        if (indexPath.row == 0) {
            if (!bjl_isRobot(BJLWebSocketTimeoutInterval)) {
                [self tryToAddFistDocument]; // retry current
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == BJLScPPTSection_document) {
        BJLDocument *document = [self.allDocuments bjl_objectAtIndex:indexPath.row];
        BJLError *error = [self.room.documentVM deleteDocumentWithID:document.documentID];
        if (error) {
            [self showProgressHUDWithText:error.localizedFailureReason ?: error.localizedDescription];
        }
    }
    else { // if (indexPath.section == BJLScPPTSection_uploading)
        BJLScPPTUploadingTask *task = [self.uploadingTasks bjl_objectAtIndex:indexPath.row];
        
        [self stopObservingUploadingTask:task];
        [task cancel];
        
        [self.uploadingTasks bjl_removeObjectAtIndex:indexPath.row];
        [self.tableView reloadData];
        [self updateViewsForDataCount];
        
        if (indexPath.row == 0) {
            [self tryToAddFistDocument]; // next
        }
    }
}

#pragma mark - image uploading

- (void)uploadImageWithUploadingTask:(BJLScPPTUploadingTask *)task {
    [self.uploadingTasks addObject:task];
    [self.tableView reloadData];
    [self updateViewsForDataCount];
    
    [self startObservingUploadingTask:task];
    [task upload];
}

- (void)startAllUploadingTasks {
    for (BJLScPPTUploadingTask *task in self.uploadingTasks) {
        if (task.state == BJLUploadState_waiting) {
            [task cancel];
            [task upload];
        }
    }
}

- (void)startObservingUploadingTask:(BJLScPPTUploadingTask *)task {
    bjl_weakify(self, task);
    
    [self bjl_kvo:BJLMakeProperty(task, state)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self, task);
             NSIndexPath *indexPath = [self updateCellForUploadingTask:task];
             if (indexPath.row == 0 && task.state == BJLUploadState_uploaded) {
                 [self tryToAddFistDocument];
             }
             if (task.state == BJLUploadState_uploaded
                 || (task.state == BJLUploadState_waiting && task.error)) {
                 BOOL anyUploading = NO;
                 NSInteger failedCount = 0;
                 for (BJLScPPTUploadingTask *task in self.uploadingTasks) {
                     if (task.state == BJLUploadState_uploading
                         || (task.state == BJLUploadState_waiting && !task.error)) {
                         anyUploading = YES;
                         break;
                     }
                     else if (task.state == BJLUploadState_waiting && task.error) {
                         failedCount++;
                     }
                 }
                 if (!anyUploading) {
                     if (self.uploadingCallback) self.uploadingCallback(failedCount, failedCount > 0 ? ^{
                         bjl_strongify(self);
                         [self startAllUploadingTasks];
                     } : nil);
                 }
             }
             return YES;
         }];
    
    [self bjl_kvo:BJLMakeProperty(task, progress)
         observer:^BOOL(id _Nullable now, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self, task);
             [self updateCellForUploadingTask:task];
             return YES;
         }];
}

- (void)stopObservingUploadingTask:(BJLScPPTUploadingTask *)task {
    [self bjl_stopAllKeyValueObservingOfTarget:task];
    [self bjl_stopAllMethodParametersObservingOfTarget:task];
}

- (nullable NSIndexPath *)updateCellForUploadingTask:(BJLScPPTUploadingTask *)task {
    NSUInteger index = [self.uploadingTasks indexOfObject:task];
    if (index == NSNotFound) {
        return nil;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:BJLScPPTSection_uploading];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
    return indexPath;
}

- (void)tryToAddFistDocument {
    BJLScPPTUploadingTask *task = self.uploadingTasks.firstObject;
    if (task && task.state == BJLUploadState_uploaded) {
        [self.room.documentVM addDocument:task.result];
    }
}

#pragma mark - image

- (void)chooseImagePickerSourceTypeFromButton:(UIButton *)button {
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:button.currentTitle ?: @"上传课件"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    bjl_weakify(self);
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [alert bjl_addActionWithTitle:@"拍照"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                  bjl_strongify(self);
                                  [self chooseImageWithSourceType:sourceType];
                              }];
    }
    
    sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [alert bjl_addActionWithTitle:@"从相册中选取"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                  bjl_strongify(self);
                                  [self chooseImageWithSourceType:sourceType];
                              }];
    }
    
    [alert bjl_addActionWithTitle:@"取消"
                            style:UIAlertActionStyleCancel
                          handler:nil];
    
    alert.popoverPresentationController.sourceView = button;
    alert.popoverPresentationController.sourceRect = button.bounds;
    alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)chooseImageWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        [BJLAuthorization checkCameraAccessAndRequest:YES callback:^(BOOL granted, UIAlertController * _Nullable alert) {
            if (granted) {
                [self chooseImageWithCamera];
            }
            else if (alert) {
                if (self.presentedViewController) {
                    [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                }
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
    else {
        [BJLAuthorization checkPhotosAccessAndRequest:YES callback:^(BOOL granted, UIAlertController * _Nullable alert) {
            if (granted) {
                [self chooseImageWithFromPhotoLibrary];
            }
            else if (alert) {
                if (self.presentedViewController) {
                    [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
                }
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
}

#pragma mark - UIImagePickerController

- (void)chooseImageWithCamera {
    self.interruptedRecordingVideo = self.room.recordingVM.recordingVideo;
    if (self.interruptedRecordingVideo) {
        [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingAudio
                                  recordingVideo:NO];
    }
    
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
    imagePickerController.allowsEditing = NO;
    imagePickerController.delegate = self;
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        imagePickerController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
#endif
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self bjl_presentFullScreenViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - <UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.interruptedRecordingVideo) {
            [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingVideo
                                      recordingVideo:YES];
            self.interruptedRecordingVideo = NO;
        }
        
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSString *mediaType = info[UIImagePickerControllerMediaType];
        NSError *error = nil;
        ICLImageFile *imageFile = [ICLImageFile imageFileWithImage:image thumbnail:nil mediaType:mediaType error:&error];
        if (!imageFile) {
            [self showProgressHUDWithText:@"照片获取出错"];
            return;
        }
        
        BJLScPPTUploadingTask *task = [BJLScPPTUploadingTask uploadingTaskWithImageFile:imageFile room:self.room];
        [self uploadImageWithUploadingTask:task];
    
        /*
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }); // */
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.interruptedRecordingVideo) {
            [self.room.recordingVM setRecordingAudio:self.room.recordingVM.recordingVideo
                                      recordingVideo:YES];
            self.interruptedRecordingVideo = NO;
        }
    }];
}

#pragma mark - QBImagePickerController

- (void)chooseImageWithFromPhotoLibrary {
    QBImagePickerController *imagePickerController = [QBImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.mediaType = QBImagePickerMediaTypeImage;
    imagePickerController.allowsMultipleSelection = YES;
    imagePickerController.showsNumberOfSelectedAssets = YES;
    imagePickerController.maximumNumberOfSelection = 20;
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        imagePickerController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
#endif
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self bjl_presentFullScreenViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - <QBImagePickerControllerDelegate>

- (void)qb_imagePickerController:(QBImagePickerController *)picker didFinishPickingAssets:(NSArray<PHAsset *> *)assets {
    NSLog(@"picked assets: %@", assets);
    [picker icl_loadImageFilesWithAssets:assets
                             contentMode:PHImageContentModeAspectFit
                              targetSize:CGSizeMake(BJLAliIMGMaxSize, BJLAliIMGMaxSize)
                           thumbnailSize:CGSizeZero]; // [UIScreen mainScreen].bounds.size]
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)picker {
    NSLog(@"picking cancelled");
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <QBImagePickerControllerDelegate_iCloudLoading>

- (void)icl_imagePickerController:(QBImagePickerController *)picker
       didFinishLoadingImageFiles:(NSArray<ICLImageFile *> *)imageFiles {
    NSLog(@"loaded imageFiles: %@", imageFiles);
    [picker dismissViewControllerAnimated:YES completion:^{
        for (ICLImageFile *imageFile in imageFiles) {
            BJLScPPTUploadingTask *task = [BJLScPPTUploadingTask uploadingTaskWithImageFile:imageFile room:self.room];
            [self uploadImageWithUploadingTask:task];
        }
    }];
}

- (void)icl_imagePickerControllerDidCancelLoadingImageFiles:(QBImagePickerController *)picker {
    NSLog(@"loading cancelled");
    // [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)icl_imagePickerController:(QBImagePickerController *)picker
        didFinishLoadingImageFile:(ICLImageFile *)imageFile {
    NSLog(@"loaded imageFile: %@", imageFile);
}

@end
