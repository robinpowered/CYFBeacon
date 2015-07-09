//
//  CYFBeaconManager.h
//  CYFBeacon
//
//  Created by Yifei Chen on 12/21/14.
//

#import <Foundation/Foundation.h>

@class CLLocationManager;
@class RACSignal;
@class CLLocation;
@class CLCircularRegion;

@interface CYFBeaconManager : NSObject

@property (nonatomic, readonly) NSArray *regions;
@property (nonatomic, strong, readonly) RACSignal *rangedBeaconsSignal;
@property (nonatomic, readonly) BOOL authorizationStatusDetermined;
@property (nonatomic, readonly) BOOL authorizationStatusAllowed;
@property (nonatomic, strong, readonly) CLLocation *location;
@property (nonatomic, strong, readonly) CLCircularRegion *geoRegion;

- (instancetype)initWithRegions:(NSArray *)regions locationManager:(CLLocationManager *)locationManager;
- (void)startMonitoringRegionsAndRangingBeacons;
- (void)stopMonitoringAndRanging;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (void)startMonitoringGeoRegion:(CLCircularRegion *)geoRegion;
- (void)stopMonitoringAllGeoRegions;
- (NSArray *)monitoredGeoRegions;

@end
