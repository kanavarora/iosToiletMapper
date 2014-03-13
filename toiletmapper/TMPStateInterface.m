//
//  TMPStateInterface.m
//  toiletmapper
//
//  Created by Kanav Arora on 3/10/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import "TMPStateInterface.h"

TMPStateInterface *globalStateInterface;

@implementation TMPStateInterface

- (id)init {
    if (self = [super init]) {
        _seedingHelper = [[TMPSeedingHelper alloc] init];
        _serverManager = [[TMPServerManager alloc] init];
    }
    return self;
}
@end
