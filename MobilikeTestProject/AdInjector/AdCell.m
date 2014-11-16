//
//  AdCell.m
//  MobilikeTestProject
//
//  Created by Ahmet Karalar on 16/11/14.
//  Copyright (c) 2014 Ahmet Karalar. All rights reserved.
//

#import "AdCell.h"

@implementation AdCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (!self) {
        return nil;
    }

    _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_webView];
    
    return self;
}

@end
