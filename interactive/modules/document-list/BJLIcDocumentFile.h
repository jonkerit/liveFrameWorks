//
//  BJLIcDocumentFile.h
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/26.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BJLDocument;

typedef NS_ENUM(NSInteger, BJLIcDocumentFileType) {
    BJLIcDocumentFileTXT,                                           // txt 文本, 不在枚举之类的默认设置为 txt
    BJLIcDocumentFileDOC,                                           // word 文档
    BJLIcDocumentFilePDF,                                           // pdf 文档
    BJLIcDocumentFileXLS,                                           // excel 等表格
    BJLIcDocumentFileNormalPPT,                                     // 普通 ppt, 本地不区分动态 ppt, 默认为普通 ppt
    BJLIcDocumentFileAnimatedPPT,                                   // 动效 ppt
    BJLIcDocumentFileWebPPT,                                        // web ppt
    BJLIcDocumentFileImage,                                         // 图片
    BJLIcDocumentFileAudio,                                         // 音频
    BJLIcDocumentFileVideo,                                         // 视频
    BJLIcDocumentFileTypeCount,                                     // 文件类型计数
    BJLIcDocumentFileTypeDefault = BJLIcDocumentFileTXT,
};

typedef NS_ENUM(NSInteger, BJLIcDocumentFileState) {
    BJLIcDocumentFileNormal,                                        // 普通状态
    BJLIcDocumentFileError,                                         // 错误状态
    BJLIcDocumentFileUploading,                                     // 上传状态
    BJLIcDocumentFileTranscoding,                                   // 转码状态
    BJLIcDocumentFileStateDefault = BJLIcDocumentFileNormal,
};

typedef NS_ENUM(NSInteger, BJLIcDocumentFileEditMode) {
    BJLIcDocumentFileNonEdit,                                       // 未编辑状态
    BJLIcDocumentFileUnselected,                                    // 非选中状态
    BJLIcDocumentFileSelected,                                      // 选中状态
    BJLIcDocumentFileEditModeDefault = BJLIcDocumentFileNonEdit,
};

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcDocumentFile : NSObject

@property (nonatomic) NSString *localID;                            // 文档标识符, 远端文档为nil
@property (nonatomic) NSString *name;                               // 文档名
@property (nonatomic) NSString *suffix;                             // 文件后缀
@property (nonatomic) NSString *mimeType;                           // 文档web类型
@property (nonatomic) NSURL *url;                                   // 文档url, 上传到远端后为远端文档url
@property (nonatomic) BJLIcDocumentFileType type;                   // 文档类型
@property (nonatomic) BJLIcDocumentFileState state;                 // 文档状态
@property (nonatomic) BJLIcDocumentFileEditMode editMode;           // 文档编辑状态
@property (nonatomic) UIDocument *localDocument;                    // 本地文档, 远端文档此属性为nil
@property (nonatomic) BJLDocument *remoteDocument;                  // 远端文档, 本地文档此属性为nil
@property (nonatomic) CGFloat progress;                             // 上传和转码进度
@property (nonatomic) NSString *errorMessage;                       // 上传失败的错误信息

/**
 使用本地文档初始化

 @param localDocument UIDocument
 @return self
 */
- (instancetype)initWithLocalDocument:(UIDocument *)localDocument;

/**
 使用远端文档初始化

 @param remoteDocument BJLDocument
 @return self
 */
- (instancetype)initWithRemoteDocument:(BJLDocument *)remoteDocument;

@end

NS_ASSUME_NONNULL_END
