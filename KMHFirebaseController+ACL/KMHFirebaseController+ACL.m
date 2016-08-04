//
//  KMHFirebaseController+ACL.m
//  KMHFirebaseController
//
//  Created by Ken M. Haggerty on 7/27/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "KMHFirebaseController+ACL.h"
#import "KMHFirebaseController+PRIVATE.h"
#import <objc/runtime.h>

#pragma mark - // DEFINITIONS (Private) //

NSString * const FirebaseObjectsWithIdsWereMadeInaccessibleNotification = @"kFirebaseObjectsWithIdsWereMadeInaccessibleNotification";
NSString * const FirebaseObjectsWithIdsWereMadePublicNotification = @"kFirebaseObjectsWithIdsWereMadePublicNotification";
NSString * const FirebaseObjectsWithIdsWereMadePrivateNotification = @"kFirebaseObjectsWithIdsWereMadePrivateNotification";
NSString * const FirebaseObjectsWithIdsWereSharedNotification = @"kFirebaseObjectsWithIdsWereSharedNotification";
NSString * const FirebaseObjectsWithIdsWereUnsharedNotification = @"kFirebaseObjectsWithIdsWereUnsharedNotification";

NSString * const FirebasePathPermissions = @"permissions";
NSString * const FirebasePathPermissionsPublic = @"public";
NSString * const FirebasePathPermissionsUser = @"user";
NSString * const FirebasePathObjects = @"objects";

@implementation KMHFirebaseController (ACL)

#pragma mark - // SETTERS AND GETTERS //

- (void)setCurrentUserId:(NSString *)currentUserId {
    NSString *primitiveCurrentUserId = objc_getAssociatedObject(self, @selector(currentUserId));
    if ([currentUserId isEqualToString:primitiveCurrentUserId]) {
        return;
    }
    
    if (!currentUserId) {
        NSMutableSet *allObjects = [NSMutableSet setWithSet:self.publicObjectIds];
        [allObjects unionSet:self.sharedObjectIds];
        NSDictionary *userInfo = @{FirebaseNotificationUserInfoKey : [NSSet setWithSet:allObjects]};
        [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseObjectsWithIdsWereMadeInaccessibleNotification object:nil userInfo:userInfo];
        self.sharedObjectIds = [NSSet set];
        self.publicObjectIds = [NSSet set];
    }
    
    if (primitiveCurrentUserId) {
        [self removeObserversFromUserId:primitiveCurrentUserId];
        [self removeObserversForPublicPermissions];
    }
    
    objc_setAssociatedObject(self, @selector(currentUserId), currentUserId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (currentUserId) {
        [self addObserversForPublicPermissions];
        [self addObserversToUserId:currentUserId];
        [self refreshObjectIdsForUserWithId:currentUserId];
    }
}

- (NSString *)currentUserId {
    return objc_getAssociatedObject(self, @selector(currentUserId));
}

- (void)setPublicObjectIds:(NSSet *)publicObjectIds {
    NSSet *primitivePublicObjectIds = objc_getAssociatedObject(self, @selector(publicObjectIds));
    if ([publicObjectIds isEqualToSet:primitivePublicObjectIds]) {
        return;
    }
    
    objc_setAssociatedObject(self, @selector(publicObjectIds), publicObjectIds, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSMutableSet *removedObjectIds = [primitivePublicObjectIds mutableCopy];
    [removedObjectIds minusSet:publicObjectIds];
    
    for (NSString *objectId in removedObjectIds) {
        [self removeObserversFromPublicPermissionForObjectWithId:objectId];
    }
    
    NSMutableSet *inaccessibleObjectIds = [removedObjectIds mutableCopy];
    [inaccessibleObjectIds minusSet:self.sharedObjectIds];
    
    [removedObjectIds minusSet:inaccessibleObjectIds];
    
    NSDictionary *userInfo = @{FirebaseNotificationUserInfoKey : [NSSet setWithSet:inaccessibleObjectIds]};
    [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseObjectsWithIdsWereMadeInaccessibleNotification object:nil userInfo:userInfo];
    
    userInfo = @{FirebaseNotificationUserInfoKey : [NSSet setWithSet:removedObjectIds]};
    [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseObjectsWithIdsWereMadePrivateNotification object:nil userInfo:userInfo];
    
    NSMutableSet *addedObjectIds = [publicObjectIds mutableCopy];
    [addedObjectIds minusSet:primitivePublicObjectIds];
    
    for (NSString *objectId in addedObjectIds) {
        [self addObserversToPublicPermissionForObjectWithId:objectId];
    }
    
    userInfo = @{FirebaseNotificationUserInfoKey : [NSSet setWithSet:addedObjectIds]};
    [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseObjectsWithIdsWereMadePublicNotification object:nil userInfo:userInfo];
}

- (NSSet *)publicObjectIds {
    NSSet *publicObjectIds = objc_getAssociatedObject(self, @selector(publicObjectIds));
    if (publicObjectIds) {
        return publicObjectIds;
    }
    
    objc_setAssociatedObject(self, @selector(publicObjectIds), [NSSet set], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self.publicObjectIds;
}

- (void)setSharedObjectIds:(NSSet *)sharedObjectIds {
    NSSet *primitiveSharedObjectIds = objc_getAssociatedObject(self, @selector(sharedObjectIds));
    if ([sharedObjectIds isEqualToSet:primitiveSharedObjectIds]) {
        return;
    }
    
    objc_setAssociatedObject(self, @selector(sharedObjectIds), sharedObjectIds, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSMutableSet *removedObjectIds = [primitiveSharedObjectIds mutableCopy];
    [removedObjectIds minusSet:sharedObjectIds];
    
    for (NSString *objectId in removedObjectIds) {
        [self removeObserversFromUserPermissionForUserWithId:self.currentUserId objectWithId:objectId];
    }
    
    NSMutableSet *inaccessibleObjectIds = [removedObjectIds mutableCopy];
    [inaccessibleObjectIds minusSet:self.publicObjectIds];
    
    [removedObjectIds minusSet:inaccessibleObjectIds];
    
    NSDictionary *userInfo = @{FirebaseNotificationUserInfoKey : [NSSet setWithSet:inaccessibleObjectIds]};
    [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseObjectsWithIdsWereMadeInaccessibleNotification object:nil userInfo:userInfo];
    
    userInfo = @{FirebaseNotificationUserInfoKey : [NSSet setWithSet:removedObjectIds]};
    [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseObjectsWithIdsWereUnsharedNotification object:nil userInfo:userInfo];
    
    NSMutableSet *addedObjectIds = [sharedObjectIds mutableCopy];
    [addedObjectIds minusSet:primitiveSharedObjectIds];
    
    for (NSString *objectId in addedObjectIds) {
        [self addObserversToUserPermissionForUserWithId:self.currentUserId objectWithId:objectId];
    }
    
    userInfo = @{FirebaseNotificationUserInfoKey : [NSSet setWithSet:addedObjectIds]};
    [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseObjectsWithIdsWereSharedNotification object:nil userInfo:userInfo];
}

- (NSSet *)sharedObjectIds {
    NSSet *sharedObjectIds = objc_getAssociatedObject(self, @selector(sharedObjectIds));
    if (sharedObjectIds) {
        return sharedObjectIds;
    }
    
    objc_setAssociatedObject(self, @selector(sharedObjectIds), [NSSet set], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self.sharedObjectIds;
}

#pragma mark - // INITS AND LOADS //

#pragma mark - // PUBLIC METHODS (Setup) //

+ (void)setCurrentUserId:(NSString *)userId {
    [KMHFirebaseController sharedController].currentUserId = userId;
}

#pragma mark - // PUBLIC METHODS (Save) //

+ (void)saveObject:(id)object withId:(NSString *)objectId isPublic:(BOOL)isPublic users:(NSSet <NSString *> *)userIds error:(void (^)(NSError *error))errorBlock completion:(void (^)(BOOL success))completionBlock {
    NSString *currentUserId = [KMHFirebaseController sharedController].currentUserId;
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsUser, currentUserId, objectId]];
    [KMHFirebaseController saveObject:@YES toPath:pathURL.relativeString withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            errorBlock(error);
            completionBlock(NO);
            return;
        }
        
        NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
        [KMHFirebaseController saveObject:object toPath:pathURL.relativeString withCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                errorBlock(error);
                completionBlock(NO);
                return;
            }
            
            NSMutableSet *sharedUserIds = [userIds mutableCopy];
            [sharedUserIds removeObject:currentUserId];
            
            if (!isPublic && !sharedUserIds.count) {
                completionBlock(YES);
                return;
            }
            
            __block NSUInteger count = (isPublic ? 1 : 0) + sharedUserIds.count;
            __block NSUInteger complete = 0;
            
            if (isPublic) {
                NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsPublic, objectId]];
                [KMHFirebaseController saveObject:@YES toPath:pathURL.relativeString withCompletion:^(BOOL success, NSError *error) {
                    if (error) {
                        errorBlock(error);
                    }
                    if (++complete >= count) {
                        completionBlock(YES);
                    }
                }];
            }
            
            for (NSString *userId in sharedUserIds) {
                NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsUser, userId, objectId]];
                [KMHFirebaseController saveObject:@YES toPath:pathURL.relativeString withCompletion:^(BOOL success, NSError *error) {
                    if (error) {
                        errorBlock(error);
                    }
                    if (++complete >= count) {
                        completionBlock(YES);
                    }
                }];
            }
        }];
    }];
}


+ (void)overwriteObjectWithId:(NSString *)objectId withObject:(id)object andCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController saveObject:object toPath:pathURL.relativeString withCompletion:completionBlock];
}

#pragma mark - // PUBLIC METHODS (Permissions) //

+ (void)setObjectWithId:(NSString *)objectId asPublic:(BOOL)isPublic withCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsPublic, objectId]];
    [KMHFirebaseController saveObject:@(isPublic) toPath:pathURL.relativeString withCompletion:^(BOOL success, NSError *error) {
        if (!success || isPublic) {
            completionBlock(success, error);
            return;
        }
        
        [KMHFirebaseController saveObject:nil toPath:pathURL.relativeString withCompletion:completionBlock];
    }];
}

+ (void)addUserWithId:(NSString *)userId toObjectWithId:(NSString *)objectId withCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsUser, userId, objectId]];
    [KMHFirebaseController saveObject:@YES toPath:pathURL.relativeString withCompletion:completionBlock];
}

+ (void)removeUserWithId:(NSString *)userId fromObjectWithId:(NSString *)objectId withCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsUser, userId, objectId]];
    [KMHFirebaseController saveObject:@NO toPath:pathURL.relativeString withCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            completionBlock(success, error);
            return;
        }
        
        [KMHFirebaseController saveObject:nil toPath:pathURL.relativeString withCompletion:completionBlock];
    }];
}

#pragma mark - // PUBLIC METHODS (Fetch) //

+ (void)objectExistsWithId:(NSString *)objectId error:(void (^)(NSError *error))errorBlock success:(void (^)(BOOL exists))successBlock {
#warning TO DO – Implementation that actually uses Firebase
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@", objectId];
    
    if ([[KMHFirebaseController sharedController].publicObjectIds filteredSetUsingPredicate:predicate].count) {
        successBlock(YES);
        return;
    }
    
    if ([[KMHFirebaseController sharedController].sharedObjectIds filteredSetUsingPredicate:predicate].count) {
        successBlock(YES);
        return;
    }
    
    successBlock(NO);
}

+ (void)fetchObjectWithId:(NSString *)objectId completion:(void (^)(id object))completionBlock {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController getObjectAtPath:pathURL.relativeString withCompletion:^(id object) {
        completionBlock(object);
    }];
}

+ (void)fetchPublicObjectsWithBlock:(void (^)(id object, float progress))block {
    NSSet *publicObjectIds = [KMHFirebaseController sharedController].publicObjectIds;
    NSURL *pathURL;
    __block int count = 0;
    for (NSString *objectId in publicObjectIds) {
        pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
        [KMHFirebaseController getObjectAtPath:pathURL.relativeString withCompletion:^(id object) {
            // check object type
            
            float progress = ((float)++count)/((float)publicObjectIds.count);
            block(object, progress);
        }];
    }
}

+ (void)fetchSharedObjectsWithBlock:(void (^)(id object, float progress))block {
    NSSet *sharedObjectIds = [KMHFirebaseController sharedController].sharedObjectIds;
    NSURL *pathURL;
    __block int count = 0;
    for (NSString *objectId in sharedObjectIds) {
        pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
        [KMHFirebaseController getObjectAtPath:pathURL.relativeString withCompletion:^(id object) {
            // check object type
            
            float progress = ((float)++count)/((float)sharedObjectIds.count);
            block(object, progress);
        }];
    }
}

#pragma mark - // PUBLIC METHODS (Observe) //

+ (void)observeValueChangedAtPath:(NSString *)path forObjectWithId:(NSString *)objectId withBlock:(void(^)(id value))block {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController observeValueChangedAtPath:[pathURL.relativeString stringByAppendingPathComponent:path] withBlock:block];
}

+ (void)observeChildAddedAtPath:(NSString *)path forObjectWithId:(NSString *)objectId withBlock:(void(^)(id value))block {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController observeChildAddedAtPath:[pathURL.relativeString stringByAppendingPathComponent:path] withBlock:block];
}

+ (void)observeChildChangedAtPath:(NSString *)path forObjectWithId:(NSString *)objectId withBlock:(void(^)(id value))block {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController observeChildChangedAtPath:[pathURL.relativeString stringByAppendingPathComponent:path] withBlock:block];
}

+ (void)observeChildRemovedFromPath:(NSString *)path forObjectWithId:(NSString *)objectId withBlock:(void(^)(id value))block {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController observeChildRemovedAtPath:[pathURL.relativeString stringByAppendingPathComponent:path] withBlock:block];
}

+ (void)removeValueChangedObserverAtPath:(NSString *)path forObjectWithId:(NSString *)objectId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController removeValueChangedObserverAtPath:[pathURL.relativeString stringByAppendingPathComponent:path]];
}

+ (void)removeChildAddedObserverAtPath:(NSString *)path forObjectWithId:(NSString *)objectId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController removeChildAddedObserverAtPath:[pathURL.relativeString stringByAppendingPathComponent:path]];
}

+ (void)removeChildChangedObserverAtPath:(NSString *)path forObjectWithId:(NSString *)objectId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController removeChildChangedObserverAtPath:[pathURL.relativeString stringByAppendingPathComponent:path]];
}

+ (void)removeChildRemovedObserverAtPath:(NSString *)path forObjectWithId:(NSString *)objectId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathObjects, objectId]];
    [KMHFirebaseController removeChildRemovedObserverAtPath:[pathURL.relativeString stringByAppendingPathComponent:path]];
}

#pragma mark - // CATEGORY METHODS //

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS (Observers) //

- (void)addObserversForPublicPermissions {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsPublic]];
    [KMHFirebaseController observeChildAddedAtPath:pathURL.relativeString withBlock:^(id child) {
        // check object type
        NSString *objectId;
        BOOL isPublic;
        
        [self objectWithId:objectId isPublic:isPublic];
    }];
}

- (void)removeObserversForPublicPermissions {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsPublic]];
    [KMHFirebaseController removeChildAddedObserverAtPath:pathURL.relativeString];
}

- (void)addObserversToPublicPermissionForObjectWithId:(NSString *)objectId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsPublic, objectId]];
    [KMHFirebaseController observeValueChangedAtPath:pathURL.relativeString withBlock:^(id value) {
        // check object type
        BOOL isPublic;
        
        [self objectWithId:objectId isPublic:isPublic];
    }];
}

- (void)removeObserversFromPublicPermissionForObjectWithId:(NSString *)objectId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsPublic, objectId]];
    [KMHFirebaseController removeValueChangedObserverAtPath:pathURL.relativeString];
}

- (void)addObserversToUserId:(NSString *)userId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsUser, userId]];
    [KMHFirebaseController observeChildAddedAtPath:pathURL.relativeString withBlock:^(NSDictionary *child) {
        if (child.count > 1) {
            //
        }
        NSString *objectId = child.allKeys.firstObject;
        NSNumber *isSharedValue = child.allValues.firstObject;
        
        [self objectWithId:objectId isShared:isSharedValue.boolValue];
    }];
}

- (void)removeObserversFromUserId:(NSString *)userId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsUser, userId]];
    [KMHFirebaseController removeChildAddedObserverAtPath:pathURL.relativeString];
}

- (void)addObserversToUserPermissionForUserWithId:(NSString *)userId objectWithId:(NSString *)objectId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsUser, userId, objectId]];
    [KMHFirebaseController observeValueChangedAtPath:pathURL.relativeString withBlock:^(id value) {
        // check object type
        BOOL isShared;
        
        [self objectWithId:objectId isShared:isShared];
    }];
}

- (void)removeObserversFromUserPermissionForUserWithId:(NSString *)userId objectWithId:(NSString *)objectId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsUser, userId, objectId]];
    [KMHFirebaseController removeValueChangedObserverAtPath:pathURL.relativeString];
}

#pragma mark - // PRIVATE METHODS (Other) //

- (void)refreshObjectIdsForUserWithId:(NSString *)userId {
    NSURL *pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsPublic]];
    [KMHFirebaseController getObjectAtPath:pathURL.relativeString withCompletion:^(NSDictionary *dictionary) {
        NSSet *publicObjectIds = [NSSet set];
        if (dictionary) {
            publicObjectIds = [dictionary keysOfEntriesPassingTest:^BOOL(NSString *objectId, NSNumber *boolValue, BOOL *stop) {
                return boolValue.boolValue;
            }];
        }
        self.publicObjectIds = publicObjectIds;
    }];
    
    pathURL = [NSURL fileURLWithPathComponents:@[FirebasePathPermissions, FirebasePathPermissionsUser, userId]];
    [KMHFirebaseController getObjectAtPath:pathURL.relativeString withCompletion:^(NSDictionary *dictionary) {
        NSSet *sharedObjectIds = [NSSet set];
        if (dictionary) {
            sharedObjectIds = [dictionary keysOfEntriesPassingTest:^BOOL(NSString *objectId, NSNumber *boolValue, BOOL *stop) {
                return boolValue.boolValue;
            }];
        }
        self.sharedObjectIds = sharedObjectIds;
    }];
}

- (void)objectWithId:(NSString *)objectId isPublic:(BOOL)isPublic {
    NSMutableSet *publicObjectIds = [self.publicObjectIds mutableCopy];
    isPublic ? [publicObjectIds addObject:objectId] : [publicObjectIds removeObject:objectId];
    self.publicObjectIds = [NSSet setWithSet:publicObjectIds];
}

- (void)objectWithId:(NSString *)objectId isShared:(BOOL)isShared {
    NSMutableSet *sharedObjectIds = [self.sharedObjectIds mutableCopy];
    isShared ? [sharedObjectIds addObject:objectId] : [sharedObjectIds removeObject:objectId];
    self.sharedObjectIds = [NSSet setWithSet:sharedObjectIds];
}

@end
