//
//  FirebaseQuery.m
//  PushQuery
//
//  Created by Ken M. Haggerty on 3/11/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "FirebaseQuery+FQuery.h"

#pragma mark - // DEFINITIONS (Private) //

@interface FirebaseQuery ()
@property (nonatomic, strong) NSString *key;
@property (nonatomic) FirebaseQueryRelation relation;
@property (nonatomic, strong) id value;
+ (FIRDatabaseQuery *)appendRelation:(FirebaseQueryRelation)relation withValue:(id)value toQuery:(FIRDatabaseQuery *)query;
@end

@implementation FirebaseQuery

#pragma mark - // SETTERS AND GETTERS //

#pragma mark - // INITS AND LOADS //

- (id)init {
    return [self initWithKey:nil relation:FirebaseKeyIsEqualTo value:nil];
}

- (id)initWithKey:(NSString *)key relation:(FirebaseQueryRelation)relation value:(id)value {
    self  = [super init];
    if (self) {
        _key = key;
        _relation = relation;
        _value = value;
    }
    
    return self;
}

#pragma mark - // PUBLIC METHODS (Initializers) //

+ (instancetype)queryWithKey:(NSString *)key relation:(FirebaseQueryRelation)relation value:(id)value {
    return [[FirebaseQuery alloc] initWithKey:key relation:relation value:value];
}

#pragma mark - // CATEGORY METHODS (FQuery) //

+ (FIRDatabaseQuery *)queryWithQueryItem:(FirebaseQuery *)queryItem andDirectory:(FIRDatabaseReference *)directory {
    FIRDatabaseQuery *query = [directory queryOrderedByChild:queryItem.key];
    return [FirebaseQuery appendRelation:queryItem.relation withValue:queryItem.value toQuery:query];
}

+ (FIRDatabaseQuery *)appendQueryItem:(FirebaseQuery *)queryItem toQuery:(FIRDatabaseQuery *)query {
    query = [query queryOrderedByChild:queryItem.key];
    return [FirebaseQuery appendRelation:queryItem.relation withValue:queryItem.value toQuery:query];
}

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

- (NSString *)description {
    NSString *relation;
    switch (self.relation) {
        case FirebaseKeyIsEqualTo:
            relation = @"==";
            break;
        case FirebaseKeyIsLessThanOrEqualTo:
            relation = @"<=";
            break;
        case FirebaseKeyIsGreaterThanOrEqualTo:
            relation = @">=";
            break;
    }
    return [NSString stringWithFormat:@"%@: %@ %@ %@", NSStringFromClass([self class]), self.key, relation, self.value];
}

#pragma mark - // PRIVATE METHODS //

+ (FIRDatabaseQuery *)appendRelation:(FirebaseQueryRelation)relation withValue:(id)value toQuery:(FIRDatabaseQuery *)query {
    switch (relation) {
        case FirebaseKeyIsEqualTo:
            return [query queryEqualToValue:value];
        case FirebaseKeyIsLessThanOrEqualTo:
            return [query queryStartingAtValue:value];
        case FirebaseKeyIsGreaterThanOrEqualTo:
            return [query queryEndingAtValue:value];
    }
}

@end
