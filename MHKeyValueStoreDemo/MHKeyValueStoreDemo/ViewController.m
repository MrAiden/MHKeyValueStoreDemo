//
//  ViewController.m
//  MHKeyValueStoreDemo
//
//  Created by Mortar on 2018/11/26.
//  Copyright © 2018 Yan. All rights reserved.
//

#import "ViewController.h"
#import "MHKeyValueStore.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    MHKeyValueStore *store = [[MHKeyValueStore alloc] initDBWithName:@"testDatabase.sqlite"];
    [store createTableWithName:@"testTable"];
    NSDictionary *dict = @{@"name": @"Mortar", @"age": @(12)};
    NSString *key = @"key";
    NSString *tableName = @"testTable";
    [store setObject:dict forKey:key intoTable:tableName];
    NSLog(@"%@", [store objectForKey:key fromTable:tableName]);
}


@end
