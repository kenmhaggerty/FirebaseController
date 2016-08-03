//
//  KMHFirebaseController+PRIVATE.h
//  Sandbox
//
//  Created by Ken M. Haggerty on 7/27/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

#pragma mark - // NOTES (Public) //

// This category on KMHFirebaseController contains private method declarations that should be available for use by KMHFirebaseController+Auth and KMHFirebaseController+ACL.

#pragma mark - // IMPORTS (Public) //

@import Firebase;

#pragma mark - // PROTOCOLS //

#pragma mark - // DEFINITIONS (Public) //

#import "KMHFirebaseController.h"

@interface KMHFirebaseController (PRIVATE)
+ (instancetype)sharedController;
- (void)setup;
@end
