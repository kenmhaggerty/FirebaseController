//
//  FirebaseController.h
//  PushQuery
//
//  Created by Ken M. Haggerty on 3/4/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import <Foundation/Foundation.h>

#import "FirebaseQuery.h"

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS (Public) //

#import "FirebaseNotifications.h"

@interface FirebaseController : NSObject

// GENERAL //

+ (void)setup:(NSString *)projectName;
+ (BOOL)isConnected;
+ (void)connect;
+ (void)disconnect;

// DATA //

+ (void)saveObject:(id)object toPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock;
+ (void)updateObjectAtPath:(NSString *)path withDictionary:(NSDictionary *)dictionary andCompletion:(void (^)(BOOL success, NSError *error))completionBlock;
+ (void)setOfflineValue:(id)offlineValue forObjectAtPath:(NSString *)path withPersistence:(BOOL)persist andCompletion:(void (^)(BOOL success, NSError *error))completionBlock;
+ (void)setOnlineValue:(id)onlineValue forObjectAtPath:(NSString *)path withPersistence:(BOOL)persist;
+ (void)persistOnlineValueForObjectAtPath:(NSString *)path;
+ (void)clearOfflineValueForObjectAtPath:(NSString *)path;
+ (void)clearOnlineValueForObjectAtPath:(NSString *)path;
+ (void)clearPersistedValueForObjectAtPath:(NSString *)path;

// QUERIES //

+ (void)getObjectAtPath:(NSString *)path withCompletion:(void (^)(id object))completionBlock;
+ (void)getObjectsAtPath:(NSString *)path withQueries:(NSArray <FirebaseQuery *> *)queries andCompletion:(void (^)(id result))completionBlock;

// OBSERVERS //

+ (void)observeValueChangedAtPath:(NSString *)path withBlock:(void (^)(id value))block;
+ (void)observeChildAddedAtPath:(NSString *)path withBlock:(void (^)(id child))block;
+ (void)observeChildChangedAtPath:(NSString *)path withBlock:(void (^)(id child))block;
+ (void)observeChildRemovedFromPath:(NSString *)path withBlock:(void (^)(id child))block;

+ (void)removeValueChangedObserverAtPath:(NSString *)path;
+ (void)removeChildAddedObserverAtPath:(NSString *)path;
+ (void)removeChildChangedObserverAtPath:(NSString *)path;
+ (void)removeChildRemovedObserverAtPath:(NSString *)path;

@end
