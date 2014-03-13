//
//  TMPBasicViewController.m
//  toiletmapper
//
//  Created by Kanav Arora on 2/28/14.
//  Copyright (c) 2014 Kanav Arora. All rights reserved.
//

#import "TMPBasicViewController.h"

#import "ASIHTTPRequest.h"
#import <GoogleMaps/GoogleMaps.h>

#import "ASStarRatingView.h"
#import "GNGeoHash.h"
#import "TMPToilet.h"
#import "TMPSeedingHelper.h"
#import "TMPServerManager.h"
#import "TMPConstants.h"
#import "TMPToiletMapMarker.h"
#import "TMPStateInterface.h"

@interface TMPBasicViewController ()

@property (nonatomic, readwrite, weak) IBOutlet GMSMapView *mapView;
@property (nonatomic, readwrite, weak) IBOutlet UIButton *addToiletButton;
@property (nonatomic, readwrite, weak) IBOutlet UIButton *contextMenuHideView;

@property (nonatomic, readwrite, weak) IBOutlet UIView *contextTopView;
@property (nonatomic, readwrite, weak) IBOutlet ASStarRatingView *toiletRating;
@property (nonatomic, readwrite, weak) IBOutlet UILabel *toiletLabel;
@property (nonatomic, readwrite, weak) IBOutlet UILabel *toiletAddress;

@property (nonatomic, readwrite, weak) IBOutlet UIView *contextBottomView;
@property (nonatomic, readwrite, weak) IBOutlet ASStarRatingView *editableToiletRating;
@property (nonatomic, readwrite, weak) IBOutlet UIButton *rateButton;
@property (nonatomic, readwrite, weak) IBOutlet UIButton *reportButton;

@property (nonatomic, readwrite, weak) IBOutlet UIView *addToiletTopMenu;
@property (nonatomic, readwrite, weak) IBOutlet UITextField *nameToiletTextField;
@property (nonatomic, readwrite, weak) IBOutlet UIImageView *addToiletMarker;
@property (nonatomic, readwrite, weak) IBOutlet UIView *loadingView;

@property (nonatomic, readwrite, strong) NSString *currentGeohash;
@property (nonatomic, readwrite, strong) NSMutableDictionary *toiletsToMarker;


@property (nonatomic, readwrite, assign) BOOL isContextMenuActive;
@property (nonatomic, readwrite, strong) TMPToilet *currentActiveToilet;

@property (nonatomic, readwrite, assign) BOOL isAddToiletMenuActive;

@end

@implementation TMPBasicViewController

#define kContextBackgroundColor [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8]
- (void)viewDidLoad {
    [super viewDidLoad];
    self.toiletsToMarker = [[NSMutableDictionary alloc] init];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:27.6
                                                            longitude:76.2
                                                                 zoom:kDefaultZoomFactor];
    self.mapView.camera = camera;

    self.mapView.delegate = self;
    self.mapView.myLocationEnabled = YES;
    self.mapView.settings.myLocationButton = YES;
    NSLog(@"User's location: %@", _mapView.myLocation);
    //self.view = _mapView;
    
    self.contextTopView.backgroundColor = kContextBackgroundColor;
    self.contextBottomView.backgroundColor = kContextBackgroundColor;
    
    self.loadingView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
    
    [self listenForMyLocationChangedProperty];
    //[globalStateInterface.seedingHelper storeToiletsForDelhiRegion];
}

- (void)listenForMyLocationChangedProperty {
    [self.mapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew context: nil];
}

- (void)stopListeningForMyLocationChangedProperty {
     [self.mapView removeObserver:self forKeyPath:@"myLocation"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"myLocation"] && [object isKindOfClass:[GMSMapView class]])
    {
        [self.mapView animateToCameraPosition:[GMSCameraPosition cameraWithLatitude:self.mapView.myLocation.coordinate.latitude
                                                                                 longitude:self.mapView.myLocation.coordinate.longitude
                                                                                      zoom:kDefaultZoomFactor]];
        [self stopListeningForMyLocationChangedProperty];
    }
}

#define kGetAllToiletsEndpoint @"ajax/getAllToilets"
#define kGetNearbyToiletsEndpoint @"ajax/getNearbyToilets?"

- (void)confirmMarkersForNearbyToiletsForLatitude:(float)latitude
                                        longitude:(float)longitude {
    [globalStateInterface.serverManager getNearbyToilets:latitude
                                               longitude:longitude
                                                 success:^(NSArray *tmpToilets, BOOL didRefresh) {
                                                     // if we need refresh, then clear and place again
                                                     if (didRefresh) {
                                                         [self clearAllMarkers];
                                                     }
                                                     for (TMPToilet *tmpToilet in tmpToilets) {
                                                         [self confirmMarkerForToilet:tmpToilet];
                                                     }
                                                 }
                                                 failure:^{
                                                 }];
}

# pragma mark  - place and clear markers
- (void)confirmMarkerForToilet:(TMPToilet *)toilet {
    // see if the marker is already there
    if (self.toiletsToMarker[toilet.geohash]) {
        return;
    }
    TMPToiletMapMarker *marker = [[TMPToiletMapMarker alloc] init];
    marker.tmpToilet = toilet;
    marker.position = CLLocationCoordinate2DMake(toilet.latitude, toilet.longitude);
    marker.title = toilet.name;
    marker.snippet = [NSString stringWithFormat:@"%.1f/5stars, %d reviews", toilet.rating, toilet.totalReviews];
    marker.map = _mapView;
    self.toiletsToMarker[toilet.geohash] = marker;
}

- (void)clearAllMarkers {
    for (NSString *key in self.toiletsToMarker) {
        TMPToiletMapMarker *marker = self.toiletsToMarker[key];
        marker.map = nil;
    }
    [self.toiletsToMarker removeAllObjects];
}

# pragma mark  - context menu for toilet

- (void)populateRateButtonAndStars {
    int rating = [globalStateInterface.persistenceManager reviewedStarsForToilet:self.currentActiveToilet];
    self.editableToiletRating.maxRating = 5;
    self.editableToiletRating.minAllowedRating = 1.0;
    self.editableToiletRating.maxAllowedRating = 5.0f;
    self.editableToiletRating.rating = 3.0f;
    if (rating < 0) {
        // hasnt reviewed yet;
        self.editableToiletRating.canEdit = YES;
        self.editableToiletRating.rating = 3.0f; // default rating
        self.rateButton.enabled = YES;
    } else {
        self.editableToiletRating.canEdit = NO;
        self.editableToiletRating.rating = rating; // what you reviewed earlier
        self.rateButton.enabled = NO;
    }
}

- (void)populateReportButton {
    BOOL alreadyReported = [globalStateInterface.persistenceManager reportedForToilet:self.currentActiveToilet];
    if (alreadyReported) {
        self.reportButton.enabled = NO;
    } else {
        self.reportButton.enabled = YES;
    }
}


- (void)showContextMenuForToilet:(TMPToilet *)tmpToilet {
    self.isContextMenuActive = YES;
    self.currentActiveToilet = tmpToilet;
    
    CLLocationCoordinate2D toiletLocation;
    toiletLocation.latitude = tmpToilet.latitude;
    toiletLocation.longitude = tmpToilet.longitude;
    [self.mapView animateToLocation:toiletLocation];
    
    // hide all markers and show marker for only selected toilet
    [self clearAllMarkers];
    [self confirmMarkerForToilet:tmpToilet];
    
    self.addToiletButton.hidden = YES;
    
    self.contextBottomView.hidden = NO;
    self.contextTopView.hidden = NO;
    self.contextMenuHideView.hidden = NO;
    // Insets are specified in this order: top, left, bottom, right
    UIEdgeInsets mapInsets = UIEdgeInsetsMake(self.contextTopView.bounds.size.height, 0.0, self.contextBottomView.bounds.size.height, 0.0);
    self.mapView.padding = mapInsets;
    
    // toilet rating
    self.toiletRating.canEdit = NO;
    self.toiletRating.maxRating = 5;
    self.toiletRating.minAllowedRating = 0;
    self.toiletRating.maxAllowedRating = 5;
    self.toiletRating.rating = tmpToilet.rating;
    
    // editable toilet rating
    [self populateRateButtonAndStars];
    
    // toilet label
    self.toiletLabel.text = tmpToilet.name;
    
    // toilet address
    self.toiletAddress.text = tmpToilet.address;
}

- (void)hideContextMenuForToilet {
    self.isContextMenuActive = NO;
    self.currentActiveToilet = nil;
    
    self.addToiletButton.hidden = NO;
    
    self.contextBottomView.hidden = YES;
    self.contextTopView.hidden = YES;
    self.contextMenuHideView.hidden = YES;
    UIEdgeInsets mapInsets = UIEdgeInsetsMake(0, 0.0, 0.0, 0.0);
    self.mapView.padding = mapInsets;
    
    //hide this special marker and show markers for current camera position
    [self clearAllMarkers];
    [self confirmPlaceMarkersForCurrentCameraPosition];
}

#pragma mark - Add Toilet Context Menu
- (void)showMenuForAddToilet {
    self.isAddToiletMenuActive = YES;
    
    self.addToiletTopMenu.hidden = NO;
    self.addToiletButton.hidden = YES;
    
    self.addToiletMarker.hidden = NO;
    
    self.nameToiletTextField.text = @"";

}

- (void)hideMenuForAddToilet {
    [self.nameToiletTextField resignFirstResponder];
    self.isAddToiletMenuActive = NO;
    
    self.addToiletTopMenu.hidden = YES;
    self.addToiletButton.hidden = NO;
    
    self.addToiletMarker.hidden = YES;
}

# pragma mark - IBActions

- (IBAction)didTapContextMenuHideButton {
    [self hideContextMenuForToilet];
}

- (IBAction)didTapRateButton {
    if (self.currentActiveToilet) {
        int rating = (int)self.editableToiletRating.rating;
        [globalStateInterface.persistenceManager storeReviewForToilet:self.currentActiveToilet
                                                                stars:rating];
        [globalStateInterface.serverManager rateToilet:self.currentActiveToilet
                                             withStars:rating];
        [self populateRateButtonAndStars];
    }
    
}

- (IBAction)didTapReportButton {
    if (self.currentActiveToilet) {
        [globalStateInterface.persistenceManager storeReportForToilet:self.currentActiveToilet];
        [globalStateInterface.serverManager reportToilet:self.currentActiveToilet];
        [self populateReportButton];
    }
}

- (IBAction)didTapAddToiletButton {
    [self showMenuForAddToilet];
}

- (IBAction)didTapConfirmAddToiletButton {
    if (![self.nameToiletTextField.text length]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Name missing"
                                                        message:@"Please enter a name for the toilet"
                                                       delegate:nil //or self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    } else {
        [self.nameToiletTextField resignFirstResponder];
        
        NSString *name = self.nameToiletTextField.text;
        float latitude = self.mapView.camera.target.latitude;
        float longitude = self.mapView.camera.target.longitude;
        
        //show loading screen
        self.loadingView.hidden = NO;
        
        void (^successBlock)() = ^() {
            self.loadingView.hidden = YES;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Toilet added"
                                                            message:@"We will review it and add it to our database soon. Thanks for the help to make this app better!"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            
            [alert show];
            [self hideMenuForAddToilet];
            
        };
        
        void (^failureBlock)(NSString *reason) = ^(NSString *reason) {
            self.loadingView.hidden = YES;
            NSString *message = [NSString stringWithFormat:@"%@(%@)",@"We are sorry for the inconvenience. Please check your network connection and try again. Thanks for help to make this app better!", reason];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Toilet could not be added"
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            
            [alert show];
            [self hideMenuForAddToilet];
        };

        [globalStateInterface.serverManager addToiletWithName:name
                                                   atLatitude:latitude
                                                    longitude:longitude
                                                      success:successBlock
                                                      failure:failureBlock];
    }
}

- (IBAction)didTapCancelAddToiletButton {
    [self hideMenuForAddToilet];
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
}

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
}

- (void)confirmPlaceMarkersForCurrentCameraPosition {
    CLLocationCoordinate2D target = self.mapView.camera.target;
    GNGeoHash *gh = [GNGeoHash withCharacterPrecision:target.latitude andLongitude:target.longitude andNumberOfCharacters:12];
    NSString *geohash = [gh toBase32];
    geohash = [TMPToilet trimmedGeohash:geohash];
    if ([self.currentGeohash isEqualToString:geohash]) {
        [self clearAllMarkers]; // if we changed position by a lot, clear all markers
    }
    // then we place markers
    [self confirmMarkersForNearbyToiletsForLatitude:target.latitude
                                          longitude:target.longitude];
}

- (void)mapView:(GMSMapView *)mapView
idleAtCameraPosition:(GMSCameraPosition *)cameraPosition {
    if (!self.isContextMenuActive) {
        [self confirmPlaceMarkersForCurrentCameraPosition];
    }
}

- (BOOL) mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    mapView.selectedMarker = marker;
    return TRUE;
}

- (void)mapView:(GMSMapView *)mapView
didTapInfoWindowOfMarker:(GMSMarker *)marker {
    if (!self.isAddToiletMenuActive) {
        TMPToiletMapMarker *toiletMarker = (TMPToiletMapMarker *)marker;
        [self showContextMenuForToilet:toiletMarker.tmpToilet];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameToiletTextField) {
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > kMaxNameForToilet) ? NO : YES;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSLog(@"Cancel Tapped.");
    }
}

@end
