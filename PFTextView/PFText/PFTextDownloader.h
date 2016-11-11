//
//  PFTextDownloader.h
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PFTextDownloader : NSObject

#define PFDownloader [PFTextDownloader defaultDownloader]

+ (instancetype)defaultDownloader;


//这三个方法内部已经实现resume方法
- (NSURLSessionDownloadTask *)pf_downloadTaskWithURL:(NSURL *)url
                                    downloadProgress:(void(^)(int64_t totalBytesWritten,int64_t totalBytesExpectedToWrite, double progress))downloadProgress
                                     completeHandler:(void(^)(NSURLSession *session,NSURLSessionTask *task,NSURL *filePath))completeHandler
                                        errorHandler:(void(^)(NSURLSession *session,NSURLSessionTask *task,NSError *error))errorHandler;

- (NSURLSessionDownloadTask *)pf_downloadTaskWithRequest:(NSURLRequest *)request
                                        downloadProgress:(void(^)(int64_t totalBytesWritten,int64_t totalBytesExpectedToWrite, double progress))downloadProgress
                                         completeHandler:(void(^)(NSURLSession *session,NSURLSessionTask *task,NSURL *filePath))completeHandler
                                            errorHandler:(void(^)(NSURLSession *session,NSURLSessionTask *task,NSError *error))errorHandler;

- (NSURLSessionDownloadTask *)pf_downloadTaskWithResumeData:(NSData *)resumeData
                                           downloadProgress:(void(^)(int64_t totalBytesWritten,int64_t totalBytesExpectedToWrite, double progress))downloadProgress
                                            completeHandler:(void(^)(NSURLSession *session,NSURLSessionTask *task,NSURL *filePath))completeHandler
                                               errorHandler:(void(^)(NSURLSession *session,NSURLSessionTask *task,NSError *error))errorHandler;

@end
