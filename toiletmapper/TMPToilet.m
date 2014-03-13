//
//  TMPToilet.m
//  toiletmapper
//
//  Created by Kanav Arora on 3/3/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import "TMPToilet.h"
#import "TMPConstants.h"

@interface TMPToilet ()

@property (nonatomic, readwrite, assign) float longitude;
@property (nonatomic, readwrite, assign) float latitude;
@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSString *address;
@property (nonatomic, readwrite, strong) NSString *geohash;
@property (nonatomic, readwrite, assign) int totalStars;
@property (nonatomic, readwrite, assign) int totalReviews;

@end

@implementation TMPToilet

- (id)initWithProperties:(NSDictionary *)properties {
    if (self = [super init]) {
        _name  = properties[@"name"];
        _address = properties[@"address"];
        _geohash = properties[@"geohash"];
        _latitude = [properties[@"lat"] floatValue];
        _longitude = [properties[@"lon"] floatValue];
        _totalStars = [properties[@"stars"] intValue];
        _totalReviews = [properties[@"reviews"] intValue];
    }
    return self;
}

- (void)updateStars:(int)totalStars reviews:(int)totalReviews {
    self.totalReviews = totalReviews;
    self.totalStars = totalStars;
}

- (NSString *)trimmedGeohash {
    return [TMPToilet trimmedGeohash:self.geohash];
}

+ (NSString *)trimmedGeohash:(NSString *)geohash {
    if (geohash.length > kGeohashPrefixLength) {
        return [geohash substringToIndex:kGeohashPrefixLength];
    } else {
        return geohash;
    }
}

- (float)rating {
    if (self.totalReviews <= 0) {
        return 0.0f;
    } else {
        return (float)self.totalStars/self.totalReviews;
    }
}

@end
