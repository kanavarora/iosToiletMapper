//
//  TMPConstants.h
//  toiletmapper
//
//  Created by Kanav Arora on 3/7/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#ifndef toiletmapper_TMPConstants_h
#define toiletmapper_TMPConstants_h

//#define kBaseUrl @"http://localhost:10080/"
#define kBaseUrl @"http://toiletmapper.appspot.com/"
#define kGetAllToiletsEndpoint @"ajax/getAllToilets"
#define kGetNearbyToiletsEndpoint @"ajax/getNearbyToilets?"
#define kRateToiletEndpoint @"ajax/rateToilet?"
#define kReportToiletEndpoint @"ajax/reportToilet?"
#define kAddToiletEndpoint @"ajax/addToilet"
#define kSeedingGmapsEndpoint @"seeding/seedWithToiletsFromGMaps"
#define kGeohashPrefixLength 4
#define kStaleTimeForCachedToilets 12*3600
#define kDefaultZoomFactor 13.0f
#define kMaxNameForToilet 25

#endif
