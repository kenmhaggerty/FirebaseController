//
//  FirebaseController.m
//  PushQuery
//
//  Created by Ken M. Haggerty on 3/4/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "FirebaseController+Auth.h"
#import "FirebaseQuery+FQuery.h"

@import Firebase;

#pragma mark - // DEFINITIONS (Private) //

NSString * const FirebaseNotificationObject = @"object";

NSString * const FirebaseIsConnectedDidChangeNotification = @"kNotificationFirebaseController_IsConnectedDidChange;";

NSString * const FirebaseUserDidChangeNotification = @"kNotificationFirebaseController_UserDidChange";
NSString * const FirebaseEmailDidChangeNotification = @"kNotificationFirebaseController_EmailDidChange";

NSString * const FirebaseKeyOnlineValue = @"value";
NSString * const FirebaseKeyPersistValue = @"persist";

NSString * const FirebaseObserverValueChanged = @"ValueChanged";
NSString * const FirebaseObserverChildAdded = @"ChildAdded";
NSString * const FirebaseObserverChildChanged = @"ChildChanged";
NSString * const FirebaseObserverChildMoved = @"ChildMoved";
NSString * const FirebaseObserverChildRemoved = @"ChildRemoved";

//NSString * const FirebaseObserverHandleKey = @"handle";
NSString * const FirebaseObserverConnectionThresholdKey = @"threshold";
NSString * const FirebaseObserverConnectionCountKey = @"count";

@interface FirebaseController ()
@property (nonatomic, strong) FIRDatabaseReference *database;
@property (nonatomic) FIRAuthStateDidChangeListenerHandle authenticationListener;
@property (nonatomic) FIRDatabaseHandle connectionListener;
@property (nonatomic) BOOL isConnected;

@property (nonatomic, strong) NSMutableDictionary *offlineValues;
@property (nonatomic, strong) NSMutableDictionary *onlineValues;
@property (nonatomic, strong) NSMutableDictionary *persistedValues;
@property (nonatomic, strong) NSMutableDictionary *observers;

// GENERAL //

+ (instancetype)sharedController;
- (void)setup;
- (void)teardown;

// GETTERS //

+ (FIRDatabaseReference *)database;

// OBSERVERS //

- (void)addObserversToAuth;
- (void)removeObserversFromAuth;

// OTHER //

+ (void)setObject:(id)object toPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock;
+ (void)setOfflineValue:(id)offlineValue forObjectAtPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock;
- (void)setOnlineValues;
- (void)persistOfflineValues;
+ (void)observeEvent:(FIRDataEventType)event atPath:(NSString *)path withBlock:(void (^)(id object))block;
+ (void)removeAllObserversAtPath:(NSString *)path forEvent:(FIRDataEventType)event;
+ (NSString *)stringForEvent:(FIRDataEventType)event;
+ (void)performCompletionBlock:(void (^)(id result))completionBlock withSnapshot:(FIRDataSnapshot *)snapshot;
+ (NSString *)keyForPath:(NSString *)path andEvent:(FIRDataEventType)event;

@end

@implementation FirebaseController

#pragma mark - // SETTERS AND GETTERS //

@synthesize database = _database;

- (void)setDatabase:(FIRDatabaseReference *)database {
    if ([database isEqual:_database]) {
        return;
    }
    
    if (_database) {
        [_database removeObserverWithHandle:self.connectionListener];
    }
    
    _database = database;
    
    self.connectionListener = [database observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        self.isConnected = [snapshot.value boolValue];
    }];
}

- (FIRDatabaseReference *)database {
    if (_database) {
        return _database;
    }
    
    self.database = [[FIRDatabase database] reference];
    return _database;
}

- (void)setIsConnected:(BOOL)isConnected {
    if (isConnected == _isConnected) {
        return;
    }
    
    NSDictionary *userInfo = @{FirebaseNotificationObject : @(isConnected)};
    
    _isConnected = isConnected;
    
    if (isConnected) {
        [self setOnlineValues];
        [self persistOfflineValues];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseIsConnectedDidChangeNotification object:nil userInfo:userInfo];
}

#pragma mark - // INITS AND LOADS //

- (void)dealloc {
    [self teardown];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setup];
}

#pragma mark - // PUBLIC METHODS (General) //

+ (void)setup {
    [FIRApp configure];
    
    [FirebaseController sharedController];
}

+ (BOOL)isConnected {
    return [FirebaseController sharedController].isConnected;
}

+ (void)connect {
    [FIRDatabaseReference goOnline];
}

+ (void)disconnect {
    [FIRDatabaseReference goOffline];
}

#pragma mark - // PUBLIC METHODS (Data) //

+ (void)setPriority:(id)priority forPath:(NSString *)path withCompletion:(void(^)(BOOL success, NSError *error))completionBlock {
    FIRDatabaseReference *directory = [[FirebaseController database] child:path];
    [directory setPriority:priority withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        if (completionBlock) {
            completionBlock(error == nil, error);
        }
    }];
}

+ (void)saveObject:(id)object toPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    [FirebaseController setObject:object toPath:path withCompletion:^(BOOL success, NSError *error) {
        if (success) {
            NSMutableDictionary *persistedValues = [FirebaseController sharedController].persistedValues;
            if ([persistedValues.allKeys containsObject:path]) {
                [persistedValues setObject:object forKey:path];
            }
        }
        
        if (completionBlock) {
            completionBlock(success, error);
        }
    }];
}

+ (void)updateObjectAtPath:(NSString *)path withDictionary:(NSDictionary *)dictionary andCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    NSMutableDictionary *mutableCopy = [dictionary mutableCopy];
    NSMutableDictionary *childValues = [NSMutableDictionary dictionary];
    NSString *key;
    id object, subobject;
    NSDictionary *subdictionary;
    while (mutableCopy.allKeys.count) {
        key = [mutableCopy.allKeys firstObject];
        object = mutableCopy[key];
        if ([object isKindOfClass:[NSDictionary class]]) {
            subdictionary = (NSDictionary *)object;
            for (NSString *subkey in subdictionary.allKeys) {
                subobject = subdictionary[subkey];
                [mutableCopy setObject:subobject forKey:[NSString stringWithFormat:@"%@/%@", key, subkey]];
            }
        }
        else {
            [childValues setObject:object forKey:key];
        }
        [mutableCopy removeObjectForKey:key];
    }
    FIRDatabaseReference *directory = [[FirebaseController database] child:path];
    [directory updateChildValues:childValues withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        NSMutableDictionary *persistedValues = [FirebaseController sharedController].persistedValues;
        for (NSString *path in childValues.allKeys) {
            if ([persistedValues.allKeys containsObject:path]) {
                [persistedValues setObject:childValues[path] forKey:path];
            }
        }
        
        if (completionBlock) {
            completionBlock(error != nil, error);
        }
    }];
}

+ (void)setOfflineValue:(id)offlineValue forObjectAtPath:(NSString *)path withPersistence:(BOOL)persist andCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    if (persist) {
        [[FirebaseController sharedController].offlineValues setObject:offlineValue forKey:path];
    }
    [FirebaseController setOfflineValue:offlineValue forObjectAtPath:path withCompletion:completionBlock];
}

+ (void)setOnlineValue:(id)onlineValue forObjectAtPath:(NSString *)path withPersistence:(BOOL)persist {
    [[FirebaseController sharedController].onlineValues setObject:@{FirebaseKeyOnlineValue : onlineValue, FirebaseKeyPersistValue : [NSNumber numberWithBool:persist]} forKey:path];
}

+ (void)persistOnlineValueForObjectAtPath:(NSString *)path {
    [FirebaseController getObjectAtPath:path withCompletion:^(id object) {
        
        [[FirebaseController sharedController].persistedValues setObject:(object ? object : [NSNull null]) forKey:path];
    }];
}

+ (void)clearOfflineValueForObjectAtPath:(NSString *)path {
    [[FirebaseController sharedController].offlineValues removeObjectForKey:path];
}

+ (void)clearOnlineValueForObjectAtPath:(NSString *)path {
    [[FirebaseController sharedController].onlineValues removeObjectForKey:path];
}

+ (void)clearPersistedValueForObjectAtPath:(NSString *)path {
    [[FirebaseController sharedController].persistedValues removeObjectForKey:path];
}

#pragma mark - // PUBLIC METHODS (Queries) //

+ (void)getObjectAtPath:(NSString *)path withCompletion:(void (^)(id object))completionBlock {
    FIRDatabaseReference *directory = [[FirebaseController database] child:path];
    [directory observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        [FirebaseController performCompletionBlock:completionBlock withSnapshot:snapshot];
    }];
}


+ (void)getObjectsAtPath:(NSString *)path withQueries:(NSArray <FirebaseQuery *> *)queries andCompletion:(void (^)(id result))completionBlock {
    FIRDatabaseReference *directory = [[FirebaseController database] child:path];
    if (!queries || !queries.count) {
        [directory observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            [FirebaseController performCompletionBlock:completionBlock withSnapshot:snapshot];
        }];
        return;
    }
    
    FIRDatabaseQuery *query;
    FirebaseQuery *queryItem;
    for (NSUInteger i = 0; i < queries.count; i++) {
        queryItem = queries[i];
        if (i) {
            query = [FirebaseQuery appendQueryItem:queryItem toQuery:query];
        }
        else {
            query = [FirebaseQuery queryWithQueryItem:queryItem andDirectory:directory];
        }
    }
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        [FirebaseController performCompletionBlock:completionBlock withSnapshot:snapshot];
     }];
}

#pragma mark - // PUBLIC METHODS (Observers) //

+ (void)observeValueChangedAtPath:(NSString *)path withBlock:(void (^)(id value))block {
    [FirebaseController observeEvent:FIRDataEventTypeValue atPath:path withBlock:block];
}

+ (void)observeChildAddedAtPath:(NSString *)path withBlock:(void (^)(id child))block {
    [FirebaseController observeEvent:FIRDataEventTypeChildAdded atPath:path withBlock:block];
}

+ (void)observeChildChangedAtPath:(NSString *)path withBlock:(void (^)(id child))block {
    [FirebaseController observeEvent:FIRDataEventTypeChildChanged atPath:path withBlock:block];
}

+ (void)observeChildRemovedFromPath:(NSString *)path withBlock:(void (^)(id child))block {
    [FirebaseController observeEvent:FIRDataEventTypeChildRemoved atPath:path withBlock:block];
}

+ (void)removeValueChangedObserverAtPath:(NSString *)path {
    [FirebaseController removeAllObserversAtPath:path forEvent:FIRDataEventTypeValue];
}

+ (void)removeChildAddedObserverAtPath:(NSString *)path {
    [FirebaseController removeAllObserversAtPath:path forEvent:FIRDataEventTypeChildAdded];
}

+ (void)removeChildChangedObserverAtPath:(NSString *)path {
    [FirebaseController removeAllObserversAtPath:path forEvent:FIRDataEventTypeChildChanged];
}

+ (void)removeChildRemovedObserverAtPath:(NSString *)path {
    [FirebaseController removeAllObserversAtPath:path forEvent:FIRDataEventTypeChildRemoved];
}

#pragma mark - // CATEGORY METHODS (Auth) //

+ (id <FIRUserInfo>)currentUser {
    return [FIRAuth auth].currentUser;
}

+ (void)signUpAndSignInWithEmail:(NSString *)email password:(NSString *)password failure:(void (^)(NSError *error))failureBlock {
    [[FIRAuth auth] createUserWithEmail:email password:password completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        if (user) {
            return;
        }
        
        failureBlock(error);
    }];
}

+ (void)signInWithEmail:(NSString *)email password:(NSString *)password failure:(void (^)(NSError *error))failureBlock {
    [[FIRAuth auth] signInWithEmail:email password:password completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
        if (user) {
            return;
        }
        
        failureBlock(error);
    }];
}

+ (void)resetPasswordForUserWithEmail:(NSString *)email withCompletionBlock:(void(^)(NSError *error))completionBlock {
    [[FIRAuth auth] sendPasswordResetWithEmail:email completion:completionBlock];
}

+ (void)updateEmailForCurrentUser:(NSString *)email withCompletionBlock:(void(^)(NSError *error))completionBlock {
    [[FIRAuth auth].currentUser updateEmail:email completion:^(NSError *error) {
        if (!error) {
            NSDictionary *userInfo = email ? @{FirebaseNotificationObject : email} : @{};
            [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseEmailDidChangeNotification object:nil userInfo:userInfo];
        }
        completionBlock(error);
    }];
}

+ (void)updatePasswordForCurrentUser:(NSString *)password withCompletionBlock:(void(^)(NSError *error))completionBlock {
    [[FIRAuth auth].currentUser updatePassword:password completion:^(NSError *error) {
        completionBlock(error);
    }];
}

+ (void)signOutWithFailure:(void(^)(NSError *error))failureBlock {
    NSError *error;
    [[FIRAuth auth] signOut:&error];
    if (!error) {
        return;
    }
    
    failureBlock(error);
}

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS (General) //

+ (instancetype)sharedController {
    static FirebaseController *_sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedController = [[FirebaseController alloc] init];
    });
    return _sharedController;
}

- (void)setup {
//    [FIRDatabaseReference defaultConfig].persistenceEnabled = YES;
    
    _isConnected = YES;
    _offlineValues = [NSMutableDictionary dictionary];
    _onlineValues = [NSMutableDictionary dictionary];
    _persistedValues = [NSMutableDictionary dictionary];
    _observers = [NSMutableDictionary dictionary];
    
    [self addObserversToAuth];
}

- (void)teardown {
    [self removeObserversFromAuth];
}

#pragma mark - // PRIVATE METHODS (Getters) //

+ (FIRDatabaseReference *)database {
    return [[FIRDatabase database] reference];
}

#pragma mark - // PRIVATE METHODS (Observers) //

- (void)addObserversToAuth {
    FIRAuth *auth = [FIRAuth auth];
    FIRAuthStateDidChangeListenerHandle handle = [auth addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        NSDictionary *userInfo = user ? @{FirebaseNotificationObject : user} : @{};
        [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseUserDidChangeNotification object:nil userInfo:userInfo];
    }];
    self.authenticationListener = handle;
}

- (void)removeObserversFromAuth {
    [[FIRAuth auth] removeAuthStateDidChangeListener:self.authenticationListener];
}

#pragma mark - // PRIVATE METHODS (Other) //

+ (void)setObject:(id)object toPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    FIRDatabaseReference *directory = [[FirebaseController database] child:path];
    [directory setValue:object withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        if (completionBlock) {
            completionBlock(error == nil, error);
        }
    }];
}

+ (void)setOfflineValue:(id)offlineValue forObjectAtPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    FIRDatabaseReference *directory = [[FirebaseController database] child:path];
    [directory onDisconnectSetValue:offlineValue withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
        if (completionBlock) {
            completionBlock(error != nil, error);
        }
    }];
}

- (void)setOnlineValues {
    for (NSString *path in self.persistedValues.allKeys) {
        
        if ([self.onlineValues.allKeys containsObject:path]) {
            continue;
        }
        
        [FirebaseController setObject:self.persistedValues[path] toPath:path withCompletion:nil];
    }
    for (NSString *path in self.onlineValues.allKeys) {
        [FirebaseController setObject:self.onlineValues[path][FirebaseKeyOnlineValue] toPath:path withCompletion:^(BOOL success, NSError *error) {
            
            if (!success) {
                return;
            }
            
            BOOL persist = ((NSNumber *)self.onlineValues[path][FirebaseKeyPersistValue]).boolValue;
            if (!persist) {
                [self.onlineValues removeObjectForKey:path];
            }
        }];
    }
}

- (void)persistOfflineValues {
    for (NSString *path in self.offlineValues.allKeys) {
        [FirebaseController setOfflineValue:self.offlineValues[path] forObjectAtPath:path withCompletion:nil];
    }
}

+ (void)observeEvent:(FIRDataEventType)event atPath:(NSString *)path withBlock:(void (^)(id object))block {
    if (event == FIRDataEventTypeChildAdded) {
        FIRDatabaseReference *directory = [[FirebaseController database] child:path];
        [directory observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
            id value = snapshot.value;
            [FirebaseController observeEvent:event atPath:path withBlock:block andThreshold:([value isKindOfClass:[NSNull class]] ? 1 : MAX(snapshot.childrenCount, 1))];
        }];
        return;
    }
    
    [FirebaseController observeEvent:event atPath:path withBlock:block andThreshold:((event == FIRDataEventTypeValue) ? 1 : 0)];
}

+ (void)observeEvent:(FIRDataEventType)event atPath:(NSString *)path withBlock:(void (^)(id object))block andThreshold:(NSUInteger)threshold {
    [[[FirebaseController database] child:path] observeEventType:event withBlock:^(FIRDataSnapshot *snapshot) {
        NSString *key = [FirebaseController keyForPath:path andEvent:event];
        NSDictionary *info = [FirebaseController sharedController].observers[key];
        if (!info) {
            return;
        }
        
        NSNumber *thresholdValue = info[FirebaseObserverConnectionThresholdKey];
        NSNumber *countValue = [FirebaseController sharedController].observers[key][FirebaseObserverConnectionCountKey];
        if (thresholdValue.integerValue > countValue.integerValue) {
            [FirebaseController sharedController].observers[key][FirebaseObserverConnectionCountKey] = [NSNumber numberWithInteger:countValue.integerValue+1];
            return;
        }
        
        [FirebaseController performCompletionBlock:block withSnapshot:snapshot];
    }];
    
    NSNumber *thresholdValue = [NSNumber numberWithInteger:threshold];
    NSNumber *countValue = @0;
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:@[thresholdValue, countValue] forKeys:@[FirebaseObserverConnectionThresholdKey, FirebaseObserverConnectionCountKey]];
    
    [[FirebaseController sharedController].observers setObject:info forKey:[FirebaseController keyForPath:path andEvent:event]];
}

+ (void)removeAllObserversAtPath:(NSString *)path forEvent:(FIRDataEventType)event {
    NSString *key = [FirebaseController keyForPath:path andEvent:event];
    FIRDatabaseReference *firebase = [[FirebaseController database] child:path];
    [firebase removeAllObservers];
    [[FirebaseController sharedController].observers removeObjectForKey:key];
}

+ (NSString *)stringForEvent:(FIRDataEventType)event {
    switch (event) {
        case FIRDataEventTypeValue:
            return FirebaseObserverValueChanged;
        case FIRDataEventTypeChildAdded:
            return FirebaseObserverChildAdded;
        case FIRDataEventTypeChildChanged:
            return FirebaseObserverChildChanged;
        case FIRDataEventTypeChildMoved:
            return FirebaseObserverChildMoved;
        case FIRDataEventTypeChildRemoved:
            return FirebaseObserverChildRemoved;
    }
}

+ (void)performCompletionBlock:(void (^)(id result))completionBlock withSnapshot:(FIRDataSnapshot *)snapshot {
    NSString *key = snapshot.key;
    id value = snapshot.value;
    if ([value isKindOfClass:[NSNull class]]) {
        return;
    }
    
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = snapshot.value;
        NSMutableArray *keys = [NSMutableArray arrayWithCapacity:array.count];
        for (int i = 0; i < array.count; i++) {
            [keys addObject:@(i)];
        }
        value = [NSDictionary dictionaryWithObjects:array forKeys:[NSArray arrayWithArray:keys]];
    }
    
    completionBlock(@{key : value});
}

+ (NSString *)keyForPath:(NSString *)path andEvent:(FIRDataEventType)event {
    return [NSString stringWithFormat:@"%@_%@", path, [FirebaseController stringForEvent:event]];
}

@end
