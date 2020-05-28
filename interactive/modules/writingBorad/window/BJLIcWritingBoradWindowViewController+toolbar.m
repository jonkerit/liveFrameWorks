//
//  BJLIcWritingBoradWindowViewController+toolbar.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/20.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJLAuthorization.h>
#import <Photos/Photos.h>

#import "BJLIcWritingBoradWindowViewController+toolbar.h"
#import "BJLIcWritingBoradWindowViewController+protected.h"
#import "BJLIcWindowViewController+protected.h"

//#import "BJL_iCloudLoading.h"
//#import "BJLIcDocumentFile.h"

@implementation BJLIcWritingBoradWindowViewController (toolbar)

- (void)addGestureForToolBar {
    NSMutableArray *viewArray = [NSMutableArray arrayWithCapacity:2];
    if(self.topBar.backgroundView) {
        [viewArray addObject:self.topBar.backgroundView];
    }
    if(self.bottomBar.backgroundView) {
        [viewArray addObject:self.bottomBar.backgroundView];
    }
}

- (void)setupBoardToolBar {
    [self bjl_addChildViewController:self.bottomToolBarViewController superview:self.bottomBar];
    [self.bottomToolBarViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomBar);
    }];
    
    bjl_weakify(self);
    [self.bottomToolBarViewController.publishButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:1];
        NSString *durationString = [self.bottomToolBarViewController restrictTime];
        [self publishWithOperate:BJLWritingBoardPublishOperate_begin restrictionTimeString:durationString];
    }];
    
//    [self.bottomToolBarViewController.pictureButton bjl_addHandler:^(UIButton * _Nonnull button) {
//        bjl_strongify(self);
//        [self choosePic:button];
//    }];
    
    [self.bottomToolBarViewController.clearButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self askToClearWritingBoard];
    }];
    
    [self.bottomToolBarViewController.nextPageButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self nextPage];
    }];
    
    [self.bottomToolBarViewController.prevPageButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self prevPage];
    }];
    
    [self.bottomToolBarViewController.revokeButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self askToRevokeWritingBoard];
    }];
    
    [self.bottomToolBarViewController.gatherButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:1];
        [self publishWithOperate:BJLWritingBoardPublishOperate_end restrictionTimeString:@"0"];
    }];
    
    [self.bottomToolBarViewController.submitButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self submitBoard];
    }];
    
    //分享窗口的底部关闭按钮
    [self.bottomToolBarViewController.closeButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self closeWritingBoard];
    }];
    
    [self.bottomToolBarViewController.reEditButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [self reedit];
    }];

    [self.bottomToolBarViewController.rePublishButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        [button bjl_disableForSeconds:1];
        [self publishWithOperate:BJLWritingBoardPublishOperate_begin restrictionTimeString:@"0"];
    }];
    
    [self.bottomToolBarViewController.restrictTimeButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        if(self.showTimeInputCallBack) {
            self.showTimeInputCallBack();
        }
    }];

    [self.bottomToolBarViewController.showNickNameButton bjl_addHandler:^(UIButton * _Nonnull button) {
        bjl_strongify(self);
        self.bottomToolBarViewController.showNickNameButton.selected = !self.bottomToolBarViewController.showNickNameButton.selected;
        
        BOOL selected = self.bottomToolBarViewController.showNickNameButton.selected;
        
        BJLUser *currentUser = nil;
        BJLUserGroup *group = nil;
        if(selected) {
            if([self.userNumber isEqualToString:BJLWritingboardUserNumberForTeacher]) {
                //说明当前被分享的是老师
                currentUser = self.room.onlineUsersVM.onlineTeacher;
            }
            else {
                for(BJLUser *user in self.room.documentVM.allWritingBoardParticipatedUsers) {
                    if([user.number isEqualToString:self.userNumber]) {
                        currentUser = user;
                    }
                }
            }
            
            NSInteger groupID = 0;
            if (currentUser) {
                for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
                    if ([user.number isEqualToString:currentUser.number]) {
                        groupID = user.groupID;
                        break;
                    }
                }
                for (BJLUserGroup *groupItem in self.room.onlineUsersVM.groupList) {
                    if (groupID == groupItem.groupID) {
                        group = groupItem;
                        break;
                    }
                }
            }
        }

        NSString *name = selected ? currentUser.displayName : nil;
        [self updateCaptionWithName:name groupInfo:group];
        self.writingBoard.userName = name;
        
        if(self.teacherwillRenameWritingBoardCallback) {
            self.teacherwillRenameWritingBoardCallback(self.writingBoard, self.userNumber, name, self.relativeRect);
        }
    }];
}

- (void)setupBoardTopToolBar {
    bjl_weakify(self);
    
    self.topToolBarViewController.screenShotCallback = ^() {
        bjl_strongify(self);
        [self takeSnapShot];
    };
        
    self.topToolBarViewController.shareBoardCallback = ^() {
        bjl_strongify(self);
        [self share];
    };
    
    [self bjl_addChildViewController:self.topToolBarViewController superview:self.popoversLayer];
    [self.topToolBarViewController.view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.right.equalTo(self.popoversLayer);
        make.left.equalTo(self.userListButton.bjl_right);
        make.height.equalTo(@(32.0));
    }];
    self.topToolBarViewController.view.hidden = YES;
}

#pragma mark - action
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *message = error ? [NSString stringWithFormat:@"保存图片出错: %@", [error localizedDescription]] : @"图片已保存";
    [self.promptViewController enqueueWithPrompt:message];
}

- (void)takeSnapShot {
    [BJLAuthorization checkPhotosAccessAndRequest:YES callback:^(BOOL granted, UIAlertController * _Nullable alert) {
        if (granted) {
            UIGraphicsBeginImageContextWithOptions(self.collectionView.bounds.size, NO, [UIScreen mainScreen].scale);
            [self.collectionView drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
            UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            UIImageWriteToSavedPhotosAlbum(snapshotImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
        else if (alert) {
            if (self.presentedViewController) {
                [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
            }
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)prevPage {
    if(![self isValidStatusForUserListAndToolBar]) {
        return;
    }
    
    if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_loginUser) {
        return;
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_activeUser) {
        NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row - 1 inSection:self.currentIndexPath.section];
        if(![self isValidIndexPathInCollectionView:preIndexPath]) {
            NSIndexPath *preSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_loginUser];
            if(![self isValidIndexPathInCollectionView:preSectionIndexPath]) {
                return;
            }
            else {
                self.currentIndexPath = preSectionIndexPath;
            }
        }
        else {
            self.currentIndexPath = preIndexPath;
        }
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_normal) {
        NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row - 1 inSection:self.currentIndexPath.section];
        if(![self isValidIndexPathInCollectionView:preIndexPath]) {
            NSIndexPath *preSectionIndexPath = [NSIndexPath indexPathForRow:[self.activeParticipatedUsers count] - 1 inSection:BJLIcWritingboradUserlistSection_activeUser];
            if(![self isValidIndexPathInCollectionView:preSectionIndexPath]) {
                NSIndexPath *loginUserSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_loginUser];
                if(![self isValidIndexPathInCollectionView:loginUserSectionIndexPath]) {
                    return;
                }
                else {
                    self.currentIndexPath = loginUserSectionIndexPath;
                }
            }
            else {
                self.currentIndexPath = preSectionIndexPath;
            }
        }
        else {
            self.currentIndexPath = preIndexPath;
        }
    }
    else {
        return ;
    }
        
    BJLUser *user = [self getUserForIndexPath:self.currentIndexPath];
    BOOL hasChecked = NO;
    for(BJLUser *checkedUsers in self.mutaCheckedUsers) {
        if([user.number isEqualToString:checkedUsers.number]) {
            hasChecked = YES;
            break;
        }
    }
    if(!hasChecked && user) {
        [self.mutaCheckedUsers addObject:user];
        self.checkedUsers = self.mutaCheckedUsers;
    }

    if([user.number isEqualToString:self.room.loginUser.number]) {
        self.currentShowUser = self.room.loginUser;
        self.currentLayer = BJLWritingboardUserNumberForTeacher;
    }
    else {
        self.currentShowUser = user;
        self.currentLayer = user.number;
    }
}

- (void)nextPage {
    if(![self isValidStatusForUserListAndToolBar]) {
        return;
    }

    if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_loginUser) {
        NSIndexPath *activeUserSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_activeUser];
        if ([self isValidIndexPathInCollectionView:activeUserSectionIndexPath]) {
            self.currentIndexPath = activeUserSectionIndexPath;
        }
        else {
            NSIndexPath *normalSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_normal];
            if ([self isValidIndexPathInCollectionView:normalSectionIndexPath]) {
                self.currentIndexPath = normalSectionIndexPath;
            }
            else {
                return;
            }
        }
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_activeUser) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row + 1 inSection:BJLIcWritingboradUserlistSection_activeUser];
        if ([self isValidIndexPathInCollectionView:nextIndexPath]) {
            self.currentIndexPath = nextIndexPath;
        }
        else {
            NSIndexPath *normalSectionIndexPath = [NSIndexPath indexPathForRow:0 inSection:BJLIcWritingboradUserlistSection_normal];
            if ([self isValidIndexPathInCollectionView:normalSectionIndexPath]) {
                self.currentIndexPath = normalSectionIndexPath;
            }
            else {
                return;
            }
        }
    }
    else if (self.currentIndexPath.section == BJLIcWritingboradUserlistSection_normal) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:self.currentIndexPath.row + 1 inSection:BJLIcWritingboradUserlistSection_normal];
        if ([self isValidIndexPathInCollectionView:nextIndexPath]) {
            self.currentIndexPath = nextIndexPath;
        }
        else {
            return;
        }
    }
    else {
        return ;
    }

    BJLUser *user = [self getUserForIndexPath:self.currentIndexPath];
    BOOL hasChecked = NO;
    for(BJLUser *checkedUsers in self.mutaCheckedUsers) {
        if([user.number isEqualToString:checkedUsers.number]) {
            hasChecked = YES;
            break;
        }
    }
    if(!hasChecked && user) {
        [self.mutaCheckedUsers addObject:user];
        self.checkedUsers = self.mutaCheckedUsers;
    }

    if([user.number isEqualToString:self.room.loginUser.number]) {
        self.currentShowUser = self.room.loginUser;
        self.currentLayer = BJLWritingboardUserNumberForTeacher;
    }
    else {
        self.currentShowUser = user;
        self.currentLayer = user.number;
    }
}


/* 图片上传小黑板第一期暂时不支持
//TODO:从本地选择图片上传, 应该类似与文档列表中展示图片, 此时图片应该是矢量图,同画笔同性质
- (void)choosePic:(UIButton *)button {
    [self.promptViewController enqueueWithPrompt:@"choosePic示例提醒"];
    
    UIAlertController *alert = [UIAlertController
                                bjl_lightAlertControllerWithTitle:button.currentTitle ?: @"发送图片"
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [alert bjl_addActionWithTitle:@"拍照"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                  [self chooseImageWithSourceType:sourceType];
                              }];
    }
    
    sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [alert bjl_addActionWithTitle:@"从相册中选取"
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
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

#pragma mark - picChoose uploadFile
- (void)sendImageMessage:(ICLImageFile *)imageFile {
    if(!imageFile.fileURL || imageFile.fileURL.absoluteString.length <= 0) {
        [self.promptViewController enqueueWithPrompt:@"文件路径不存在"];

        return;
    }
    
    bjl_weakify(self);
    UIDocument *document = [[UIDocument alloc] initWithFileURL:imageFile.fileURL];
    BJLIcDocumentFile *documentFile = [[BJLIcDocumentFile alloc] initWithLocalDocument:document];
    documentFile.type = BJLIcDocumentFileAnimatedPPT;
    documentFile.state = BJLIcDocumentFileUploading;
    documentFile.progress = 0.0;

    [self.room.documentVM uploadFile:documentFile.url
                            mimeType:documentFile.mimeType
                            fileName:documentFile.name
                          isAnimated:NO
                            progress:^(CGFloat progress) {
//                                TODO:选择图片上传时 进度条?
                            }
                              finish:^(BJLDocument * _Nullable document, BJLError * _Nullable error) {
                                  bjl_strongify(self);
                                  if(!error) {
//                                      TODO:使用哪一个document?
//                                      通过fileID获取文档
                                      [self.room.documentVM addDocument:document];
                                  }
                                  else {
                                      //TODO:选择图片上传失败?

                                      documentFile.state = BJLIcDocumentFileError;
                                      documentFile.errorMessage = @"文件上传失败\n无法使用";
                                      
                                      [self.promptViewController enqueueWithPrompt:@"文件上传失败\n无法使用"];
                                  }
                              }];
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

- (void)chooseImageWithCamera {
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
    imagePickerController.allowsEditing = NO;
    imagePickerController.delegate = self;
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)chooseImageWithFromPhotoLibrary {
    QBImagePickerController *imagePickerController = [QBImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.mediaType = QBImagePickerMediaTypeImage;
    imagePickerController.allowsMultipleSelection = YES;
    imagePickerController.showsNumberOfSelectedAssets = YES;
    imagePickerController.maximumNumberOfSelection = 1; // 1: 避免刷屏
    if (self.presentedViewController) {
        [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
    }
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - <UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
    bjl_weakify(self);
    [picker dismissViewControllerAnimated:YES completion:^{
        bjl_strongify(self);
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        UIImage *thumbnail = [image bjl_imageFillSize:BJLAspectFillSize([UIScreen mainScreen].bounds.size,
                                                                        image.size.width / image.size.height)
                                              enlarge:NO];
        NSString *mediaType = info[UIImagePickerControllerMediaType];
        NSError *error = nil;
        ICLImageFile *imageFile = [ICLImageFile imageFileWithImage:image
                                                         thumbnail:thumbnail
                                                         mediaType:mediaType
                                                             error:&error];
        if (!imageFile) {
            [self.promptViewController enqueueWithPrompt:@"照片获取出错"];
            return;
        }
        [self sendImageMessage:imageFile];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <QBImagePickerControllerDelegate>

- (void)qb_imagePickerController:(QBImagePickerController *)picker didFinishPickingAssets:(NSArray<PHAsset *> *)assets {
    [picker icl_loadImageFilesWithAssets:assets
                             contentMode:PHImageContentModeAspectFit
                              targetSize:CGSizeMake(BJLAliIMGMaxSize, BJLAliIMGMaxSize)
                           thumbnailSize:[UIScreen mainScreen].bounds.size]; // CGSizeZero
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <QBImagePickerControllerDelegate_iCloudLoading>

- (void)icl_imagePickerController:(QBImagePickerController *)picker
       didFinishLoadingImageFiles:(NSArray<ICLImageFile *> *)imageFiles {
    bjl_weakify(self);
    [picker dismissViewControllerAnimated:YES completion:^{
        bjl_strongify(self);
        [self sendImageMessage:imageFiles.firstObject];
    }];
}
*/

@end
