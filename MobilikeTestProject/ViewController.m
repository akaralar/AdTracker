//
//  ViewController.m
//  MobilikeTestProject
//
//  Created by Ahmet Karalar on 16/11/14.
//  Copyright (c) 2014 Ahmet Karalar. All rights reserved.
//

#import "ViewController.h"
#import "AdInjector.h"

static NSString * const kAdURL = @"http://media.mobworkz.com/adserver/seamless-300x250/";
static NSString * const kAdTrackingURL = @"http://tracker.seamlessapi.com/track/imp/ahmetKaralar";
static const NSInteger kAdCellCount = 25;

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) AdInjector *injector;

- (void)injectAdAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    [self.view addSubview:self.tableView];

    self.injector = [[AdInjector alloc] initWithTableView:self.tableView];

    for (NSInteger i = 0; i < kAdCellCount; i++) {

        NSIndexPath *path = [NSIndexPath indexPathForRow:(i * 4 + 2) inSection:0];
        [self injectAdAtIndexPath:path];
    }
}

#pragma mark - Helpers

- (void)injectAdAtIndexPath:(NSIndexPath *)indexPath
{
    [self.injector injectAdWithURL:[NSURL URLWithString:kAdURL]
                       trackingURL:[NSURL URLWithString:kAdTrackingURL]
                       atIndexPath:indexPath];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = NSStringFromClass([UITableViewCell class]);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier
                                                            forIndexPath:indexPath];

    cell.textLabel.text = @(indexPath.row).stringValue;

    return cell;
}

#pragma mark - UITableViewDelegate


@end
