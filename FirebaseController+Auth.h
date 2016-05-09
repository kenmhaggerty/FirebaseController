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

#pragma mark - // DEFINITIONS //

extern NSString * const FirebaseEmailDidChangeNotification;

extern NSString * const FirebaseAuthKeyEmail;
extern NSString * const FirebaseAuthKeyUID;
extern NSString * const FirebaseAuthKeyToken;
extern NSString * const FirebaseAuthKeyProfileImageURL;

@interface FirebaseController (Auth)
+ (NSDictionary *)authData;
+ (void)signUpWithEmail:(NSString *)email password:(NSString *)password success:(void (^)(NSDictionary *))successBlock failure:(void (^)(NSError *))failureBlock;
+ (void)loginUserWithEmail:(NSString *)email password:(NSString *)password success:(void (^)(NSDictionary *))successBlock failure:(void (^)(NSError *))failureBlock;
+ (void)resetPasswordForUserWithEmail:(NSString *)email withCompletionBlock:(void(^)(NSError *error))completionBlock;
+ (void)changeEmailForUserWithEmail:(NSString *)email password:(NSString *)password toNewEmail:(NSString *)newEmail withCompletionBlock:(void(^)(NSError *error))completionBlock;
+ (void)changePasswordForUserWithEmail:(NSString *)email fromOld:(NSString *)oldPassword toNew:(NSString *)newPassword withCompletionBlock:(void(^)(NSError *error))completionBlock;
+ (void)logout;
@end
