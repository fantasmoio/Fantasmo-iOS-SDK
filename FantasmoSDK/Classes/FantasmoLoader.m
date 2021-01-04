//
//  NSObject+Loader.m
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

#import "FantasmoLoader.h"
#import <FantasmoSDK/FantasmoSDK-Swift.h>

@implementation FantasmoLoader: NSObject

+ (void)load {
    NSLog(@"Fantasmo SDK initialized");
    [FMLoader swiftyLoad];
}

@end
