//
//  TMPStateInterface.h
//  toiletmapper
//
//  Created by Kanav Arora on 3/10/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMPPersistenceManager.h"
#import "TMPSeedingHelper.h"
#import "TMPServerManager.h"

@interface TMPStateInterface : NSObject

@property (nonatomic, readwrite, strong) TMPPersistenceManager *persistenceManager;
@property (nonatomic, readwrite, strong) TMPServerManager *serverManager;
@property (nonatomic, readwrite, strong) TMPSeedingHelper *seedingHelper;

@end

extern TMPStateInterface *globalStateInterface;
