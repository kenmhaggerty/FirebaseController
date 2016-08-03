//
//  KMHFirebaseController+Auth.h
//  KMHFirebaseController
//
//  Created by Ken M. Haggerty on 3/4/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

#pragma mark - // NOTES //

#pragma mark - // IMPORTS //

#import "KMHFirebaseController.h"

#pragma mark - // PROTOCOLS //

#import <FirebaseAuth/FIRUserInfo.h>

#pragma mark - // DEFINITIONS //

extern NSString * const FirebaseUserDidChangeNotification;
extern NSString * const FirebaseEmailDidChangeNotification;

@interface KMHFirebaseController (Auth)
+ (id <FIRUserInfo>)currentUser;
+ (void)signUpAndSignInWithEmail:(NSString *)email password:(NSString *)password failure:(void (^)(NSError *error))failureBlock;
+ (void)signInWithEmail:(NSString *)email password:(NSString *)password failure:(void (^)(NSError *error))failureBlock;
+ (void)resetPasswordForUserWithEmail:(NSString *)email withCompletionBlock:(void(^)(NSError *error))completionBlock;
+ (void)updateEmailForCurrentUser:(NSString *)email withCompletionBlock:(void(^)(NSError *error))completionBlock;
+ (void)updatePasswordForCurrentUser:(NSString *)password withCompletionBlock:(void(^)(NSError *error))completionBlock;
+ (void)signOutWithFailure:(void(^)(NSError *error))failureBlock;
@end
