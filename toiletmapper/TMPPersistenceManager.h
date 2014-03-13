//
//  TMPPersistenceManager.h
//  toiletmapper
//
//  Created by Kanav Arora on 3/10/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMPToilet;
@interface TMPPersistenceManager : NSObject

- (id) initWithContext:(NSManagedObjectContext *)context;

- (int)reviewedStarsForToilet:(TMPToilet *)tmpToilet;
- (void)storeReviewForToilet:(TMPToilet *)tmpToilet stars:(int)stars;
- (BOOL)reportedForToilet:(TMPToilet *)tmpToilet;
- (void)storeReportForToilet:(TMPToilet *)tmpToilet;

@end
