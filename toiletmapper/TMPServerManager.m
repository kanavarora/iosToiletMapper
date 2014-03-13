//
//  TMPServerManager.m
//  toiletmapper
//
//  Created by Kanav Arora on 3/7/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import "TMPServerManager.h"

#import "ASIHTTPRequest.h"
#import "GNGeoHash.h"
#import "TMPToilet.h"
#import "TMPSeedingHelper.h"
#import "TMPConstants.h"
#import "ASIFormDataRequest.h"

@interface TMPServerManager ()

@property (nonatomic, readwrite, strong) NSMutableDictionary *cachedToiletResults;

@end


@implementation TMPServerManager

- (id)init {
    if (self = [super init]) {
        _cachedToiletResults = [NSMutableDictionary dictionary];
    }
    return self;
}
- (void)getAllToiletsWithSuccess:(void(^)(NSArray *tmpToilets))success
                         failure:(void(^)())failure {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kBaseUrl, kGetAllToiletsEndpoint];
    NSURL *url = [NSURL URLWithString:urlString];
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{
        // Use when fetching binary data
        NSData *responseData = [request responseData];
        NSArray *serailizedToilets = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
        NSLog(@"%@", serailizedToilets);
        NSMutableArray *tmpToilets = [NSMutableArray array];
        for (NSDictionary *toiletProperties in serailizedToilets) {
            TMPToilet *toilet = [[TMPToilet alloc] initWithProperties:toiletProperties];
            [tmpToilets addObject:toilet];
        }
        success(tmpToilets);
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"%@", error);
        failure();
    }];
    [request startAsynchronous];
}

- (void)getNearbyToilets:(float)latitude
               longitude:(float)longitude
                 success:(void(^)(NSArray *tmpToilets, BOOL didRefresh))success
                 failure:(void(^)())failure {
    
    GNGeoHash *gh = [GNGeoHash withCharacterPrecision:latitude andLongitude:longitude andNumberOfCharacters:12];
    //print the result
    NSString *geohash = [gh toBase32];
    [self getNearbyToiletsForGeoHash:geohash success:success failure:failure];
}

- (void)getNearbyToiletsForGeoHash:(NSString *)geohash
                           success:(void(^)(NSArray *tmpToilets, BOOL didRefresh))success
                           failure:(void(^)())failure {
    if (geohash.length > kGeohashPrefixLength) {
        geohash = [geohash substringToIndex:kGeohashPrefixLength];
    }
    
    double currentTime = [[NSDate date] timeIntervalSince1970];
    // see if its cached already
    if (self.cachedToiletResults[geohash]) {
        double timeOfCachedResult = [self.cachedToiletResults[geohash][@"time"] doubleValue];
        if (currentTime - timeOfCachedResult > kStaleTimeForCachedToilets) {
            [self.cachedToiletResults removeObjectForKey:geohash];
        } else {
            NSArray* toilets = self.cachedToiletResults[geohash][@"toilets"];
            success(toilets, YES);
            return;
        }
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kBaseUrl, kGetNearbyToiletsEndpoint];
    NSDictionary *params = @{@"geohash": geohash};
    NSURL *url = [NSURL URLWithString:[TMPSeedingHelper constructGetUrlWithBaseUrl:urlString andParameters:params]];
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{
        // Use when fetching binary data
        NSData *responseData = [request responseData];
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
        NSLog(@"%@", response);
        if (response[@"error"]) {
            NSLog(response[@"error"]);
            failure();
        } else {
            NSArray *serializedToilets = response[@"toilets"];
            NSMutableArray *tmpToilets = [NSMutableArray array];
            for (NSDictionary *toiletProperties in serializedToilets) {
                TMPToilet *toilet = [[TMPToilet alloc] initWithProperties:toiletProperties];
                [tmpToilets addObject:toilet];
            }
            self.cachedToiletResults[geohash]= @{@"time": @(currentTime),
                                                 @"toilets" : tmpToilets};
            success(tmpToilets, NO);
        }
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"%@", error);
        failure();
    }];
    
    [request startAsynchronous];
}

- (void)rateToilet:(TMPToilet *)toilet withStars:(int)stars {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kBaseUrl, kRateToiletEndpoint];
    NSString *userId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSDictionary *params = @{@"geohash": toilet.geohash,
                             @"stars" : @(stars),
                             @"userId" : userId?userId:@""};
    NSURL *url = [NSURL URLWithString:[TMPSeedingHelper constructGetUrlWithBaseUrl:urlString andParameters:params]];
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{
        // Use when fetching binary data
        NSData *responseData = [request responseData];
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
        NSLog(@"%@", response);
        if (response[@"error"]) {
            NSLog(response[@"error"]);
        } else {
            int totalStars = [response[@"stars"] intValue];
            int totalReviews = [response[@"reviews"] intValue];
            if (totalReviews > 0 && totalStars > 0) {
                [toilet updateStars:totalStars reviews:totalReviews];
            }
        }
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"%@", error);
    }];
    
    [request startAsynchronous];
}

- (void)reportToilet:(TMPToilet *)toilet {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kBaseUrl, kReportToiletEndpoint];
    NSString *userId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSDictionary *params = @{@"geohash": toilet.geohash,
                             @"userId": userId?userId:@""};
    NSURL *url = [NSURL URLWithString:[TMPSeedingHelper constructGetUrlWithBaseUrl:urlString andParameters:params]];
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{
        // Use when fetching binary data
        NSData *responseData = [request responseData];
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
        NSLog(@"%@", response);
        if (response[@"error"]) {
            NSLog(response[@"error"]);
        }
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"%@", error);
    }];
    
    [request startAsynchronous];
}

- (void)addToiletWithName:(NSString *)name
               atLatitude:(float)latitude
                longitude:(float)longitude
                  success:(void(^)())success
                  failure:(void(^)(NSString *reason))failure {
    NSString *userId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kBaseUrl, kAddToiletEndpoint];
    NSURL *url = [NSURL URLWithString:urlString];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setRequestMethod:@"POST"];
    [request setPostValue:name forKey:@"name"];
    [request setPostValue:@(latitude) forKey:@"latitude"];
    [request setPostValue:@(longitude) forKey:@"longitude"];
    [request setPostValue:userId?userId:@"" forKey:@"userId"];
    
    [request setCompletionBlock:^{
        // Use when fetching binary data
        NSData *responseData = [request responseData];
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
        NSLog(@"%@", response);
        if (response[@"error"]) {
            NSLog(response[@"error"]);
            failure(response[@"error"]);
        } else {
            success();
        }
    }];
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"%@", error);
        failure(@"Internet error");
    }];
    
    [request startAsynchronous];
}
@end
