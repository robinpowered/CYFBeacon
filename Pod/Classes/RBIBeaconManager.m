//
//  RBIBeaconManager.m
//  RBIBeacon
//
//  Created by Yifei Chen on 12/21/14.
//

#import "RBIBeaconManager.h"
#import "ReactiveCocoa.h"
#import "RBIBeacon.h"

@import CoreLocation;

@interface RBIBeaconManager () <CLLocationManagerDelegate> {
    NSMutableSet *_insideRegions;
}

@property (nonatomic, strong) NSArray *regions;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, readwrite) BOOL isRanging;
@property (nonatomic, readwrite) BOOL isInsideRegions;

@end

@implementation RBIBeaconManager

- (instancetype)initWithRegions:(NSArray *)regions locationManager:(CLLocationManager *)locationManager intervalForBeaconRanging:(NSNumber *)intervalForBeaconRanging lengthOfBeaconRanging:(NSNumber *)lengthOfBeaconRanging
{
    self = [super init];
    if (self) {
        _locationManager = locationManager;
        _locationManager.delegate = self;
        _intervalForBeaconRanging = intervalForBeaconRanging.doubleValue;
        _lengthOfBeaconRanging = lengthOfBeaconRanging.doubleValue;
        _regions = regions;
        _insideRegions = [NSMutableSet setWithCapacity:20];
        
        RACSignal *regionEnterSignal =
            [[[self rac_signalForSelector:@selector(locationManager:didDetermineState:forRegion:) fromProtocol:@protocol(CLLocationManagerDelegate)]
                filter:^BOOL(RACTuple *tuple) {
                    return [tuple.second integerValue] == CLRegionStateInside && [tuple.third isKindOfClass:CLBeaconRegion.class];
                }]
                map:^id(RACTuple *tuple) {
                    CLBeaconRegion *region = tuple.third;
                    return region;
                }];

        RACSignal *regionExitSignal =
            [[[self rac_signalForSelector:@selector(locationManager:didDetermineState:forRegion:) fromProtocol:@protocol(CLLocationManagerDelegate)]
                filter:^BOOL(RACTuple *tuple) {
                    return [tuple.second integerValue] == CLRegionStateOutside && [tuple.third isKindOfClass:CLBeaconRegion.class];
                }]
                map:^id(RACTuple *tuple) {
                    CLBeaconRegion *region = tuple.third;
                    return region;
                }];
        
        [regionExitSignal subscribeNext:^(CLBeaconRegion *region) {
            [locationManager stopRangingBeaconsInRegion:region];
        }];
        
        @weakify(self)
        [regionEnterSignal subscribeNext:^(CLBeaconRegion *region) {
            @strongify(self)
            if (!self.isRanging) {
                return;
            }
            [locationManager startRangingBeaconsInRegion:region];
        }];
        
        
        NSMutableArray *beaconBuffer = [NSMutableArray arrayWithCapacity:50];
        RACSignal *rangedBeaconsSignal = [self rac_signalForSelector:@selector(locationManager:didRangeBeacons:inRegion:) fromProtocol:@protocol(CLLocationManagerDelegate)];
        
        RACSignal *combinedRangedBeaconsSignal =
        [[[rangedBeaconsSignal
            reduceEach:^(CLLocationManager *manager, NSArray *beacons, CLBeaconRegion *_) {
                [beaconBuffer addObjectsFromArray:beacons];
                return beaconBuffer;
            }]
            throttle:0.3]
            map:^id(NSMutableArray *buffer) {
                NSArray *ret = [buffer copy];
                [buffer removeAllObjects];
                return ret;
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
                return @(status.integerValue == kCLAuthorizationStatusAuthorizedAlways);
            }];
        
        RACSignal *intervalSignal =
        [[[RACSignal combineLatest:@[
                                   RACObserve(self, intervalForBeaconRanging),
                                   RACObserve(self, isRanging),
                                   RACObserve(self, alwaysRanging)
                                   ]]
            reduceEach:^id(NSNumber *intervalForBeaconRanging, NSNumber *isRanging, NSNumber *alwaysRanging) {
                if (!isRanging.boolValue) {
                    return [RACSignal empty];
                }
                
                return [[RACSignal interval:intervalForBeaconRanging.doubleValue onScheduler:[RACScheduler mainThreadScheduler]] startWith:[NSDate date]];
            }]
            switchToLatest];
        
        [intervalSignal
            subscribeNext:^(id x) {
                @strongify(self)
                if (self.isRanging) {
                    for (CLBeaconRegion *region in _insideRegions) {
                        [self.locationManager startRangingBeaconsInRegion:region];
                    }
                }
            }];
        
        [[[intervalSignal
            map:^id(id value) {
                return [[RACSignal return:nil] delay:self.lengthOfBeaconRanging];
            }]
            switchToLatest]
            subscribeNext:^(id x) {
                @strongify(self)
                if (self.isRanging && !self.alwaysRanging) {
                    for (CLBeaconRegion *region in _insideRegions) {
                        [self.locationManager stopRangingBeaconsInRegion:region];
                    }
                }
            }];
    }
    return self;
}

- (void)startMonitoringRegionsAndRangingBeacons {
    for (CLBeaconRegion *region in self.regions) {
        [self _startMonitoringAndRangingInRegion:region];
    }
    self.isRanging = YES;
}

- (void)stopMonitoringAndRanging {
    for (CLBeaconRegion *region in self.regions) {
        [self _stopMonitoringAndRangingInRegion:region];
    }
    self.isRanging = NO;
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    if ([region isKindOfClass:CLBeaconRegion.class]) {
        if (state == CLRegionStateInside) {
            [_insideRegions addObject:region];
        }
        else {
            [_insideRegions removeObject:region];
        }
        self.isInsideRegions = _insideRegions.count > 0;
    }
}

- (void)addRegion:(CLBeaconRegion *)region {
    self.regions = [self.regions arrayByAddingObject:region];
    
    if (self.isRanging) {
        [self _startMonitoringAndRangingInRegion:region];
    }
    
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        if ([region isKindOfClass:[CLBeaconRegion class]] && ![self.regions containsObject:region]) {
            NSLog(@"stop region %@ because it should not be monitored", region.identifier);
            [self _stopMonitoringAndRangingInRegion:(CLBeaconRegion *)region];
        }
    }
}

- (void)_startMonitoringAndRangingInRegion:(CLBeaconRegion *)region {
    [self.locationManager startMonitoringForRegion:region];
    [self.locationManager startRangingBeaconsInRegion:region];
}

- (void)_stopMonitoringAndRangingInRegion:(CLBeaconRegion *)region {
    [self.locationManager stopRangingBeaconsInRegion:region];
    [self.locationManager stopMonitoringForRegion:region];
}

@end
