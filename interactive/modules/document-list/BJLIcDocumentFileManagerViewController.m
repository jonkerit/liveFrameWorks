//
//  BJLIcDocumentFileManagerViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/26.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveBase/BJLNetworking+BaijiaYun.h>
#import <BJLiveBase/BJLError.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcDocumentFileManagerViewController.h"
#import "BJLIcDocumentFileView.h"
#import "BJLIcDocumentFileCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BJLIcDocumentFileSection) {
    BJLIcDocumentFileSection_office,
    BJLIcDocumentFileSection_web,
    BJLIcDocumentFileSection_image,
    BJLIcDocumentFileSection_media,
    _BJLIcDocumentFileSection_count
};

static const CGFloat pollDuration = 2.0;

@interface BJLIcDocumentFileManagerViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIDocumentPickerDelegate>

@property (nonatomic, weak) BJLRoom *room;
// 文档管理视图
@property (nonatomic) BJLIcDocumentFileView *documentFileView;
// 编辑模式
@property (nonatomic) BOOL isEditing;
@property (nonatomic) NSInteger selectedDocumentFileCount;
// 区分动态和静态PPT调用按钮
@property (nonatomic) BOOL isSelectAnimatedDocumentFile;
// 轮询转码进度 timer
@property (nonatomic, nullable) NSTimer *pollTimer;

// document manager
@property (nonatomic) NSMutableArray<BJLIcDocumentFile *> *mutableDocumentFileList;
@property (nonatomic) NSMutableArray<BJLIcDocumentFile *> *mutableOfficeDocumentFileList;
@property (nonatomic) NSMutableArray<BJLIcDocumentFile *> *mutableImageFileList;
@property (nonatomic) NSMutableArray<BJLIcDocumentFile *> *mutableMediaFileList;
@property (nonatomic) NSMutableArray<BJLIcDocumentFile *> *mutableWebDocumentFileList;

// 文档成功添加列表
@property (nonatomic) NSMutableArray<NSString *> *finishDocumentFileIDList;

// debug
@property (nonatomic) UITextView *fullNameTextView;

@end

@implementation BJLIcDocumentFileManagerViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self.room = room;
        self.mutableDocumentFileList = [NSMutableArray new];
        self.mutableWebDocumentFileList = [NSMutableArray new];
        self.mutableOfficeDocumentFileList = [NSMutableArray new];
        self.mutableImageFileList = [NSMutableArray new];
        self.mutableMediaFileList = [NSMutableArray new];
        self.finishDocumentFileIDList = [NSMutableArray new];
        
        [self makeObserving];
        if (self.room.state == BJLRoomState_connected) {
            [self loadAllRemoteDocuments:self.room.documentVM.allDocuments];
        }
    }
    return self;
}

- (void)dealloc {
    self.documentFileView.collectionView.delegate = nil;
    self.documentFileView.collectionView.dataSource = nil;
    [self bjl_stopAllMethodParametersObserving];
    [self stopPollTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeSubviewsAndConstraints];
    [self makeActions];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateDocumentFileViewHidden];
    [self.documentFileView.collectionView reloadData];
}

- (void)makeSubviewsAndConstraints {
    self.view.backgroundColor = [UIColor clearColor];
    // 毛玻璃效果
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIView *backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    [self.view addSubview:backgroundView];
    [backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.documentFileView = [[BJLIcDocumentFileView alloc] init];
    self.documentFileView.collectionView.delegate = self;
    self.documentFileView.collectionView.dataSource = self;
    [self.view addSubview:self.documentFileView];
    [self.documentFileView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.equalTo(self.view.bjl_width).multipliedBy(0.9);
        make.height.equalTo(self.view.bjl_height).multipliedBy(0.8);
    }];
    [self updateDocumentFileViewHidden];
}

#pragma mark - actions

- (void)makeActions {
    // close button
    [self.documentFileView.closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    // add animate document file
    [self.documentFileView.addAnimatedDocumentFileButton addTarget:self action:@selector(addAnimatedDocumentFile) forControlEvents:UIControlEventTouchUpInside];
    [self.documentFileView.addAnimatedDocumentFileEmptyButton addTarget:self action:@selector(addAnimatedDocumentFile) forControlEvents:UIControlEventTouchUpInside];
    // add normal document file
    [self.documentFileView.addNormalDocumentFileButton addTarget:self action:@selector(addNormalDocumentFile) forControlEvents:UIControlEventTouchUpInside];
    [self.documentFileView.addNormalDocumentFileEmptyButton addTarget:self action:@selector(addNormalDocumentFile) forControlEvents:UIControlEventTouchUpInside];
    // edit
    [self.documentFileView.editDocumentFileButton addTarget:self action:@selector(enterEditMode) forControlEvents:UIControlEventTouchUpInside];
    // delete
    [self.documentFileView.deleteDocumentFileButton addTarget:self action:@selector(deleteSelectedDocumentFile) forControlEvents:UIControlEventTouchUpInside];
    // cancel
    [self.documentFileView.cancelEditStateButton addTarget:self action:@selector(cancelEditMode) forControlEvents:UIControlEventTouchUpInside];
}

// 隐藏
- (void)hide {
    if (self.hideCallback) {
        self.hideCallback();
    }
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

// 添加动态PPT
- (void)addAnimatedDocumentFile {
    self.isSelectAnimatedDocumentFile = YES;
    [self showDocumentPickerViewController];
}

// 添加普通PPT
- (void)addNormalDocumentFile {
    self.isSelectAnimatedDocumentFile = NO;
    [self showDocumentPickerViewController];
}

- (void)showDocumentPickerViewController {
    if (@available(iOS 11.0, *)) {
        // open 仅限于打开自己的文件, import 可以导入共享的文件
        NSArray *array = @[@"public.data"];
        if (self.isSelectAnimatedDocumentFile) {
            array = @[@"org.openxmlformats.presentationml.presentation", @"com.microsoft.powerpoint.ppt"];
        }
        UIDocumentPickerViewController* vc = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:array
                                                                                                    inMode:UIDocumentPickerModeImport];
        vc.delegate = self;
        vc.allowsMultipleSelection = NO;
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000) // __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            vc.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
#endif
        if (self.presentedViewController) {
            [self.presentedViewController bjl_dismissAnimated:YES completion:nil];
        }
        [self bjl_presentFullScreenViewController:vc animated:YES completion:nil];
    }
    else {
        if (self.showErrorMessageCallback) {
            self.showErrorMessageCallback(@"当前系统版本不支持，请升级到11.0以上版本");
        }
    }
}

// 编辑模式
- (void)enterEditMode {
    self.isEditing = YES;
    self.selectedDocumentFileCount = 0;
    for (BJLIcDocumentFile *file in [self.mutableDocumentFileList copy]) {
        file.editMode = BJLIcDocumentFileUnselected;
    }
    for (BJLIcDocumentFile *file in [self.mutableWebDocumentFileList copy]) {
        file.editMode = BJLIcDocumentFileUnselected;
    }
    [self.documentFileView updateEditViewHidden:NO];
    [self.documentFileView.collectionView reloadData];
}

// 删除选中文档
- (void)deleteSelectedDocumentFile {
    [self deleteSelectedDocumentFiles];
    [self updateDocumentFileViewHidden];
    [self cancelEditMode];
}

// 取消编辑模式
- (void)cancelEditMode {
    self.isEditing = NO;
    self.selectedDocumentFileCount = 0;
    for (BJLIcDocumentFile *file in [self.mutableDocumentFileList copy]) {
        file.editMode = BJLIcDocumentFileNonEdit;
    }
    for (BJLIcDocumentFile *file in [self.mutableWebDocumentFileList copy]) {
        file.editMode = BJLIcDocumentFileNonEdit;
    }
    [self.documentFileView updateEditViewHidden:YES];
    [self.documentFileView.collectionView reloadData];
}

// debug
- (void)updateDocumentFileFullName:(NSString *)name onCell:(UICollectionViewCell *)cell {
    self.fullNameTextView.hidden = !self.fullNameTextView.isHidden;
    if (!self.fullNameTextView.isHidden) {
        self.fullNameTextView.text = name;
        [cell addSubview:self.fullNameTextView];
        [self.fullNameTextView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.left.right.bottom.equalTo(cell);
            make.top.equalTo(cell).offset(75.0).priorityHigh();
        }];
    }
}

#pragma mark - observing

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didAddDocument:)
             observer:^BOOL(BJLDocument *document) {
                 bjl_strongify(self);
                 // 更新文档状态
                 BJLIcDocumentFile *documentFile  = [[BJLIcDocumentFile alloc] initWithRemoteDocument:document];
                 if (self.isEditing) {
                     documentFile.editMode = BJLIcDocumentFileUnselected;
                 }
                 [self updateDocumentsListWithDocumentFile:documentFile];
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, allDocumentsDidOverwrite:)
             observer:^BOOL{
                 bjl_strongify(self);
                 [self loadAllRemoteDocuments:self.room.documentVM.allDocuments];
                 return YES;
             }];
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didDeleteDocument:)
             observer:^BOOL(BJLDocument *document) {
                 bjl_strongify(self);
                 BJLIcDocumentFile *documentFile = [self documentFileWithLocalID:nil fileID:document.fileID];
                 [self deleteDocumetFile:documentFile];
                 return YES;
             }];
    [self bjl_kvo:BJLMakeProperty(self, selectedDocumentFileCount)
         observer:^BOOL(id  _Nullable now, id  _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             if (self.isEditing) {
                 self.documentFileView.deleteDocumentFileButton.enabled = self.selectedDocumentFileCount;
                 self.documentFileView.deleteDocumentFileButton.backgroundColor = self.selectedDocumentFileCount? [UIColor bjl_colorWithHexString:@"#FF1F49" alpha:1.0] : [UIColor bjl_colorWithHexString:@"#FFFFFF" alpha:0.3];
             }
             return YES;
         }];
    
    [self makeObservingForWebDocument];
}

- (void)makeObservingForWebDocument {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, allWebDocumentsDidOverwrite:)
             observer:^BOOL(NSArray<BJLDocument *> *allWebDocuments) {
                 bjl_strongify(self);
                 [self.mutableWebDocumentFileList removeAllObjects];
                 for (BJLDocument *document in allWebDocuments) {
                     BJLIcDocumentFile *documentFile = [[BJLIcDocumentFile alloc] initWithRemoteDocument:document];
                     if (self.isEditing) {
                         documentFile.editMode = BJLIcDocumentFileUnselected;
                     }
                     [self.mutableWebDocumentFileList addObject:documentFile];
                 }
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self updateDocumentFileViewHidden];
                 [self.documentFileView.collectionView reloadData];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didAddWebDocument:)
             observer:^BOOL(BJLDocument *document) {
                 bjl_strongify(self);
                 BJLIcDocumentFile *documentFile = [[BJLIcDocumentFile alloc] initWithRemoteDocument:document];
                 if (self.isEditing) {
                     documentFile.editMode = BJLIcDocumentFileUnselected;
                 }
                 [self.mutableWebDocumentFileList addObject:documentFile];
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self updateDocumentFileViewHidden];
                 [self.documentFileView.collectionView reloadData];
                 return YES;
             }];
    
    [self bjl_observe:BJLMakeMethod(self.room.documentVM, didDeleteWebDocument:)
             observer:^BOOL(BJLDocument *document){
                  bjl_strongify(self);
                 NSString *documentID = document.documentID;
                 for (BJLIcDocumentFile *documentFile in [self.mutableWebDocumentFileList copy]) {
                     if ([documentFile.remoteDocument.documentID isEqualToString:documentID]) {
                         [self.mutableWebDocumentFileList removeObject:documentFile];
                     }
                 }
                 if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
                     return YES;
                 }
                 [self updateDocumentFileViewHidden];
                 [self.documentFileView.collectionView reloadData];
                 return YES;
             }];
}

#pragma mark - timer

// 轮询转码
- (void)startPollTimer {
    [self stopPollTimer];
    // 立即请求一次
    [self requestTranscodingProgress];
    bjl_weakify(self);
    self.pollTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:pollDuration repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        [self requestTranscodingProgress];
    }];
}

- (void)stopPollTimer {
    [self.pollTimer invalidate];
    self.pollTimer = nil;
}

#pragma mark - document file manager

// 加载所有远端文档
- (void)loadAllRemoteDocuments:(NSArray<BJLDocument *> *)documents {
    [self.mutableDocumentFileList removeAllObjects];
    [self.mutableOfficeDocumentFileList removeAllObjects];
    [self.mutableImageFileList removeAllObjects];
    [self.mutableMediaFileList removeAllObjects];
    
    for (BJLDocument *document in documents) {
        if ([document.documentID isEqualToString:BJLBlackboardID]) {
            continue; // 白板不计入
        }
        if ([document.documentID isEqualToString:BJLWritingboardID]) {
            continue; // 小黑板不计入
        }

        BJLIcDocumentFile *documentFile = [[BJLIcDocumentFile alloc] initWithRemoteDocument:document];
        [self.mutableDocumentFileList bjl_addObject:documentFile];
        
        switch (documentFile.type) {
            case BJLIcDocumentFileImage:
                [self.mutableImageFileList bjl_addObject:documentFile];
                break;
            case BJLIcDocumentFileAudio:
            case BJLIcDocumentFileVideo:
                [self.mutableMediaFileList bjl_addObject:documentFile];
                break;
            default:
                [self.mutableOfficeDocumentFileList bjl_addObject:documentFile];
                break;
        }
    }
}

// 上传文档 TODO:!!!上传时存在 BoringSSL 的警告
- (void)uploadDocumentFile:(BJLIcDocumentFile *)documentFile {
    // 改变状态
    documentFile.state = BJLIcDocumentFileUploading;
    documentFile.progress = 0.0;
    [self updateDocumentsListWithDocumentFile:documentFile];
    bjl_weakify(self);
    BOOL isAnimated = documentFile.type == BJLIcDocumentFileAnimatedPPT;
    // 上传
    [self.room.documentVM uploadFile:documentFile.url
                            mimeType:documentFile.mimeType
                            fileName:documentFile.name
                          isAnimated:isAnimated
                            progress:^(CGFloat progress) {
                                bjl_strongify(self);
                                [self updateDocumentFileWithLocalID:documentFile.localID fileID:nil progress:progress];
                            }
                              finish:^(BJLDocument * _Nullable document, BJLError * _Nullable error) {
                                  bjl_strongify(self);
                                  
                                  if (!error) {
                                      // 如果文档在上传过程中删除了，丢弃远端文档
                                      if (![self.mutableDocumentFileList containsObject:documentFile]) {
                                          return;
                                      }
                                      // 远端文档和本地文档对应，以便更新文档列表
                                      BJLIcDocumentFile *file = [[BJLIcDocumentFile alloc] initWithRemoteDocument:document];
                                      file.localID = documentFile.localID;
                                      // 设置状态为转码, 重置进度，更新文档列表
                                      file.state = BJLIcDocumentFileTranscoding;
                                      file.progress = 0.0;
                                      [self updateDocumentsListWithDocumentFile:file];
                                      if (file.type == BJLIcDocumentFileImage) {
                                          // 图片不需要转码，直接添加到教室
                                          [self finishUpdateDocumentFileWithFileID:file.remoteDocument.fileID];
                                      }
                                      else {
                                          // 开始轮询转码进度
                                          [self startPollTimer];
                                      }
                                  }
                                  else {
                                      documentFile.state = BJLIcDocumentFileError;
                                      documentFile.errorMessage = @"文件上传失败\n无法使用";
                                      [self updateDocumentsListWithDocumentFile:documentFile];
                                  }
                              }];

    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    [self updateDocumentFileViewHidden];
}

- (void)requestTranscodingProgress {
    // 查询所有转码中的文档进度
    NSMutableArray *array = [NSMutableArray new];
    for (BJLIcDocumentFile *documentFile in [self.mutableDocumentFileList copy]) {
        if (documentFile.state == BJLIcDocumentFileTranscoding) {
            if (documentFile.remoteDocument.fileID.length) {
                [array bjl_addObject:documentFile.remoteDocument.fileID];
            }
        }
    }
    // 当前没有转码中文档，停止轮询
    if (!array.count) {
        [self stopPollTimer];
        return;
    }
    // 请求转码进度接口
    bjl_weakify(self);
    [self.room.documentVM requestTranscodingProgressWithFileIDList:array
                                                        completion:^(NSArray<BJLDocumentTranscodeModel *> * _Nullable transcodeModelArray, BJLError * _Nullable error) {
                                                            bjl_strongify(self);
                                                            if (error) {
                                                                NSLog(@"error when requestTranscodingProgressWithFileIDList %@", error);
                                                                return;
                                                            }
                                                            for (BJLDocumentTranscodeModel *model in transcodeModelArray) {
                                                                if (model.progress >= 100) {
                                                                    // 转码完成
                                                                    [self finishUpdateDocumentFileWithFileID:model.fileID];
                                                                }
                                                                else {
                                                                    // 更新转码进度
                                                                    [self updateDocumentFileWithLocalID:nil fileID:model.fileID progress:model.progress];
                                                                }
                                                            }
                                                        }];
}

// 远端文档转码完成
- (void)finishUpdateDocumentFileWithFileID:(NSString *)fileID {
    BJLIcDocumentFile *documentFile = [self documentFileWithLocalID:nil fileID:fileID];
    if (!documentFile) {
        return;
    }
    if (documentFile.type == BJLIcDocumentFileImage) {
        // 图片不需要转码
        [self.room.documentVM addDocument:documentFile.remoteDocument];
    }
    else {
        // 添加文档
        bjl_weakify(self);
        [self.room.documentVM requestDocumentListWithFileIDList:@[fileID]
                                                     completion:^(NSArray<BJLDocument *> * _Nullable documentArray, BJLError * _Nullable error) {
                                                         bjl_strongify(self);
                                                         if (error) {
                                                             NSLog(@"error when requestDocumentListWithFileIDList %@", error);
                                                             return;
                                                         }
                                                         for (BJLDocument *document in documentArray) {
                                                             for (NSString *fileID in self.finishDocumentFileIDList) {
                                                                 // 如果文档已经添加到了教室, 不处理
                                                                 if ([document.fileID isEqualToString:fileID]) {
                                                                     return;
                                                                 }
                                                             }
                                                             // 请求到文档信息之后添加文档，这时认为已经添加到了教室里
                                                             [self.finishDocumentFileIDList bjl_addObject:document.fileID];
                                                             // 转码成功后可以获得文档的页码信息，更新本地document
                                                             BJLIcDocumentFile *documentFile = [self documentFileWithLocalID:nil fileID:document.fileID];
                                                             [documentFile.remoteDocument updateDocumentName:documentFile.name pageInfo:document.pageInfo];
                                                             [self.room.documentVM addDocument:documentFile.remoteDocument];
                                                         }
                                                     }];
    }
}

// 更新上传和转码进度
- (void)updateDocumentFileWithLocalID:(nullable NSString *)localID fileID:(nullable NSString *)fileID progress:(CGFloat)progress {
    BJLIcDocumentFile *documentFile = [self documentFileWithLocalID:localID fileID:fileID];
    if (documentFile.state == BJLIcDocumentFileUploading || documentFile.state == BJLIcDocumentFileTranscoding) {
        documentFile.progress = progress;
    }
}

// 上传成功, 更新文档列表, 使用远端文档数据
- (void)updateDocumentsListWithDocumentFile:(BJLIcDocumentFile *)documentFile {
    BJLIcDocumentFile *changedFile = [self documentFileWithLocalID:documentFile.localID fileID:documentFile.remoteDocument.fileID];
    // file 发生改变
    if (changedFile) {
        // 转码完成前没有办法判断是否是动态PPT，因此根据本地上传文档来判断
        documentFile.type = changedFile.type;
        [self.mutableDocumentFileList removeObject:changedFile];
        [self.mutableOfficeDocumentFileList removeObject:changedFile];
        [self.mutableMediaFileList removeObject:changedFile];
        [self.mutableImageFileList removeObject:changedFile];
    }
    
    [self.mutableDocumentFileList bjl_addObject:documentFile];
    switch (documentFile.type) {
        case BJLIcDocumentFileImage:
            [self.mutableImageFileList bjl_addObject:documentFile];
            break;
            
        case BJLIcDocumentFileAudio:
        case BJLIcDocumentFileVideo:
            [self.mutableMediaFileList bjl_addObject:documentFile];
            break;
            
        default:
            [self.mutableOfficeDocumentFileList bjl_addObject:documentFile];
            break;
    }
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    [self updateDocumentFileViewHidden];
    [self.documentFileView.collectionView reloadData];
}

// 删除选中的文档, 不等待返回删除成功
- (void)deleteSelectedDocumentFiles {
    for (BJLIcDocumentFile *file in [self.mutableDocumentFileList copy]) {
        if (file.editMode == BJLIcDocumentFileSelected) {
            if (file.state == BJLIcDocumentFileNormal) {
                BJLError *error = [self.room.documentVM deleteDocumentWithID:file.remoteDocument.documentID];
                if (error) {
                    NSLog(@"error occur when delete file %@ error %@", file.name, error);
                    return;
                }
            }
            [self.mutableDocumentFileList removeObject:file];
        }
    }
    // 清空所有数组中的指向
    for (BJLIcDocumentFile *file in [self.mutableOfficeDocumentFileList copy]) {
        if (file.editMode == BJLIcDocumentFileSelected) {
            [self.mutableOfficeDocumentFileList removeObject:file];
        }
    }
    for (BJLIcDocumentFile *file in [self.mutableImageFileList copy]) {
        if (file.editMode == BJLIcDocumentFileSelected) {
            [self.mutableImageFileList removeObject:file];
        }
    }
    for (BJLIcDocumentFile *file in [self.mutableMediaFileList copy]) {
        if (file.editMode == BJLIcDocumentFileSelected) {
            [self.mutableMediaFileList removeObject:file];
        }
    }
    
    for (BJLIcDocumentFile *file in self.mutableWebDocumentFileList) {
        if (file.editMode == BJLIcDocumentFileSelected) {
            BJLError *error = [self.room.documentVM deleteWebDocumentWithID:file.remoteDocument.documentID];
            if (error) {
                NSLog(@"error occur when delete file %@ error %@", file.name, error);
                return;
            }
            [self.mutableMediaFileList removeObject:file];
        }
    }
    
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    [self.documentFileView.collectionView reloadData];
}

- (void)deleteDocumetFile:(BJLIcDocumentFile *)file {
    if ([self.mutableDocumentFileList containsObject:file]) {
        [self.mutableDocumentFileList removeObject:file];
    }
    if ([self.mutableOfficeDocumentFileList containsObject:file]) {
        [self.mutableOfficeDocumentFileList removeObject:file];
    }
    else if ([self.mutableImageFileList containsObject:file]) {
        [self.mutableImageFileList removeObject:file];
    }
    else if ([self.mutableMediaFileList containsObject:file]) {
        [self.mutableMediaFileList removeObject:file];
    }
    if (!self || !self.isViewLoaded || !self.view.window || self.view.hidden) {
        return;
    }
    [self.documentFileView.collectionView reloadData];
}

// 根据 localID 或者 fileID 获取文档
- (nullable BJLIcDocumentFile *)documentFileWithLocalID:(nullable NSString *)localID fileID:(nullable NSString *)fileID {
    for (BJLIcDocumentFile *documentFile in [self.mutableDocumentFileList copy]) {
        if (localID.length && [documentFile.localID isEqualToString:localID]) {
            return documentFile;
        }
        else if (fileID.length && [documentFile.remoteDocument.fileID isEqualToString:fileID]) {
            return documentFile;
        }
    }
    return nil;
}

#pragma mark - getter

- (UITextView *)fullNameTextView {
    if (!_fullNameTextView) {
        _fullNameTextView = ({
            UITextView *textView = [UITextView new];
            textView.editable = NO;
            textView.showsVerticalScrollIndicator = NO;
            textView.showsHorizontalScrollIndicator = NO;
            textView.textContainerInset = UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0);
            textView.layer.cornerRadius = 4.0;
            textView.clipsToBounds = YES;
            textView.hidden = YES;
            textView.textAlignment = NSTextAlignmentLeft;
            textView.backgroundColor = [UIColor whiteColor];
            textView.font = [UIFont systemFontOfSize:14.0];
            textView.textColor = [UIColor blackColor];
            textView;
        });
    }
    return _fullNameTextView;
}

#pragma mark - wheel

- (nullable BJLIcDocumentFile *)documentFileWithIndexPath:(NSIndexPath *)indexPath {
    NSArray<BJLIcDocumentFile *> *fileList = nil;
    switch (indexPath.section) {
        case BJLIcDocumentFileSection_office:
            fileList = self.mutableOfficeDocumentFileList;
            break;
            
        case BJLIcDocumentFileSection_web:
            fileList = self.mutableWebDocumentFileList;
            break;
            
        case BJLIcDocumentFileSection_image:
            fileList = self.mutableImageFileList;
            break;
            
        case BJLIcDocumentFileSection_media:
            fileList = self.mutableMediaFileList;
            break;
            
        default:
            break;
    }
    return [fileList bjl_objectAtIndex:indexPath.row];
}

#pragma mark - collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _BJLIcDocumentFileSection_count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case BJLIcDocumentFileSection_office:
            return self.mutableOfficeDocumentFileList.count;
        
        case BJLIcDocumentFileSection_web:
            return self.mutableWebDocumentFileList.count;
            
        case BJLIcDocumentFileSection_image:
            return self.mutableImageFileList.count;
            
        case BJLIcDocumentFileSection_media:
            return self.mutableMediaFileList.count;
            
        default:
            return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcDocumentFileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kIcDocumentFileCellReuseIdentifier forIndexPath:indexPath];
    return cell;
}

// head view
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    BJLIcDocumentFileCellHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kIcDocumentFileCellHeaderReuseIdentifier forIndexPath:indexPath];
    NSString *title = nil;
    switch (indexPath.section) {
        case BJLIcDocumentFileSection_office:
            title = @"文档";
            break;
            
        case BJLIcDocumentFileSection_web:
            title = @"网页文档";
            break;
            
        case BJLIcDocumentFileSection_image:
            title = @"图片";
            break;
            
        case BJLIcDocumentFileSection_media:
            title = @"媒体文件";
            break;
            
        default:
            break;
    }
    [headerView updateWithTitle:title];
    return headerView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    BOOL hidden = NO;
    switch (section) {
        case BJLIcDocumentFileSection_office:
            hidden = self.mutableOfficeDocumentFileList.count <= 0;
            break;
        
        case BJLIcDocumentFileSection_web:
            hidden = self.mutableWebDocumentFileList.count <= 0;
            break;
            
        case BJLIcDocumentFileSection_image:
            hidden = self.mutableImageFileList.count <= 0;
            break;
            
        case BJLIcDocumentFileSection_media:
            hidden = self.mutableMediaFileList.count <= 0;
            break;
            
        default:
            hidden = NO;
    }
    return CGSizeMake(self.documentFileView.bounds.size.width, hidden ? 0.0 : 40.0);
}

#pragma mark - collection view delegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLIcDocumentFileCell *documentFileCell = bjl_as(cell, BJLIcDocumentFileCell);
    BJLIcDocumentFile *file = [self documentFileWithIndexPath:indexPath];
    [documentFileCell updateWithDocumentFile:file];
    bjl_weakify(self, documentFileCell);
    [documentFileCell setSingleTapCallback:^(BJLIcDocumentFile * _Nonnull documentFile, UIImage * _Nullable image) {
        bjl_strongify(self, documentFileCell);
        if (self.isEditing) {
            // 编辑状态
            if (file.editMode == BJLIcDocumentFileUnselected) {
                file.editMode = BJLIcDocumentFileSelected;
                self.selectedDocumentFileCount ++;
            }
            else {
                file.editMode = BJLIcDocumentFileUnselected;
                self.selectedDocumentFileCount --;
            }
            [documentFileCell updateWithDocumentFile:file];
        }
        else {
            // 非编辑状态
            if (file.state == BJLIcDocumentFileNormal) {
                // 单击打开
                if (self.selectDocumentFileCallback) {
                    self.selectDocumentFileCallback(file, image);
                }
                [self hide];
            }
            else if (file.state == BJLIcDocumentFileError) {
                // 错误文件显示错误
                [documentFileCell showErrorView];
            }
        }
    }];
}

#pragma mark - UIDocumentPicker Delegate

// TODO:!!!选取的文件存在没有预览图的警告
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        UIDocument *document = [[UIDocument alloc] initWithFileURL:url];
        BJLIcDocumentFile *documentFile = [[BJLIcDocumentFile alloc] initWithLocalDocument:document];
        documentFile.type = self.isSelectAnimatedDocumentFile ? BJLIcDocumentFileAnimatedPPT : documentFile.type;
        [self uploadDocumentFile:documentFile];
    }
    self.isSelectAnimatedDocumentFile = NO;
}

#pragma mark - private

- (void)updateDocumentFileViewHidden {
    [self.documentFileView updateDocumentFileViewHidden:!(self.mutableDocumentFileList.count + self.mutableWebDocumentFileList.count)];
}

@end

NS_ASSUME_NONNULL_END
