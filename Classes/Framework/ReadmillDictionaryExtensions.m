//
//  ReadmillDictionaryExtensions.m
//  Readmill Framework
//
//  Created by Work on 12/01/2011.
//  Copyright 2011 KennettNet Software Limited. All rights reserved.
//

#import "ReadmillDictionaryExtensions.h"


@implementation NSDictionary (ReadmillDictionaryExtensions)

-(NSDictionary *)dictionaryByRemovingNullValues {
    
    NSMutableDictionary *cleanedDictionary = [[self mutableCopy] autorelease];
    NSArray *nullKeys = [self allKeysForObject:[NSNull null]];
    [cleanedDictionary removeObjectsForKeys:nullKeys];
    
    return [NSDictionary dictionaryWithDictionary:cleanedDictionary];
}

@end
