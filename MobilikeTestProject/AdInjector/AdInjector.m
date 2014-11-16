//
//  AdInjector.m
//  MobilikeTestProject
//
//  Created by Ahmet Karalar on 16/11/14.
//  Copyright (c) 2014 Ahmet Karalar. All rights reserved.
//

#import "AdInjector.h"
#import "TableViewAd.h"

@interface AdInjector () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) id<UITableViewDataSource> tableViewDataSource;
@property (nonatomic, weak) id<UITableViewDelegate> tableViewDelegate;

@property (nonatomic) NSMutableArray *ads;

- (NSNumber *)createIndexedAdIdentifier;
- (NSIndexPath *)adjustedIndexPathForOriginalIndexPath:(NSIndexPath *)indexPath;

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

- (NSIndexPath *)adjustedIndexPathForOriginalIndexPath:(NSIndexPath *)indexPath
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

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewDataSource tableView:tableView numberOfRowsInSection:section];
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tableViewDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableViewDataSource numberOfSectionsInTableView:tableView];
}

//
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section;
//
//// Editing
//
//// Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
//
//// Moving/reordering
//
//// Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
//
//// Index
//
//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView;                                                    // return list of section titles to display in section index view (e.g. "ABCD...Z#")
//- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;  // tell table which section corresponds to section title/index (e.g. "B",1))
//
//// Data manipulation - insert and delete support
//
//// After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
//// Not called for edit actions using UITableViewRowAction - the action's handler will be invoked instead
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
//
//// Data manipulation - reorder / moving support
//
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

#pragma mark - UITableViewDelegate

@end

