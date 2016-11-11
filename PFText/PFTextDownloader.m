//
//  PFTextDownloader.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextDownloader.h"
#import <objc/runtime.h>

NSString * const SESSION_DEFAULT_IDENTIFIER = @"https://github.com/LongPF";



/**
 扩展NSURLSessionTask,添加回调
 */
@interface NSURLSessionTask (pf_addition)

@property (nonatomic, copy) void(^downloadProgress)(int64_t totalBytesWritten,int64_t totalBytesExpectedToWrite, double progress);
@property (nonatomic, copy) void(^completeHandler)(NSURLSession *session,NSURLSessionTask *task,NSURL *filePath);
@property (nonatomic, copy) void(^errorHandler)(NSURLSession *session,NSURLSessionTask *task,NSError *error);

@end





@interface PFTextDownloader ()<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation PFTextDownloader

+ (instancetype)defaultDownloader
{
    static PFTextDownloader *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[PFTextDownloader alloc]init];
    });
    return downloader;
}


#pragma mark - interface method

- (NSURLSessionDownloadTask *)pf_downloadTaskWithURL:(NSURL *)url downloadProgress:(void (^)(int64_t, int64_t, double))downloadProgress completeHandler:(void (^)(NSURLSession *, NSURLSessionTask *, NSURL *))completeHandler errorHandler:(void (^)(NSURLSession *, NSURLSessionTask *, NSError *))errorHandler
{
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:url];
    task.downloadProgress = downloadProgress;
    task.completeHandler = completeHandler;
    task.errorHandler = errorHandler;
    [task resume];
    return task;
}

- (NSURLSessionDownloadTask *)pf_downloadTaskWithRequest:(NSURLRequest *)request downloadProgress:(void (^)(int64_t, int64_t, double))downloadProgress completeHandler:(void (^)(NSURLSession *, NSURLSessionTask *, NSURL *))completeHandler errorHandler:(void (^)(NSURLSession *, NSURLSessionTask *, NSError *))errorHandler
{
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:request];
    task.downloadProgress = downloadProgress;
    task.completeHandler = completeHandler;
    task.errorHandler = errorHandler;
    [task resume];
    return task;
}

- (NSURLSessionDownloadTask *)pf_downloadTaskWithResumeData:(NSData *)resumeData downloadProgress:(void (^)(int64_t, int64_t, double))downloadProgress completeHandler:(void (^)(NSURLSession *, NSURLSessionTask *, NSURL *))completeHandler errorHandler:(void (^)(NSURLSession *, NSURLSessionTask *, NSError *))errorHandler
{
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithResumeData:resumeData];
    task.downloadProgress = downloadProgress;
    task.completeHandler = completeHandler;
    task.errorHandler = errorHandler;
    [task resume];
    return task;
}


#pragma mark - NSURLSessionDownloadTask delegate / NSURLSession delegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    if (downloadTask.completeHandler) {
        downloadTask.completeHandler(session,downloadTask,location);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if (downloadTask.downloadProgress) {
        downloadTask.downloadProgress(totalBytesWritten,totalBytesExpectedToWrite,(double)totalBytesWritten/totalBytesExpectedToWrite);
    }
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && task.errorHandler) {
        task.errorHandler(session,task,error);
    }
}

#pragma mark - getters/ setters

- (NSURLSession *)session
{
    if (!_session) {
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        cfg.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        cfg.sessionSendsLaunchEvents = YES;
        cfg.discretionary = YES;
        _session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue new]];
    }
    return _session;
}

@end




@implementation NSURLSessionTask (pf_addition)


- (void (^)(int64_t, int64_t, double))downloadProgress
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setDownloadProgress:(void (^)(int64_t, int64_t, double))downloadProgress
{
    objc_setAssociatedObject(self, @selector(downloadProgress), downloadProgress, OBJC_ASSOCIATION_RETAIN);
}

- (void (^)(NSURLSession *, NSURLSessionTask *, NSURL *))completeHandler
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCompleteHandler:(void (^)(NSURLSession *, NSURLSessionTask *, NSURL *))completeHandler
{
    objc_setAssociatedObject(self, @selector(completeHandler), completeHandler, OBJC_ASSOCIATION_RETAIN);
}

- (void (^)(NSURLSession *, NSURLSessionTask *, NSError *))errorHandler
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setErrorHandler:(void (^)(NSURLSession *, NSURLSessionTask *, NSError *))errorHandler
{
    objc_setAssociatedObject(self, @selector(errorHandler), errorHandler, OBJC_ASSOCIATION_RETAIN);
}


@end
