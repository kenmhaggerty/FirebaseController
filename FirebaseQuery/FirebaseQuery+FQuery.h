//
//  FirebaseQuery+FQuery.h
//  PushQuery
//
//  Created by Ken M. Haggerty on 3/11/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import "FirebaseQuery.h"

@import Firebase;

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS (Public) //

@interface FirebaseQuery (FQuery)

+ (FIRDatabaseQuery *)queryWithQueryItem:(FirebaseQuery *)queryItem andDirectory:(FIRDatabaseReference *)directory;
+ (FIRDatabaseQuery *)appendQueryItem:(FirebaseQuery *)queryItem toQuery:(FIRDatabaseQuery *)query;

@end
