//
//  TMPSeedingHelper.h
//  toiletmapper
//
//  Created by Kanav Arora on 3/4/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMPSeedingHelper : NSObject
@property (nonatomic, readonly, strong) NSMutableDictionary *allResults;

+ (NSString *)constructGetUrlWithBaseUrl:(NSString *)baseUrl andParameters:(NSDictionary *)params;
- (void)storeToiletsForDelhiRegion;
- (void)storeSearchResults;

@end

@interface TMPSearchResult : NSObject

@property (nonatomic, readonly, strong) NSString *resultId;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, assign) float latitude;
@property (nonatomic, readonly, assign) float longitude;
@property (nonatomic, readonly, strong) NSString *address;

@end
