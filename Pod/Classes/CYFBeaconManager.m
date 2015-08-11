//
//  CYFBeaconManager.m
//  CYFBeacon
//
//  Created by Yifei Chen on 12/21/14.
//

#import "CYFBeaconManager.h"
#import "ReactiveCocoa.h"
#import "CYFBeaconDistanceSmoother.h"
#import "CYFBeacon.h"

@import CoreLocation;

@interface CYFBeaconManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) NSArray *regions;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) RACSignal *regionEnterSignal;
@property (nonatomic, strong) RACSignal *regionExitSignal;
@property (nonatomic, strong) RACSignal *noBeaconsNearbySignal;
@property (nonatomic, readwrite) BOOL isRanging;

@end



@implementation CYFBeaconManager

- (instancetype)initWithRegions:(NSArray *)regions locationManager:(CLLocationManager *)locationManager
{
    self = [super init];
    if (self) {
        _locationManager = locationManager;
        _locationManager.delegate = self;
        
        _regions = regions;
        _intervalForBeaconRanging = 60;
        _lengthOfBeaconRanging = 8;
        
        self.regionEnterSignal =
            [[[self rac_signalForSelector:@selector(locationManager:didDetermineState:forRegion:) fromProtocol:@protocol(CLLocationManagerDelegate)]
                filter:^BOOL(RACTuple *tuple) {
                    return [tuple.second integerValue] == CLRegionStateInside;
                }]
                map:^id(RACTuple *tuple) {
                    CLBeaconRegion *region = tuple.third;
                    return region;
                }];
        
        self.regionExitSignal =
            [[[self rac_signalForSelector:@selector(locationManager:didDetermineState:forRegion:) fromProtocol:@protocol(CLLocationManagerDelegate)]
                filter:^BOOL(RACTuple *tuple) {
                    return [tuple.second integerValue] == CLRegionStateOutside;
                }]
                map:^id(RACTuple *tuple) {
                    CLBeaconRegion *region = tuple.third;
                    return region;
                }];
        
        [[self.regionEnterSignal
            filter:^BOOL(CLRegion *region) {
                return [region isKindOfClass:CLBeaconRegion.class];
            }]
            subscribeNext:^(CLBeaconRegion *region) {
                [self.locationManager startRangingBeaconsInRegion:region];
            }];
        
        RACSignal *rangedBeaconsSignal = [self rac_signalForSelector:@selector(locationManager:didRangeBeacons:inRegion:) fromProtocol:@protocol(CLLocationManagerDelegate)];
        NSArray *regionsRangedBeaconsSignals =
            [[self.regions.rac_sequence map:^id(CLBeaconRegion *region) {
                return
                    [[rangedBeaconsSignal
                        filter:^BOOL(RACTuple *tuple) { //tuple consits of CLLocationManager *manager, NSArray *beacons, CLBeaconRegion *region
                            return [tuple.third isEqual:region];
                        }]
                        reduceEach:^(CLLocationManager *manager, NSArray *beacons, CLBeaconRegion *_) {
                            return beacons;
                        }];
            }] array];
        
        
        RACSignal *combinedRangedBeaconsSignal =
            [[[RACSignal combineLatest:regionsRangedBeaconsSignals] throttle:0.3] map:^id(RACTuple *regionsRangedBeacons) {
                return
                    [regionsRangedBeacons.rac_sequence foldLeftWithStart:[NSMutableArray arrayWithCapacity:20] reduce:^id(NSMutableArray *result, NSArray *rangedBeacons) {
                        
                        [result addObjectsFromArray:rangedBeacons];
                        return result;
                    }];
            }];
        _rangedBeaconsSignal = combinedRangedBeaconsSignal;

        RACSignal *authorizationStatusSignal =
            [[[self rac_signalForSelector:@selector(locationManager:didChangeAuthorizationStatus:) fromProtocol:@protocol(CLLocationManagerDelegate)]
                reduceEach:^id(CLLocationManager *manager, NSNumber *status) {
                    return status;
                }]
                startWith:@(CLLocationManager.authorizationStatus)];
        
        RAC(self, authorizationStatusDetermined) =
             [authorizationStatusSignal map:^id(NSNumber *status) {
                 return @(status.integerValue != kCLAuthorizationStatusNotDetermined);
             }];
        
        RAC(self, authorizationStatusAllowed) =
            [authorizationStatusSignal map:^id(NSNumber *status) {
                return @(status.integerValue == kCLAuthorizationStatusAuthorized || status.integerValue == kCLAuthorizationStatusAuthorizedAlways);
            }];
        
        
        RACSignal *intevalSignal = [RACSignal interval:self.intervalForBeaconRanging onScheduler:[RACScheduler mainThreadScheduler]];
         
        [intevalSignal
            subscribeNext:^(id x) {
                NSLog(@"interval startttt ranging");
                if (self.isRanging) {
                    for (CLBeaconRegion *region in self.regions) {
                        [self.locationManager startRangingBeaconsInRegion:region];
                    }
                }
            }];
        
        [[intevalSignal delay:self.lengthOfBeaconRanging]
            subscribeNext:^(id x) {
                NSLog(@"interval topppppp ranging");
                if (self.isRanging) {
                    for (CLBeaconRegion *region in self.regions) {
                        [self.locationManager stopRangingBeaconsInRegion:region];
                    }
                }
            }];
    }
    return self;
}

- (void)startMonitoringRegionsAndRangingBeacons {
    NSLog(@"CYFBeaconManager startMonitoringRegionsAndRangingBeacons");
    if (CLLocationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
    }
    

    for (CLBeaconRegion *region in self.regions) {
        [self.locationManager startMonitoringForRegion:region];
        [self.locationManager startRangingBeaconsInRegion:region];
    }
    
    self.isRanging = YES;
}

- (void)stopMonitoringAndRanging {
    NSLog(@"CYFBeaconManager stopMonitoringAndRanging");
    for (CLBeaconRegion *region in self.regions) {
        [self.locationManager stopRangingBeaconsInRegion:region];
        [self.locationManager stopMonitoringForRegion:region];
    }
    self.isRanging = NO;
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSLog(@"CYFBeaconManager del didDetermineState region %ld %@", state, region.identifier);
}

@end
