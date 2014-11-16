//
//  TableViewAd.h
//  MobilikeTestProject
//
//  Created by Ahmet Karalar on 16/11/14.
//  Copyright (c) 2014 Ahmet Karalar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TableViewAd : NSObject

@property (nonatomic) NSURL *adURL;
@property (nonatomic) NSURL *trackingURL;
@property (nonatomic) NSIndexPath *indexPath;

@property (nonatomic) BOOL tracked;
@property (nonatomic) NSNumber *indexedAdIdentifier;

@end
