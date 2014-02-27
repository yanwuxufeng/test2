//
//  UIWebViewThreadManager.h
//  mtt
//
//  Created by fengfengxu on 12-8-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <mach/mach.h>

@interface UIWebViewThreadManager : NSObject
{
    pthread_t   mainThread;
    thread_t    webThread;
    BOOL        checkThreadNeedRun;
    int         webThreadSuspendCount;
    BOOL        isWebThreadRunning;
    NSThread    *monitorThread;
}

@property(atomic, assign)int webThreadSuspendCount;
@property(atomic, assign)BOOL checkThreadNeedRun;
@property(atomic, assign)BOOL isWebThreadRunning;

+(id)shareInstance;
-(void)suspendWebThread;
-(void)resumeWebThread;

@end
