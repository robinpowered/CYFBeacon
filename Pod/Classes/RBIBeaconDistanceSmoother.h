//
//  RBIBeaconDistanceSmoother.h
//  RBIBeacon
//
//  Created by Yifei Chen on 12/22/14.
//

#import <Foundation/Foundation.h>

/**
 *  Calculate running average of beacons' distance(accuracy).
 *  Feed smoother with CLBeacon by calling -addRangedBeacons:. Smoother will update smoothedBeacons at refreshRate.
 *  For example, if refreshRate is 3, then smoother updates smoothedBeacons every 3 times -addRangedBeacons: is called.
 */
@interface RBIBeaconDistanceSmoother : NSObject

@property (nonatomic) NSInteger refreshRate;

/// An array of RBIBeacon.
@property (nonatomic, strong, readonly) NSArray *smoothedBeacons;


/// Feed smoother with raw CLBeacons.
- (void)addRangedBeacons:(NSArray *)beacons;

/// Clear history and reset to initial state
- (void)reset;

@end
