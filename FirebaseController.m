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
#import "AKDebugger.h"
#import "AKGenerics.h"
#import "FirebaseQuery+FQuery.h"

#import <Firebase/Firebase.h>

#pragma mark - // DEFINITIONS (Private) //

NSString * const FirebaseIsConnectedDidChangeNotification = @"kNotificationFirebaseController_IsConnectedDidChange;";
NSString * const FirebaseEmailDidChangeNotification = @"kNotificationFirebaseController_EmailDidChange";

NSString * const FirebaseAuthKeyEmail = @"email";
NSString * const FirebaseAuthKeyUID = @"uid";
NSString * const FirebaseAuthKeyToken = @"token";
NSString * const FirebaseAuthKeyProfileImageURL = @"profileImageURL";

NSString * const FirebaseKeyOnlineValue = @"value";
NSString * const FirebaseKeyPersistValue = @"persist";

NSString * const FirebaseObserverValueChanged = @"ValueChanged";
NSString * const FirebaseObserverChildAdded = @"ChildAdded";
NSString * const FirebaseObserverChildChanged = @"ChildChanged";
NSString * const FirebaseObserverChildMoved = @"ChildMoved";
NSString * const FirebaseObserverChildRemoved = @"ChildRemoved";

NSString * const FirebaseObserverHandleKey = @"handle";
NSString * const FirebaseObserverConnectionThresholdKey = @"threshold";
NSString * const FirebaseObserverConnectionCountKey = @"count";

@interface FirebaseController ()
@property (nonatomic, strong) Firebase *firebase;
@property (nonatomic) FirebaseHandle firebaseHandle;
@property (nonatomic) BOOL isConnected;
@property (nonatomic, strong) NSMutableDictionary *offlineValues;
@property (nonatomic, strong) NSMutableDictionary *onlineValues;
@property (nonatomic, strong) NSMutableDictionary *persistedValues;
@property (nonatomic, strong) NSMutableDictionary *observers;

// GENERAL //

+ (instancetype)sharedController;
- (void)setup;
- (void)setProjectName:(NSString *)projectName;

+ (void)setObject:(id)object toPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock;
+ (void)setOfflineValue:(id)offlineValue forObjectAtPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock;
- (void)setOnlineValues;
- (void)persistOfflineValues;
+ (void)observeEvent:(FEventType)event atPath:(NSString *)path withBlock:(void (^)(id object))block;
+ (void)removeObserverAtPath:(NSString *)path forEvent:(FEventType)event;
+ (NSString *)stringForEvent:(FEventType)event;
+ (void)performCompletionBlock:(void (^)(id result))completionBlock withSnapshot:(FDataSnapshot *)snapshot;
+ (NSDictionary *)dictionaryForAuthData:(FAuthData *)authData;
+ (NSString *)keyForPath:(NSString *)path andEvent:(FEventType)event;

@end

@implementation FirebaseController

#pragma mark - // SETTERS AND GETTERS //

- (void)setFirebase:(Firebase *)firebase {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_REMOTE_DATA] message:nil];
    
    if ([firebase isEqual:_firebase]) {
        return;
    }
    
    if (_firebase) {
        [_firebase removeObserverWithHandle:self.firebaseHandle];
    }
    
    _firebase = firebase;
    
    self.firebaseHandle = [[firebase childByAppendingPath:@".info/connected"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        BOOL isConnected = [snapshot.value boolValue];
        self.isConnected = isConnected;
    }];
}

- (void)setIsConnected:(BOOL)isConnected {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_REMOTE_DATA, AKD_CONNECTIVITY] message:nil];
    
    if (isConnected == _isConnected) {
        return;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithBool:isConnected] forKey:NOTIFICATION_OBJECT_KEY];
    
    _isConnected = isConnected;
    
    if (isConnected) {
        [self setOnlineValues];
        [self persistOfflineValues];
    }
    
    [AKGenerics postNotificationName:FirebaseIsConnectedDidChangeNotification object:nil userInfo:userInfo];
}

#pragma mark - // INITS AND LOADS //

- (id)init {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_REMOTE_DATA] message:nil];
    
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)awakeFromNib {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [super awakeFromNib];
    
    [self setup];
}

#pragma mark - // PUBLIC METHODS (General) //

+ (void)setup:(NSString *)projectName {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_REMOTE_DATA] message:nil];
    
    FirebaseController *sharedController = [FirebaseController sharedController];
    if (!sharedController) {
        [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeWarning methodType:AKMethodTypeSetup tags:@[AKD_REMOTE_DATA] message:[NSString stringWithFormat:@"Could not initialize %@", NSStringFromClass([FirebaseController class])]];
    }
    
    [sharedController setProjectName:projectName];
}

+ (BOOL)isConnected {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_REMOTE_DATA, AKD_CONNECTIVITY] message:nil];
    
    return [FirebaseController sharedController].isConnected;
}

+ (void)connect {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_REMOTE_DATA, AKD_CONNECTIVITY] message:nil];
    
    [Firebase goOnline];
}

+ (void)disconnect {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_REMOTE_DATA, AKD_CONNECTIVITY] message:nil];
    
    [Firebase goOffline];
}

#pragma mark - // PUBLIC METHODS (Data) //

+ (void)saveObject:(id)object toPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController setObject:object toPath:path withCompletion:^(BOOL success, NSError *error) {
        
        if (success) {
            NSMutableDictionary *persistedValues = [FirebaseController sharedController].persistedValues;
            if ([persistedValues.allKeys containsObject:path]) {
                [persistedValues setObject:object forKey:path];
            }
        }
        
        completionBlock(success, error);
    }];
}

+ (void)updateObjectAtPath:(NSString *)path withDictionary:(NSDictionary *)dictionary andCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
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
    Firebase *directory = [[FirebaseController sharedController].firebase childByAppendingPath:path];
    [directory updateChildValues:childValues withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        if (error) {
            [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
        }
        
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
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    if (persist) {
        [[FirebaseController sharedController].offlineValues setObject:offlineValue forKey:path];
    }
    [FirebaseController setOfflineValue:offlineValue forObjectAtPath:path withCompletion:completionBlock];
}

+ (void)setOnlineValue:(id)onlineValue forObjectAtPath:(NSString *)path withPersistence:(BOOL)persist {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [[FirebaseController sharedController].onlineValues setObject:@{FirebaseKeyOnlineValue : onlineValue, FirebaseKeyPersistValue : [NSNumber numberWithBool:persist]} forKey:path];
}

+ (void)persistOnlineValueForObjectAtPath:(NSString *)path {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController getObjectAtPath:path withCompletion:^(id object) {
        
        [[FirebaseController sharedController].persistedValues setObject:(object ? object : [NSNull null]) forKey:path];
    }];
}

+ (void)clearOfflineValueForObjectAtPath:(NSString *)path {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [[FirebaseController sharedController].offlineValues removeObjectForKey:path];
}

+ (void)clearOnlineValueForObjectAtPath:(NSString *)path {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [[FirebaseController sharedController].onlineValues removeObjectForKey:path];
}

+ (void)clearPersistedValueForObjectAtPath:(NSString *)path {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [[FirebaseController sharedController].persistedValues removeObjectForKey:path];
}

#pragma mark - // PUBLIC METHODS (Queries) //

+ (void)getObjectAtPath:(NSString *)path withCompletion:(void (^)(id object))completionBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_REMOTE_DATA] message:nil];
    
    Firebase *directory = [[FirebaseController sharedController].firebase childByAppendingPath:path];
    [directory observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        [FirebaseController performCompletionBlock:completionBlock withSnapshot:snapshot];
    }];
}


+ (void)getObjectsAtPath:(NSString *)path withQueries:(NSArray <FirebaseQuery *> *)queries andCompletion:(void (^)(id result))completionBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_REMOTE_DATA] message:nil];
    
    Firebase *directory = [[FirebaseController sharedController].firebase childByAppendingPath:path];
    if (!queries || !queries.count) {
        [directory observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            [FirebaseController performCompletionBlock:completionBlock withSnapshot:snapshot];
        }];
        return;
    }
    
    FQuery *query;
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
    [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        [FirebaseController performCompletionBlock:completionBlock withSnapshot:snapshot];
     }];
}

#pragma mark - // PUBLIC METHODS (Observers) //

+ (void)observeValueChangedAtPath:(NSString *)path withBlock:(void (^)(id value))block {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController observeEvent:FEventTypeValue atPath:path withBlock:block];
}

+ (void)observeChildAddedAtPath:(NSString *)path withBlock:(void (^)(id child))block {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController observeEvent:FEventTypeChildAdded atPath:path withBlock:block];
}

+ (void)observeChildChangedAtPath:(NSString *)path withBlock:(void (^)(id child))block {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController observeEvent:FEventTypeChildChanged atPath:path withBlock:block];
}

+ (void)observeChildRemovedFromPath:(NSString *)path withBlock:(void (^)(id child))block {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController observeEvent:FEventTypeChildRemoved atPath:path withBlock:block];
}

+ (void)removeValueChangedObserverAtPath:(NSString *)path {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController removeObserverAtPath:path forEvent:FEventTypeValue];
}

+ (void)removeChildAddedObserverAtPath:(NSString *)path {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController removeObserverAtPath:path forEvent:FEventTypeChildAdded];
}

+ (void)removeChildChangedObserverAtPath:(NSString *)path {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController removeObserverAtPath:path forEvent:FEventTypeChildChanged];
}

+ (void)removeChildRemovedObserverAtPath:(NSString *)path {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    [FirebaseController removeObserverAtPath:path forEvent:FEventTypeChildRemoved];
}

#pragma mark - // CATEGORY METHODS (Auth) //

+ (NSDictionary *)authData {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_ACCOUNTS] message:nil];
    
    FAuthData *authData = [FirebaseController sharedController].firebase.authData;
    return [FirebaseController dictionaryForAuthData:authData];
}

+ (void)signUpWithEmail:(NSString *)email password:(NSString *)password success:(void (^)(NSDictionary *result))successBlock failure:(void (^)(NSError *error))failureBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeCreator tags:@[AKD_ACCOUNTS] message:nil];
    
    [[FirebaseController sharedController].firebase createUser:email password:password withValueCompletionBlock:^(NSError *error, NSDictionary *result) {
        
        if (error) {
            [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeCreator tags:@[AKD_ACCOUNTS] message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
        }
        
        if (!result) {
            failureBlock(error);
            return;
        }
        
        successBlock([FirebaseController authData]);
    }];
}

+ (void)loginUserWithEmail:(NSString *)email password:(NSString *)password success:(void (^)(NSDictionary *result))successBlock failure:(void (^)(NSError *error))failureBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_ACCOUNTS] message:nil];
    
    [[FirebaseController sharedController].firebase authUser:email password:password withCompletionBlock:^(NSError *error, FAuthData *authData) {
        
        if (error) {
            [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeCreator tags:@[AKD_ACCOUNTS] message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
        }
        
        if (!authData) {
            failureBlock(error);
            return;
        }
        
        successBlock([FirebaseController dictionaryForAuthData:authData]);
    }];
}

+ (void)resetPasswordForUserWithEmail:(NSString *)email withCompletionBlock:(void(^)(NSError *error))completionBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_ACCOUNTS] message:nil];
    
    [[FirebaseController sharedController].firebase resetPasswordForUser:email withCompletionBlock:completionBlock];
}

+ (void)changeEmailForUserWithEmail:(NSString *)email password:(NSString *)password toNewEmail:(NSString *)newEmail withCompletionBlock:(void(^)(NSError *error))completionBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_ACCOUNTS] message:nil];
    
    [[FirebaseController sharedController].firebase changeEmailForUser:email password:password toNewEmail:newEmail withCompletionBlock:^(NSError *error){
        
        if (!error) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            userInfo[NOTIFICATION_OBJECT_KEY] = newEmail;
            
            [AKGenerics postNotificationName:FirebaseEmailDidChangeNotification object:nil userInfo:userInfo];
        }
        completionBlock(error);
    }];
}

+ (void)changePasswordForUserWithEmail:(NSString *)email fromOld:(NSString *)oldPassword toNew:(NSString *)newPassword withCompletionBlock:(void(^)(NSError *error))completionBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_ACCOUNTS] message:nil];
    
    [[FirebaseController sharedController].firebase changePasswordForUser:email fromOld:oldPassword toNew:newPassword withCompletionBlock:completionBlock];
}

+ (void)logout {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_ACCOUNTS] message:nil];
    
    [[FirebaseController sharedController].firebase unauth];
}

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS (General) //

+ (instancetype)sharedController {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_REMOTE_DATA] message:nil];
    
    static FirebaseController *_sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedController = [[FirebaseController alloc] init];
    });
    return _sharedController;
}

- (void)setup {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_REMOTE_DATA] message:nil];
    
    //    [Firebase defaultConfig].persistenceEnabled = YES;
    
    _isConnected = YES;
    _offlineValues = [NSMutableDictionary dictionary];
    _onlineValues = [NSMutableDictionary dictionary];
    _persistedValues = [NSMutableDictionary dictionary];
    _observers = [NSMutableDictionary dictionary];
}

- (void)setProjectName:(NSString *)projectName {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_REMOTE_DATA] message:nil];
    
    self.firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"https://%@.firebaseio.com", projectName]];
}

+ (void)setObject:(id)object toPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetter tags:@[AKD_REMOTE_DATA] message:nil];
    
    Firebase *directory = [[FirebaseController sharedController].firebase childByAppendingPath:path];
    [directory setValue:object withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        if (error) {
            [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
        }
        
        if (completionBlock) {
            completionBlock(error == nil, error);
        }
    }];
}

+ (void)setOfflineValue:(id)offlineValue forObjectAtPath:(NSString *)path withCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    Firebase *directory = [[FirebaseController sharedController].firebase childByAppendingPath:path];
    [directory onDisconnectSetValue:offlineValue withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        if (error) {
            [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
        }
        
        if (completionBlock) {
            completionBlock(error != nil, error);
        }
    }];
}

- (void)setOnlineValues {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_REMOTE_DATA] message:nil];
    
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
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeSetup tags:@[AKD_REMOTE_DATA] message:nil];
    
    for (NSString *path in self.offlineValues.allKeys) {
        [FirebaseController setOfflineValue:self.offlineValues[path] forObjectAtPath:path withCompletion:nil];
    }
}

+ (void)observeEvent:(FEventType)event atPath:(NSString *)path withBlock:(void (^)(id object))block {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    if ((event == FEventTypeValue) || (event == FEventTypeChildAdded)) {
        Firebase *directory = [[FirebaseController sharedController].firebase childByAppendingPath:path];
        [directory observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            id value = snapshot.value;
            [FirebaseController observeEvent:event atPath:path withBlock:block andThreshold:([value isKindOfClass:[NSNull class]] ? 1 : MAX(snapshot.childrenCount, 1))];
        }];
        return;
    }
    
    [FirebaseController observeEvent:event atPath:path withBlock:block andThreshold:0];
}

+ (void)observeEvent:(FEventType)event atPath:(NSString *)path withBlock:(void (^)(id object))block andThreshold:(NSUInteger)threshold {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    FirebaseHandle handle = [[[FirebaseController sharedController].firebase childByAppendingPath:path] observeEventType:event withBlock:^(FDataSnapshot *snapshot) {
        NSString *key = [FirebaseController keyForPath:path andEvent:event];
        NSNumber *thresholdValue = [FirebaseController sharedController].observers[key][FirebaseObserverConnectionThresholdKey];
        NSNumber *countValue = [FirebaseController sharedController].observers[key][FirebaseObserverConnectionCountKey];
        if (thresholdValue.integerValue > countValue.integerValue) {
            [FirebaseController sharedController].observers[key][FirebaseObserverConnectionCountKey] = [NSNumber numberWithInteger:countValue.integerValue+1];
            return;
        }
        
        [FirebaseController performCompletionBlock:block withSnapshot:snapshot];
    } withCancelBlock:^(NSError *error) {
        if (error) {
            [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeError methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:[NSString stringWithFormat:@"%@, %@", error, error.userInfo]];
        }
    }];
    
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:@[[NSNumber numberWithInteger:handle], [NSNumber numberWithInteger:threshold], @0] forKeys:@[FirebaseObserverHandleKey, FirebaseObserverConnectionThresholdKey, FirebaseObserverConnectionCountKey]];
    
    [[FirebaseController sharedController].observers setObject:info forKey:[FirebaseController keyForPath:path andEvent:event]];
}

+ (void)removeObserverAtPath:(NSString *)path forEvent:(FEventType)event {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    NSString *key = [FirebaseController keyForPath:path andEvent:event];
    NSNumber *handleValue = [FirebaseController sharedController].observers[key][FirebaseObserverHandleKey];
    FirebaseHandle handle = handleValue.integerValue;
    [[FirebaseController sharedController].firebase removeObserverWithHandle:handle];
    [[FirebaseController sharedController].observers removeObjectForKey:key];
}

+ (NSString *)stringForEvent:(FEventType)event {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_REMOTE_DATA] message:nil];
    
    switch (event) {
        case FEventTypeValue:
            return FirebaseObserverValueChanged;
        case FEventTypeChildAdded:
            return FirebaseObserverChildAdded;
        case FEventTypeChildChanged:
            return FirebaseObserverChildChanged;
        case FEventTypeChildMoved:
            return FirebaseObserverChildMoved;
        case FEventTypeChildRemoved:
            return FirebaseObserverChildRemoved;
    }
}

+ (void)performCompletionBlock:(void (^)(id result))completionBlock withSnapshot:(FDataSnapshot *)snapshot {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_REMOTE_DATA] message:nil];
    
    NSString *key = snapshot.key;
    id value = snapshot.value;
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = snapshot.value;
        value = [NSDictionary dictionaryWithObjects:array forKeys:[NSArray arrayWithValue:0 increment:1 length:array.count]];
    }
    
    completionBlock(@{key : value});
}

+ (NSDictionary *)dictionaryForAuthData:(FAuthData *)authData {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeUnspecified tags:@[AKD_ACCOUNTS] message:nil];
    
    if (!authData) {
        return nil;
    }
    
    return @{FirebaseAuthKeyEmail : authData.providerData[FirebaseAuthKeyEmail], FirebaseAuthKeyUID : authData.uid, FirebaseAuthKeyProfileImageURL : authData.providerData[FirebaseAuthKeyProfileImageURL], FirebaseAuthKeyToken : authData.token};
}

+ (NSString *)keyForPath:(NSString *)path andEvent:(FEventType)event {
    [AKDebugger logMethod:METHOD_NAME logType:AKLogTypeMethodName methodType:AKMethodTypeGetter tags:@[AKD_REMOTE_DATA] message:nil];
    
    return [NSString stringWithFormat:@"%@_%@", path, [FirebaseController stringForEvent:event]];
}

@end
