//
//  BJLIcDocumentFile.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/9/26.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLDocument.h>
#import <BJLiveBase/BJLNetworking.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "BJLIcDocumentFile.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BJLIcDocumentFile

- (instancetype)init {
    if (self = [super init]) {
        self.state = BJLIcDocumentFileStateDefault;
        self.editMode = BJLIcDocumentFileEditModeDefault;
        self.type = BJLIcDocumentFileTypeDefault;
        self.progress = 0.0;
    }
    return self;
}

- (instancetype)initWithLocalDocument:(UIDocument *)localDocument {
    if (self = [super init]) {
        self.localDocument = localDocument;
        
        self.localID = [self getUniqueId];
        self.url = localDocument.fileURL;
        [self updateFileNameAndSuffixWithFileURLString:self.url.absoluteString];
        [self updateFileTypeWithSuffix:self.suffix];
    }
    return self;
}

- (instancetype)initWithRemoteDocument:(BJLDocument *)remoteDocument {
    if (self = [super init]) {
        self.remoteDocument = remoteDocument;
        
        self.name = remoteDocument.fileName;
        self.suffix = remoteDocument.fileExtension;
        self.url = [NSURL URLWithString:(remoteDocument.isWebDocument
                                         ? remoteDocument.webDocumentURL
                                         : remoteDocument.pageInfo.pageURLString)];
        [self updateFileTypeWithSuffix:self.suffix];
        if (remoteDocument.isAnimate && self.type == BJLIcDocumentFileNormalPPT) {
            self.type = BJLIcDocumentFileAnimatedPPT;
        }
    }
    return self;
}

#pragma mark - wheel

- (NSString *)getUniqueId {
    CFUUIDRef uuidRef =CFUUIDCreate(NULL);
    CFStringRef uuidStringRef =CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    return [NSString stringWithFormat:@"documentFile%@",(__bridge_transfer NSString *)uuidStringRef];
}

- (void)updateFileNameAndSuffixWithFileURLString:(NSString *)urlString {
    NSString *name = [urlString.lastPathComponent stringByRemovingPercentEncoding];
    NSString *suffix = name.pathExtension;
    self.name = name;
    self.suffix = [@"." stringByAppendingString:suffix];
    // 处理 HEIC 和 HEIF 格式的图片
    NSArray *imageSuffixArray = @[@".heic",
                                  @".heif"];
    if ([self compareSuffix:self.suffix withSuffixArray:imageSuffixArray]) {
        CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)self.localDocument.fileURL, nil);
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, nil);
        NSString *cachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSString *fileName = [name.stringByDeletingPathExtension stringByAppendingString:@".jpg"];
        NSString *filePath = [cachesDir stringByAppendingPathComponent:fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        CGImageDestinationRef fileURLRef = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeJPEG, 1, nil);
        if (!fileURLRef) {
            CGImageRelease(imageRef);
            CFRelease(source);
            NSLog(@"unable to create CGImageDestination");
            return;
        }
        CGImageDestinationAddImage(fileURLRef, imageRef, nil);
        CGImageDestinationFinalize(fileURLRef);
        // 重新赋值
        self.url = [NSURL fileURLWithPath:filePath];
        self.name = fileName;
        self.suffix = @".jpg";
        
        CGImageRelease(imageRef);
        CFRelease(fileURLRef);
        CFRelease(source);
    }
}

- (void)updateFileTypeWithSuffix:(NSString *)suffix {
    // txt
    NSArray *txtSuffixArray = @[@".txt"];
    // image
    NSArray *imageSuffixArray = @[@".jpg",
                                  @".png",
                                  @".jpeg",
                                  @".webp",
                                  @".bmp",
                                  @".ico",
                                  @".gif",
                                  @".heic",
                                  @".heif"];
    // doc
    NSArray *docSuffixArray = @[@".doc",
                                @".docx"];
    
    // web doc
    NSArray *webDocSuffixArray = @[@".zip"];
    
    // pdf
    NSArray *pdfSuffixArray = @[@".pdf"];
    // xls
    NSArray *xlsSuffixArray = @[@".xls",
                                @".xlsx"];
    // ppt
    NSArray *pptSuffixArray = @[@".ppt",
                                @".pptx"];
    // audio mp3、wma、wav、mid、midd、kar、ogg、m4a、ra、ram、mod
    NSArray *audioSuffixArray = @[@".mp3",
                                  @".wma",
                                  @".wav",
                                  @".mid",
                                  @".midd",
                                  @".kar",
                                  @".m4a",
                                  @".ra",
                                  @".ram",
                                  @".flac",
                                  @".au",
                                  @".ogg",
                                  @".aac",
                                  @".pcm",
                                  @".arm",
                                  @".mod"];
    // video wmv、avi、dat、asf、rm、rmvb、ram、mpg、mpeg、3gp、mov、mp4、m4v、dvix、dv、mkv、flv、vob、qt、divx、cpk、fli、flc、mod
    NSArray *videoSuffixArray = @[@".wmv",
                                  @".avi",
                                  @".dat",
                                  @".asf",
                                  @".rm",
                                  @".rmvb",
                                  @".ram",
                                  @".mpg",
                                  @".mpeg",
                                  @".3gp",
                                  @".mov",
                                  @".mp4",
                                  @".m4v",
                                  @".dvix",
                                  @".dv",
                                  @".mkv",
                                  @".flv",
                                  @".vob",
                                  @".qt",
                                  @".divx",
                                  @".cpk",
                                  @".fli",
                                  @".flc"];
    
    
    if ([self compareSuffix:suffix withSuffixArray:txtSuffixArray]) {
        self.type = BJLIcDocumentFileTXT;
    }
    else if ([self compareSuffix:suffix withSuffixArray:imageSuffixArray]) {
        self.type = BJLIcDocumentFileImage;
    }
    else if ([self compareSuffix:suffix withSuffixArray:docSuffixArray]) {
        self.type = BJLIcDocumentFileDOC;
    }
    else if ([self compareSuffix:suffix withSuffixArray:pdfSuffixArray]) {
        self.type = BJLIcDocumentFilePDF;
    }
    else if ([self compareSuffix:suffix withSuffixArray:xlsSuffixArray]) {
        self.type = BJLIcDocumentFileXLS;
    }
    else if ([self compareSuffix:suffix withSuffixArray:pptSuffixArray]) {
        self.type = BJLIcDocumentFileNormalPPT;
    }
    else if ([self compareSuffix:suffix withSuffixArray:webDocSuffixArray]) {
        self.type = BJLIcDocumentFileWebPPT;
    }
    else if ([self compareSuffix:suffix withSuffixArray:audioSuffixArray]) {
        self.type = BJLIcDocumentFileAudio;
    }
    else if ([self compareSuffix:suffix withSuffixArray:videoSuffixArray]) {
        self.type = BJLIcDocumentFileVideo;
    }
    // default
    else {
        self.type = BJLIcDocumentFileTypeDefault;
    }
    self.mimeType = BJLMimeTypeForPathExtension(self.url.absoluteString.pathExtension);
}

- (BOOL)compareSuffix:(NSString *)suffix withSuffixArray:(NSArray <NSString *>*)suffixArray {
    BOOL flag = NO;
    for (NSString *targetSuffix in suffixArray) {
        if ([suffix compare:targetSuffix options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            flag = YES;
            break;
        }
    }
    return flag;
}

@end

NS_ASSUME_NONNULL_END
