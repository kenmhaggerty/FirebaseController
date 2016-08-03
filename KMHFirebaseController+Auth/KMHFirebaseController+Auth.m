//
//  KMHFirebaseController+Auth.m
//  Sandbox
//
//  Created by Ken M. Haggerty on 7/29/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "KMHFirebaseController+Auth.h"
#import "KMHFirebaseController+PRIVATE.h"
#import <objc/runtime.h>

#pragma mark - // DEFINITIONS (Private) //

NSString * const FirebaseUserDidChangeNotification = @"kNotificationFirebaseController_UserDidChange";
NSString * const FirebaseEmailDidChangeNotification = @"kNotificationFirebaseController_EmailDidChange";

@implementation KMHFirebaseController (Auth)

#pragma mark - // SETTERS AND GETTERS //

- (void)setAuthenticationListener:(FIRAuthStateDidChangeListenerHandle)authenticationListener {
    FIRAuthStateDidChangeListenerHandle primitiveAuthenticationListener = objc_getAssociatedObject(self, @selector(authenticationListener));
    if (authenticationListener == primitiveAuthenticationListener) {
        return;
    }
    
    objc_setAssociatedObject(self, @selector(authenticationListener), authenticationListener, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FIRAuthStateDidChangeListenerHandle)authenticationListener {
    return objc_getAssociatedObject(self, @selector(authenticationListener));
}

#pragma mark - // INITS AND LOADS //

- (void)dealloc {
    [self removeObserversFromAuth];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
        [self addObserversToAuth];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setup];
    [self addObserversToAuth];
}

#pragma mark - // PUBLIC METHODS //

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
            NSDictionary *userInfo = email ? @{FirebaseNotificationUserInfoKey : email} : @{};
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

#pragma mark - // CATEGORY METHODS //

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS (Observers) //

- (void)addObserversToAuth {
    FIRAuth *auth = [FIRAuth auth];
    FIRAuthStateDidChangeListenerHandle handle = [auth addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        NSDictionary *userInfo = user ? @{FirebaseNotificationUserInfoKey : user} : @{};
        [[NSNotificationCenter defaultCenter] postNotificationName:FirebaseUserDidChangeNotification object:nil userInfo:userInfo];
    }];
    self.authenticationListener = handle;
}

- (void)removeObserversFromAuth {
    [[FIRAuth auth] removeAuthStateDidChangeListener:self.authenticationListener];
}

@end
