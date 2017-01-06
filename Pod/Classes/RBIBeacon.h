//
//  RBIBeacon.h
//  RBIBeacon
//
//  Created by Yifei Chen on 12/30/14.
//

#import <Foundation/Foundation.h>

@interface RBIBeacon : NSObject

@property (readonly, nonatomic, strong) NSUUID *proximityUUID;

@property (readonly, nonatomic, strong) NSNumber *major;

@property (readonly, nonatomic, strong) NSNumber *minor;

@property (readonly, nonatomic, strong) NSString *key;

@property (nonatomic) double accuracy;

- (instancetype)initWithUUID:(NSUUID *)UUID major:(NSNumber *)major minor:(NSNumber *)minor accuracy:(double)accuracy;

@end
