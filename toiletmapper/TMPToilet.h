//
//  TMPToilet.h
//  toiletmapper
//
//  Created by Kanav Arora on 3/3/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMPToilet : NSObject

@property (nonatomic, readonly, assign) float longitude;
@property (nonatomic, readonly, assign) float latitude;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *address;
@property (nonatomic, readonly, strong) NSString *geohash;
@property (nonatomic, readonly, assign) int totalStars;
@property (nonatomic, readonly, assign) int totalReviews;

- (id)initWithProperties:(NSDictionary *)properties;

- (void)updateStars:(int)totalStars reviews:(int)totalReviews;
- (NSString *)trimmedGeohash;
+ (NSString *)trimmedGeohash:(NSString *)geohash;
- (float)rating;

@end
