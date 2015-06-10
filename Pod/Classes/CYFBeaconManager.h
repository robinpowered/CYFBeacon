//
//  CYFBeaconManager.h
//  CYFBeacon
//
//  Created by Yifei Chen on 12/21/14.
//

#import <Foundation/Foundation.h>

@class CLLocationManager;
@class RACSignal;

@interface CYFBeaconManager : NSObject

@property (nonatomic, readonly) NSArray *regions;
@property (nonatomic, strong, readonly) RACSignal *rangedBeaconsSignal;
@property (nonatomic, readonly) BOOL authorizationStatusDetermined;
@property (nonatomic, readonly) BOOL authorizationStatusAllowed;

- (instancetype)initWithRegions:(NSArray *)regions locationManager:(CLLocationManager *)locationManager;
- (void)startMonitoringRegionsAndRangingBeacons;
- (void)stopMonitoringAndRanging;
- (void)startUpdatingLocation;

@end
