//
//  KMHFirebaseQuery+PRIVATE.h
//  KMHFirebaseController
//
//  Created by Ken M. Haggerty on 3/11/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import "KMHFirebaseQuery.h"

@import Firebase;

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS (Public) //

@interface KMHFirebaseQuery (FQuery)

+ (FIRDatabaseQuery *)queryWithQueryItem:(KMHFirebaseQuery *)queryItem andDirectory:(FIRDatabaseReference *)directory;
+ (FIRDatabaseQuery *)appendQueryItem:(KMHFirebaseQuery *)queryItem toQuery:(FIRDatabaseQuery *)query;

@end
