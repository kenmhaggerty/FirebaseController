//
//  KMHFirebaseController.h
//  KMHFirebaseController
//
//  Created by Ken M. Haggerty on 3/4/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import <Foundation/Foundation.h>

#import "KMHFirebaseQuery.h"

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS (Public) //

extern NSString * const FirebaseNotificationUserInfoKey;
extern NSString * const FirebaseIsConnectedDidChangeNotification;

@interface KMHFirebaseController : NSObject

// GENERAL //

+ (void)setup;
+ (BOOL)isConnected;
+ (void)connect;
+ (void)disconnect;

// DATA //

+ (void)setPriority:(id)priority forPath:(NSString *)path withCompletion:(void(^)(BOOL success, NSError *error))completionBlock;
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
+ (void)getObjectsAtPath:(NSString *)path withQueries:(NSArray <KMHFirebaseQuery *> *)queries andCompletion:(void (^)(id result))completionBlock;

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
