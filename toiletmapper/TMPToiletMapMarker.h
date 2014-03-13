//
//  TMPToiletMapMarker.h
//  toiletmapper
//
//  Created by Kanav Arora on 3/9/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

@class TMPToilet;

@interface TMPToiletMapMarker : GMSMarker

@property (nonatomic, readwrite, strong) TMPToilet *tmpToilet;

@end


@interface TMPNewToiletMapMarker : GMSMarker

@end