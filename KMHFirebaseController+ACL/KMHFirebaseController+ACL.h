//
//  KMHFirebaseController+ACL.h
//  KMHFirebaseController
//
//  Created by Ken M. Haggerty on 7/27/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import "KMHFirebaseController.h"

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS (Public) //

extern NSString * const FirebaseObjectsWithIdsWereMadeInaccessibleNotification;
extern NSString * const FirebaseObjectsWithIdsWereMadePublicNotification;
extern NSString * const FirebaseObjectsWithIdsWereMadePrivateNotification;
extern NSString * const FirebaseObjectsWithIdsWereSharedNotification;
extern NSString * const FirebaseObjectsWithIdsWereUnsharedNotification;

@interface KMHFirebaseController (ACL)

// SETUP //

+ (void)setCurrentUserId:(NSString *)userId;

// SAVE //

+ (void)saveObject:(id)object withId:(NSString *)objectId isPublic:(BOOL)isPublic users:(NSSet <NSString *> *)userIds error:(void (^)(NSError *error))errorBlock completion:(void (^)(BOOL success))completionBlock;
+ (void)overwriteObjectWithId:(NSString *)objectId withObject:(id)object andCompletion:(void (^)(BOOL success, NSError *error))completionBlock;

// PERMISSIONS //

+ (void)setObjectWithId:(NSString *)objectId asPublic:(BOOL)isPublic withCompletion:(void (^)(BOOL success, NSError *error))completionBlock;
+ (void)addUserWithId:(NSString *)userId toObjectWithId:(NSString *)objectId withCompletion:(void (^)(BOOL success, NSError *error))completionBlock;
+ (void)removeUserWithId:(NSString *)userId fromObjectWithId:(NSString *)objectId withCompletion:(void (^)(BOOL success, NSError *error))completionBlock;

// FETCH //

+ (void)objectExistsWithId:(NSString *)objectId error:(void (^)(NSError *error))errorBlock success:(void (^)(BOOL exists))successBlock;
+ (void)fetchObjectWithId:(NSString *)objectId completion:(void (^)(id object))completionBlock;
+ (void)fetchPublicObjectsWithBlock:(void (^)(id object, float progress))block;
+ (void)fetchSharedObjectsWithBlock:(void (^)(id object, float progress))block;

// OBSERVE //

+ (void)observeValueChangedAtPath:(NSString *)path forObjectWithId:(NSString *)objectId withBlock:(void(^)(id value))block;
+ (void)observeChildAddedAtPath:(NSString *)path forObjectWithId:(NSString *)objectId withBlock:(void(^)(id value))block;
+ (void)observeChildChangedAtPath:(NSString *)path forObjectWithId:(NSString *)objectId withBlock:(void(^)(id value))block;
+ (void)observeChildRemovedFromPath:(NSString *)path forObjectWithId:(NSString *)objectId withBlock:(void(^)(id value))block;

+ (void)removeValueChangedObserverAtPath:(NSString *)path forObjectWithId:(NSString *)objectId;
+ (void)removeChildAddedObserverAtPath:(NSString *)path forObjectWithId:(NSString *)objectId;
+ (void)removeChildChangedObserverAtPath:(NSString *)path forObjectWithId:(NSString *)objectId;
+ (void)removeChildRemovedObserverAtPath:(NSString *)path forObjectWithId:(NSString *)objectId;

@end
