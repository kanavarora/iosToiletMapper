//
//  TMPServerManager.h
//  toiletmapper
//
//  Created by Kanav Arora on 3/7/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMPToilet;
@interface TMPServerManager : NSObject

- (void)getAllToiletsWithSuccess:(void(^)(NSArray *tmpToilets))success
                         failure:(void(^)())failure;
- (void)getNearbyToilets:(float)latitude
               longitude:(float)longitude
                 success:(void(^)(NSArray *tmpToilets, BOOL didRefresh))success
                 failure:(void(^)())failure;
- (void)rateToilet:(TMPToilet *)toilet withStars:(int)stars;
- (void)reportToilet:(TMPToilet *)toilet;
- (void)addToiletWithName:(NSString *)name
               atLatitude:(float)latitude
                longitude:(float)longitude
                  success:(void(^)())success
                  failure:(void(^)(NSString *reason))failure;
@end
