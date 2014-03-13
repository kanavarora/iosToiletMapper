//
//  TMPSeedingHelper.m
//  toiletmapper
//
//  Created by Kanav Arora on 3/4/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import "TMPSeedingHelper.h"

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "TMPConstants.h"

@interface TMPSearchResult ()

@property (nonatomic, readwrite, strong) NSString *resultId;
@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, assign) float latitude;
@property (nonatomic, readwrite, assign) float longitude;
@property (nonatomic, readwrite, strong) NSString *address;

@end

@implementation TMPSearchResult

@end

@interface TMPSeedingHelper ()

@property (nonatomic, readwrite, strong) NSMutableDictionary *allResults;
@property (nonatomic, readwrite, assign) int pendingQueries;

@end

@implementation TMPSeedingHelper

+ (NSString *)constructGetUrlWithBaseUrl:(NSString *)baseUrl andParameters:(NSDictionary *)params {
    NSString *paramsString = @"";
    for (NSString *key in params) {
        NSString *value = params[key];
        paramsString = [NSString stringWithFormat:@"%@%@=%@&", paramsString, key, value];
    }
    
    NSString *fullUrl = [NSString stringWithFormat:@"%@%@", baseUrl, paramsString];
    return fullUrl;
}

- (id)init {
    if (self = [super init]) {
        _allResults = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)storeToiletsForDelhiRegion {
    [self getToiletsBetweenMinLatitude:28.38 maxLatitude:28.90 minLongitude:76.82 maxLongitude:77.43];
}

- (void)getToiletsBetweenMinLatitude:(float)minLatitude
                         maxLatitude:(float)maxLatitude
                        minLongitude:(float)minLongitude
                        maxLongitude:(float)maxLongitude {
    float degIncrement = 0.05f;
    for (float lat = minLatitude; lat<= maxLatitude; lat += degIncrement) {
        for (float lon = minLongitude; lon<=maxLongitude; lon += degIncrement) {
            self.pendingQueries++;
            [self getToiletsNearLatitude:lat longitude:lon radius:5000];
        }
    }
}


#define kPlacesBaseUrl @"https://maps.googleapis.com/maps/api/place/textsearch/json?"
#define kPlacesApiKey @"AIzaSyC7DnuCdJfnsu-sjxbPsvojVOE_atiCNGM"

- (void)getToiletsNearLatitude:(float)latitude
                     longitude:(float)longitude
                        radius:(float)radiusInMeters {
    NSString *locationParam = [NSString stringWithFormat:@"%.4f,%.4f", latitude, longitude];
    NSDictionary *params = @{
                             @"key" : kPlacesApiKey,
                             @"location" : locationParam,
                             @"radius" : @(radiusInMeters),
                             @"sensor" : @"false",
                             @"query" : @"toilet",
                             };
    
    NSString *urlString = [TMPSeedingHelper constructGetUrlWithBaseUrl:kPlacesBaseUrl
                                                   andParameters:params];
    NSURL *url = [NSURL URLWithString:urlString];
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    [request setCompletionBlock:^{
        
        NSData *responseData = [request responseData];
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:nil];
        if ([responseDict[@"status"] isEqualToString:@"OK"]) {
            NSArray *resultsArray = responseDict[@"results"];
            for (NSDictionary *serializedResult in resultsArray) {
                [self parseSerializedResult:serializedResult];
            }
        }else {
            NSLog(responseDict[@"status"]);
        }
        self.pendingQueries--;
        NSLog(@"Progress - %d", self.pendingQueries);
        if (self.pendingQueries == 0) {
            [self storeSearchResults];
        }
    }];

    
    [request setFailedBlock:^{
        NSError *error = [request error];
        NSLog(@"%@", error);
        NSLog(@"Progress - %d", self.pendingQueries);
        self.pendingQueries--;
        if (self.pendingQueries == 0) {
            [self storeSearchResults];
        }
    }];
    
    [request startAsynchronous];
}

- (void)parseSerializedResult:(NSDictionary *)serializedResult {
    NSString *resultId = serializedResult[@"id"];
    if (resultId) {
        float latitude = [serializedResult[@"geometry"][@"location"][@"lat"] floatValue];
        float longitude = [serializedResult[@"geometry"][@"location"][@"lng"] floatValue];
        NSString *name = serializedResult[@"name"]?serializedResult[@"name"]:@"";
        if ([name rangeOfString:@"toilet" options:NSCaseInsensitiveSearch].location == NSNotFound) {
            return; // no toilet in name
        }
        NSString *address = serializedResult[@"formatted_address"]?serializedResult[@"formatted_address"]:@"";
        TMPSearchResult *searchResult = [[TMPSearchResult alloc] init];
        searchResult.resultId = resultId;
        searchResult.name = name;
        searchResult.latitude = latitude;
        searchResult.longitude = longitude;
        searchResult.address = address;
        if (!self.allResults[resultId]) {
            self.allResults[resultId] = searchResult;
        }
    }
}

- (void)storeSearchResults {
    NSMutableArray *serializedResults = [NSMutableArray array];
    for (NSString *key in self.allResults) {
        TMPSearchResult *searchResult = self.allResults[key];
        NSDictionary *serializedResult = @{@"lat" : @(searchResult.latitude),
                                           @"lon" : @(searchResult.longitude),
                                           @"name" : searchResult.name,
                                           @"address" : searchResult.address,
                                           @"resultId" : searchResult.resultId};
        [serializedResults addObject:serializedResult];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:serializedResults options:kNilOptions error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kBaseUrl, kSeedingGmapsEndpoint];
    NSURL *url = [NSURL URLWithString:urlString];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setRequestMethod:@"POST"];
    [request setPostValue:jsonString forKey:@"toilets"];
    [request startAsynchronous];
}


@end

