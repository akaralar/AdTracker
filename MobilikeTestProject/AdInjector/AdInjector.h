//
//  AdInjector.h
//  MobilikeTestProject
//
//  Created by Ahmet Karalar on 16/11/14.
//  Copyright (c) 2014 Ahmet Karalar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AdInjector : NSObject

- (instancetype)initWithTableView:(UITableView *)tableView;

- (void)injectAdWithURL:(NSURL *)adURL
            trackingURL:(NSURL *)trackingURL
            atIndexPath:(NSIndexPath *)indexPath;

@end
