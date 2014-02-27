//
//  UIWebViewThreadManager.m
//  mtt
//
//  Created by fengfengxu on 12-8-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "UIWebViewThreadManager.h"
#import <mach/mach.h>

//#define NSLog(...) 

#define CHECKTHREADSLEEPPERIOD  0.01   // 单位 s
#define ThreadNameMaxLen        256

static UIWebViewThreadManager *gUIWebViewThreadManager = nil;

@interface UIWebViewThreadManager (UIWebViewThreadManagerPrivate)

-(BOOL)suspendWebThreadInternal;
-(BOOL)resumeWebThreadInternal;
-(thread_t)getWebThread;
-(void)checkMainThreadBlocked;
-(BOOL)mainThreadIsBlocked;
-(BOOL)threadIsBlock:(pthread_t)thread;
-(void)startMonitorThread;
-(void)stopMonitorThread;
@end


@implementation UIWebViewThreadManager

@synthesize webThreadSuspendCount;
@synthesize checkThreadNeedRun;
@synthesize isWebThreadRunning;

-(id)init
{
    if(self =[super init])
    {
        if (pthread_main_np()) {
            mainThread = pthread_self(); 
            self.isWebThreadRunning = YES;
        }
    }
    
    return self;
}

+(id)shareInstance
{
    if (gUIWebViewThreadManager == nil) {
        @synchronized(self) 
        {
            if (gUIWebViewThreadManager == nil) {
                gUIWebViewThreadManager = [[UIWebViewThreadManager alloc] init];
            }
        }
    }
    
    return gUIWebViewThreadManager;
}

-(void)suspendWebThread
{
    if (self.webThreadSuspendCount > 0) {
        self.webThreadSuspendCount++;
    }else{
        [self suspendWebThreadInternal];
        [self startMonitorThread];
        self.webThreadSuspendCount = 1;
    }
}


-(void)resumeWebThread
{
    dispatch_sync(dispatch_queue_create("resumeWebTrhead", 0), ^{
        if (self.webThreadSuspendCount == 1) {
            [self resumeWebThreadInternal];
            [self stopMonitorThread];
            self.webThreadSuspendCount = 0;
        }else {
            self.webThreadSuspendCount--;
        }

    });
}

#pragma mark privateAPI

-(BOOL)threadIsBlock:(pthread_t) thread
{
    thread_basic_info_t    basic_info_t;
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    BOOL isBlocked = NO;
    
    thread_info_count = THREAD_INFO_MAX;
    kern_return_t kr = thread_info(pthread_mach_thread_np(thread), THREAD_BASIC_INFO,
                                   (thread_info_t)thinfo, &thread_info_count);
    if (kr != KERN_SUCCESS) {
        return isBlocked;
    }
    
    basic_info_t = (thread_basic_info_t)thinfo;
    isBlocked = basic_info_t->run_state != TH_STATE_RUNNING;
    
    NSLog(@"run_state = [%d]", basic_info_t->run_state);
    NSLog(@"ThreadIsBlock isBlocked = [%d]", isBlocked);
    
    return isBlocked;
}


- (BOOL)mainThreadIsBlocked{
    return [self threadIsBlock:mainThread];
}


- (void)checkMainThreadBlocked{
    
    while (self.checkThreadNeedRun){
        if ([self mainThreadIsBlocked]) {
            [self resumeWebThreadInternal];
        } else {
            if (self.isWebThreadRunning) {
                [self suspendWebThreadInternal];
            }
        }
        sleep(CHECKTHREADSLEEPPERIOD);
    }
    [self resumeWebThreadInternal];    
}

-(void)startMonitorThread
{
    if (monitorThread) {
        [monitorThread cancel];
        [monitorThread release];
        monitorThread = nil;
    }
    
    self.checkThreadNeedRun = YES;
    monitorThread = [[NSThread alloc] initWithTarget:self selector:@selector(checkMainThreadBlocked) object:nil];
    [monitorThread start];
    
}

-(void)stopMonitorThread
{
    self.checkThreadNeedRun = NO;
    if (monitorThread) {
        [monitorThread cancel];
        [monitorThread release];
        monitorThread = nil;
    }
}


-(void)initWebThread
{
    task_t selfTask = mach_task_self();
    thread_act_array_t threads;
    mach_msg_type_number_t thread_count;
    
    if (task_threads(selfTask, &threads, &thread_count) != KERN_SUCCESS) {
        thread_count = 0;
    }
    
    for(mach_msg_type_number_t i = 0; i < thread_count; i++)
    {
        pthread_t pthread = pthread_from_mach_thread_np(threads[i]);
        char name[ThreadNameMaxLen] = {0};
        pthread_getname_np(pthread, name, ThreadNameMaxLen);
        
        if(strcmp(name, "WebThread") == 0)
        {
            NSLog(@"getWebThread = [%x]", threads[i]);
            webThread =  threads[i];
        }
    }

}


-(thread_t)getWebThread
{
    if (!webThread) {
        [self initWebThread];
    } 
    return webThread;
}


-(BOOL)suspendWebThreadInternal
{
    @synchronized(gUIWebViewThreadManager)
    { 
        NSLog(@"suspendWebThreadInternal start");
        
        BOOL isSuccess = NO;
        if (self.isWebThreadRunning) 
        {
            if([self getWebThread]&&
               (thread_suspend(webThread) == KERN_SUCCESS))
            {
                isSuccess = YES;
                self.isWebThreadRunning = NO;
            }
        }

        NSLog(@"suspendWebThreadInternal isSuccess = [%d]", isSuccess);
        return isSuccess;
    }
}

-(BOOL)resumeWebThreadInternal
{    
    @synchronized(gUIWebViewThreadManager)
    { 
        BOOL isSuccess = NO;
        NSLog(@"resumeWebThreadInternal tart");

        if(!self.isWebThreadRunning)
        {
            if([self getWebThread] &&
               (thread_resume(webThread) == KERN_SUCCESS))
            {
                isSuccess = YES;
                self.isWebThreadRunning = YES;
            }
        }
        
        
        if (!isSuccess) {
            int i = 0;
            i++;
            NSLog(@"web threadIsBlock = [%d]", [self threadIsBlock:pthread_from_mach_thread_np(webThread)]);
        } 
        NSLog(@"resumeWebThreadInternal isSuccess = [%d]", isSuccess);
        return isSuccess;
    }
}

@end
