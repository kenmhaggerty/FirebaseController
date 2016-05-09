//
//  FirebaseQuery.h
//  PushQuery
//
//  Created by Ken M. Haggerty on 3/11/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import <Foundation/Foundation.h>

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS (Public) //

typedef enum : NSUInteger {
    FirebaseKeyIsEqualTo = 0,
    FirebaseKeyIsLessThanOrEqualTo,
    FirebaseKeyIsGreaterThanOrEqualTo,
} FirebaseQueryRelation;

@interface FirebaseQuery : NSObject

// INITIALIZERS //

- (id)init;
- (id)initWithKey:(NSString *)key relation:(FirebaseQueryRelation)relation value:(id)value;
+ (instancetype)queryWithKey:(NSString *)key relation:(FirebaseQueryRelation)relation value:(id)value;

@end
