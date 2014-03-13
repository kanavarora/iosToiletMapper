//
//  TMPPersistenceManager.m
//  toiletmapper
//
//  Created by Kanav Arora on 3/10/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import "TMPPersistenceManager.h"

#import "TMPToilet.h"

@interface TMPPersistenceManager ()

@property (nonatomic, readwrite, strong) NSManagedObjectContext *context;

@end

@implementation TMPPersistenceManager

- (id) initWithContext:(NSManagedObjectContext *)context {
    if (self  = [super init]) {
        _context = context;
    }
    return self;
}

- (int)reviewedStarsForToilet:(TMPToilet *)tmpToilet {
    NSString *toiletGeohash = tmpToilet.geohash;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PersistentReview" inManagedObjectContext:self.context];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [self.context executeFetchRequest:fetchRequest error:nil];
    int stars = -1;
    for (NSManagedObject *info in fetchedObjects) {
        NSString *geohash = [info valueForKey:@"geohash"];
        if ([geohash isEqualToString:toiletGeohash]) {
            return [[info valueForKey:@"stars"] intValue];
        }
    }
    
    return stars;
}

- (void)storeReviewForToilet:(TMPToilet *)tmpToilet stars:(int)stars {
    NSManagedObjectContext *context = self.context;
    NSManagedObject *persistentReview = [NSEntityDescription
                                       insertNewObjectForEntityForName:@"PersistentReview"
                                       inManagedObjectContext:context];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    [persistentReview setValue:tmpToilet.geohash forKey:@"geohash"];
    [persistentReview setValue:@(stars) forKey:@"stars"];
    [persistentReview setValue:@(currentTime) forKey:@"time"];
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

- (BOOL)reportedForToilet:(TMPToilet *)tmpToilet {
    NSString *toiletGeohash = tmpToilet.geohash;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PersistentReport" inManagedObjectContext:self.context];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [self.context executeFetchRequest:fetchRequest error:nil];
    for (NSManagedObject *info in fetchedObjects) {
        NSString *geohash = [info valueForKey:@"geohash"];
        if ([geohash isEqualToString:toiletGeohash]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)storeReportForToilet:(TMPToilet *)tmpToilet {
    NSManagedObjectContext *context = self.context;
    NSManagedObject *persistentReview = [NSEntityDescription
                                         insertNewObjectForEntityForName:@"PersistentReport"
                                         inManagedObjectContext:context];
    double currentTime = [[NSDate date] timeIntervalSince1970];
    [persistentReview setValue:tmpToilet.geohash forKey:@"geohash"];
    [persistentReview setValue:@(currentTime) forKey:@"time"];
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

@end
