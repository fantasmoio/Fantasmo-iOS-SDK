//
//  NSObject+Loader.m
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

#import "NSObject+Loader.h"
#import <FantasmoSDK/FantasmoSDK-Swift.h>

@implementation NSObject (Loader)

+ (void)load {
    NSLog(@"Fantasmo SDK initialized");
    [FMLoader swiftyLoad];
}

@end
