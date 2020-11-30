//
//  NSObject+Loader.m
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

#import "NSObject+Loader.h"
#import <FantasmoSDK/FantasmoSDK-Swift.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@implementation NSObject (Loader)

#if DEBUG
    static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
    static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

+ (void)load {
    [DDLog addLogger:[DDOSLogger sharedInstance]];
    DDLogInfo(@"Fantasmo SDK initialized");
    [FMLoader swiftyLoad];
}

@end
