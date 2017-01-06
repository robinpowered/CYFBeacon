//
//  RBIBeaconManager.h
//  RBIBeacon
//
//  Created by Yifei Chen on 12/21/14.
//

#import <Foundation/Foundation.h>

@class CLLocationManager;
@class RACSignal;
@class CLBeaconRegion;

@interface RBIBeaconManager : NSObject

@property (nonatomic, readonly) NSArray *regions;
// YES if inside any 'regions'
@property (nonatomic, readonly) BOOL isInsideRegions;
@property (nonatomic, strong, readonly) RACSignal *rangedBeaconsSignal;
@property (nonatomic, readonly) BOOL authorizationStatusDetermined;
@property (nonatomic, readonly) BOOL authorizationStatusAllowed;
@property (nonatomic, readonly) BOOL isRanging;
@property (nonatomic) BOOL alwaysRanging;
@property (nonatomic) NSTimeInterval intervalForBeaconRanging;
@property (nonatomic) NSTimeInterval lengthOfBeaconRanging;

- (instancetype)initWithRegions:(NSArray *)regions locationManager:(CLLocationManager *)locationManager intervalForBeaconRanging:(NSNumber *)intervalForBeaconRanging lengthOfBeaconRanging:(NSNumber *)lengthOfBeaconRanging;
- (void)startMonitoringRegionsAndRangingBeacons;
- (void)stopMonitoringAndRanging;
- (void)addRegion:(CLBeaconRegion *)region;

@end
