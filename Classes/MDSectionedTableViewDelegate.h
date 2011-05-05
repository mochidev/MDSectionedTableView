//
//  MDSectionedTableViewDelegate.h
//  MDSectionedTableViewDemo
//
//  Created by Dimitri Bouniol on 5/4/11.
//  Copyright 2011 Mochi Development, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol MDSectionedTableViewDelegate <NSObject>

@optional
- (void)tableView:(MDSectionedTableView *)tableView didSelectRow:(NSUInteger)row inSection:(NSUInteger)section;
- (void)tableView:(MDSectionedTableView *)tableView didDoubleClickRow:(NSUInteger)row inSection:(NSUInteger)section;

@end
