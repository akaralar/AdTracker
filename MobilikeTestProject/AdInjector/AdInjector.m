//
//  AdInjector.m
//  MobilikeTestProject
//
//  Created by Ahmet Karalar on 16/11/14.
//  Copyright (c) 2014 Ahmet Karalar. All rights reserved.
//

#import "AdInjector.h"
#import "TableViewAd.h"
#import "AdCell.h"

static NSString * const kAdCellIdentifier = @"AdCell";

@interface AdInjector () <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) id<UITableViewDataSource> tableViewDataSource;
@property (nonatomic, weak) id<UITableViewDelegate> tableViewDelegate;

@property (nonatomic) NSMutableArray *ads;
@property (nonatomic) NSMutableSet *trackInProgressAdIDs;

- (NSNumber *)createIndexedAdIdentifier;
- (NSIndexPath *)adjustedContentIndexPathForOriginalContentIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)adjustedAdIndexPathForOriginalAdIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)originalContentIndexPathForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)shouldInjectAdAtIndexPath:(NSIndexPath *)indexPath;
- (TableViewAd *)adForIndexPath:(NSIndexPath *)indexPath;
- (void)checkVisibilityOfAdCell:(AdCell *)cell inView:(UIView *)view;

- (NSInteger)numberOfAdsInSection:(NSInteger)section;

- (void)trackAd:(TableViewAd *)ad;

@end

@implementation AdInjector

- (instancetype)initWithTableView:(UITableView *)tableView
{
    self = [super init];

    if (!self) {
        return nil;
    }

    _tableView = tableView;
    _tableViewDataSource = tableView.dataSource;
    _tableViewDelegate = tableView.delegate;

    _tableView.dataSource = self;
    _tableView.delegate = self;

    _ads = [NSMutableArray array];
    _trackInProgressAdIDs = [NSMutableSet set];

    [tableView registerClass:[AdCell class]
      forCellReuseIdentifier:kAdCellIdentifier];

    return self;
}

- (void)injectAdWithURL:(NSURL *)adURL
            trackingURL:(NSURL *)trackingURL
            atIndexPath:(NSIndexPath *)indexPath
{

    TableViewAd *ad = [[TableViewAd alloc] init];
    ad.adURL = adURL;
    ad.trackingURL = trackingURL;
    ad.indexPath = indexPath;
    ad.indexedAdIdentifier = [self createIndexedAdIdentifier];

    // replace if an ad for that index path already exists
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];

    [self.ads enumerateObjectsUsingBlock:^(TableViewAd *ad, NSUInteger idx, BOOL *stop) {

        if (ad.indexPath.section == indexPath.section &&
            ad.indexPath.row == indexPath.row) {

            [indexSet addIndex:idx];
        }
    }];

    [self.ads removeObjectsAtIndexes:indexSet];
    [self.ads addObject:ad];

    [self.tableView reloadData];
}

#pragma mark - Helpers

- (NSNumber *)createIndexedAdIdentifier
{
    NSNumber *identifier = @0;

    if (self.ads.count == 0) {

        return identifier;
    }

    for (TableViewAd *ad in self.ads) {

        if (ad.indexedAdIdentifier.integerValue > identifier.integerValue) {
            identifier = ad.indexedAdIdentifier;
        }
    }

    identifier = @(identifier.integerValue + 1);

    return identifier;
}

- (NSIndexPath *)adjustedContentIndexPathForOriginalContentIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfAdsBeforeOriginalIndexPath = 0;

    for (TableViewAd *ad in self.ads) {

        if (ad.indexPath.section == indexPath.section &&
            ad.indexPath.row <= indexPath.row) {

            numberOfAdsBeforeOriginalIndexPath++;
        }
    }

    return [NSIndexPath indexPathForRow:indexPath.row + numberOfAdsBeforeOriginalIndexPath
                              inSection:indexPath.section];
}

- (NSIndexPath *)adjustedAdIndexPathForOriginalAdIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfAdsBeforeOriginalIndexPath = 0;

    for (TableViewAd *ad in self.ads) {

        if (ad.indexPath.section == indexPath.section &&
            ad.indexPath.row < indexPath.row) {

            numberOfAdsBeforeOriginalIndexPath++;
        }
    }

    return [NSIndexPath indexPathForRow:indexPath.row + numberOfAdsBeforeOriginalIndexPath
                              inSection:indexPath.section];
}

- (BOOL)shouldInjectAdAtIndexPath:(NSIndexPath *)indexPath
{
    for (TableViewAd *ad in self.ads) {

        NSIndexPath *adjustedAdPath = [self adjustedAdIndexPathForOriginalAdIndexPath:ad.indexPath];

        if (adjustedAdPath.section == indexPath.section &&
            adjustedAdPath.row == indexPath.row) {

            return YES;
        }
    }

    return NO;
}

- (NSInteger)numberOfAdsInSection:(NSInteger)section
{
    NSInteger numberOfAdsInSection = 0;

    for (TableViewAd *ad in self.ads) {

        if (ad.indexPath.section == section) {

            numberOfAdsInSection++;
        }
    }

    return numberOfAdsInSection;
}

- (NSIndexPath *)originalContentIndexPathForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfAdsBefore = 0;

    for (TableViewAd *ad in self.ads) {

        NSIndexPath *adjusted = [self adjustedAdIndexPathForOriginalAdIndexPath:ad.indexPath];
        if (adjusted.section == indexPath.section &&
            adjusted.row < indexPath.row) {

            numberOfAdsBefore++;
        }
    }

    return [NSIndexPath indexPathForRow:indexPath.row - numberOfAdsBefore
                              inSection:indexPath.section];

}

- (TableViewAd *)adForIndexPath:(NSIndexPath *)indexPath
{
    for (TableViewAd *ad in self.ads) {

        NSIndexPath *adjustedAdPath = [self adjustedAdIndexPathForOriginalAdIndexPath:ad.indexPath];

        if (adjustedAdPath.section == indexPath.section &&
            adjustedAdPath.row == indexPath.row) {

            return ad;
        }
    }
    
    return nil;
}

- (void)checkVisibilityOfAdCell:(AdCell *)cell inView:(UIView *)view {

    CGRect topHalfRect, bottomHalfRect;

    CGRectDivide(cell.frame, &topHalfRect, &bottomHalfRect, cell.frame.size.height / 2, CGRectMinYEdge);
    CGRect cellRect = [view convertRect:topHalfRect toView:view.superview];

    if (CGRectContainsRect(view.frame, cellRect)) {

        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        TableViewAd *ad = [self adForIndexPath:indexPath];

        [self trackAd:ad];
    }
}

- (void)trackAd:(TableViewAd *)ad
{
    if (!ad.tracked &&
        ![self.trackInProgressAdIDs containsObject:ad.indexedAdIdentifier]) {

        [self.trackInProgressAdIDs addObject:ad.indexedAdIdentifier];

        NSURLRequest *request = [NSURLRequest requestWithURL:ad.trackingURL];
        NSURLSession *session = [NSURLSession sharedSession];
        NSLog(@"starting to track ad with request: %@, ad id: %@", request, ad.indexedAdIdentifier);
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                        NSLog(@"finished tracking ad with request: %@, ad id: %@", request, ad.indexedAdIdentifier);
                        ad.tracked = YES;
                        [self.trackInProgressAdIDs removeObject:ad.indexedAdIdentifier];
                    }] resume];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger originalRows = [self.tableViewDataSource tableView:tableView
                                           numberOfRowsInSection:section];
    NSInteger adsInSection = [self numberOfAdsInSection:section];
    NSInteger rows = originalRows + adsInSection;

    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;

    if ([self shouldInjectAdAtIndexPath:indexPath]) {

        AdCell *adCell = [tableView dequeueReusableCellWithIdentifier:kAdCellIdentifier
                                                         forIndexPath:indexPath];
        CGRect frame = adCell.contentView.bounds;
        frame.size.width = 300;
        adCell.webView.frame = frame;
        adCell.webView.center = adCell.contentView.center;

        TableViewAd *ad = [self adForIndexPath:indexPath];
        NSURLRequest *request = [NSURLRequest requestWithURL:ad.adURL];
        [adCell.webView loadRequest:request];

        cell = adCell;
    }
    else {
        NSIndexPath *originalIndexPath = [self originalContentIndexPathForIndexPath:indexPath];

        cell = [self.tableViewDataSource tableView:tableView
                             cellForRowAtIndexPath:originalIndexPath];
    }

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = 1;
    if ([self.tableViewDataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {

        sections = [self.tableViewDataSource numberOfSectionsInTableView:tableView];
    }

    return sections;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self shouldInjectAdAtIndexPath:indexPath]) {

        return 250;
    }
    else {

        if ([self.tableViewDelegate
             respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {

            return [self.tableViewDelegate tableView:tableView heightForRowAtIndexPath:indexPath];
        }
        else {

            // default
            return 45;
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.tableViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {

        [self.tableViewDelegate scrollViewDidScroll:scrollView];
    }

    for (TableViewAd *ad in self.ads) {

        NSIndexPath *adjusted = [self adjustedAdIndexPathForOriginalAdIndexPath:ad.indexPath];
        AdCell *cell = (AdCell *)[self.tableView cellForRowAtIndexPath:adjusted];

        if (cell) {
            [self checkVisibilityOfAdCell:cell inView:scrollView];
        }
    }
}

@end

