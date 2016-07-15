//
//  FirebaseController+Auth.h
//  PushQuery
//
//  Created by Ken M. Haggerty on 3/4/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES //

#pragma mark - // IMPORTS //

#import "FirebaseController.h"

#pragma mark - // PROTOCOLS //

#import <FirebaseAuth/FIRUserInfo.h>

#pragma mark - // DEFINITIONS //

extern NSString * const FirebaseUserDidChangeNotification;
extern NSString * const FirebaseEmailDidChangeNotification;

@interface FirebaseController (Auth)
+ (id <FIRUserInfo>)currentUser;
+ (void)signUpAndSignInWithEmail:(NSString *)email password:(NSString *)password failure:(void (^)(NSError *error))failureBlock;
+ (void)signInWithEmail:(NSString *)email password:(NSString *)password failure:(void (^)(NSError *error))failureBlock;
+ (void)resetPasswordForUserWithEmail:(NSString *)email withCompletionBlock:(void(^)(NSError *error))completionBlock;
+ (void)updateEmailForCurrentUser:(NSString *)email withCompletionBlock:(void(^)(NSError *error))completionBlock;
+ (void)updatePasswordForCurrentUser:(NSString *)password withCompletionBlock:(void(^)(NSError *error))completionBlock;
+ (void)signOutWithFailure:(void(^)(NSError *error))failureBlock;
@end
