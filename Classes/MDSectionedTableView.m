//
//  MDSectionedTableView.m
//  MDSectionedTableView
//
//  Created by Dimitri Bouniol on 5/1/11.
//  Copyright 2011 Mochi Development, Inc. All rights reserved.
//  
//  Copyright (c) 2011 Dimitri Bouniol, Mochi Development, Inc.
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//  
//  Mochi Dev, and the Mochi Development logo are copyright Mochi Development, Inc.
//  
//  Also, it'd be super awesome if you credited this page in your about screen :)
//  

#import "MDSectionedTableView.h"
#import "MDTableViewCell.h"

@implementation MDSectionedTableView

@synthesize dataSource, delegate, rowHeight, headerHeight, selectedRow, selectedSection;

- (id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect])) {
        dequeuedCells = [[NSMutableSet alloc] init];
        
        rowHeight = 18;
        headerHeight = 18;
        
        selectedRow = NSNotFound;
        selectedSection = NSNotFound;
    }
    
    return self;
}

- (void)selectRow:(NSUInteger)row inSection:(NSUInteger)section
{
    selectedRow = row;
    selectedSection = section;
    
    if (selectedSection != NSNotFound && selectedSection < [cellSections count]) {
        if (selectedRow != NSNotFound && selectedRow < [[cellSections objectAtIndex:selectedSection] count]) {
            MDTableViewCell *cell = [[cellSections objectAtIndex:selectedSection] objectAtIndex:selectedRow];
            if ((NSNull *)cell != [NSNull null]) {
                cell.selected = YES;
            }
        }
    }
}

- (void)deselectRow:(NSUInteger)row inSection:(NSUInteger)section
{
    if (selectedSection != NSNotFound && selectedSection < [cellSections count]) {
        if (selectedRow != NSNotFound && selectedRow < [[cellSections objectAtIndex:selectedSection] count]) {
            MDTableViewCell *cell = [self cellForRow:selectedRow inSection:selectedSection];
            cell.selected = NO;
        }
    }
    
    if (row == selectedRow && section == selectedSection) {
        selectedRow = NSNotFound;
        selectedSection = NSNotFound;
    }
}

- (void)awakeFromNib
{
    [self reloadData];
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
}

- (void)dealloc
{
    [dequeuedCells release];
    [cellSections release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (NSView *)hitTest:(NSPoint)aPoint
{
    //if ([[[NSApplication sharedApplication] currentEvent] type] != NSScrollWheel) 
    //    return [super hitTest:aPoint];

    return self;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint click = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    for (int section = 0; section < [cellSections count]; section++) {
        NSArray *rows = [cellSections objectAtIndex:section];
        for (int row = 0; row < [rows count]; row++) {
            id cell = [rows objectAtIndex:row];
            if (cell != [NSNull null] && NSPointInRect(click, [(NSView *)cell frame])) {
                if (section != selectedSection || row != selectedRow) {
                    [self deselectRow:selectedRow inSection:selectedSection];
                    
                    [(MDTableViewCell *)cell setSelected:YES];
                    selectedRow = row;
                    selectedSection = section;
                    
                    [self tableView:self didSelectRow:selectedRow inSection:selectedSection];
                } else if ([[NSApp currentEvent] modifierFlags]&NSShiftKeyMask || [[NSApp currentEvent] modifierFlags]&NSCommandKeyMask) {
                    [self deselectRow:selectedRow inSection:selectedSection];
                    [self tableView:self didSelectRow:NSNotFound inSection:NSNotFound]; // deselected
                }
                
                return;
            }
        }
    }
    
    [self deselectRow:selectedRow inSection:selectedSection];
    [self tableView:self didSelectRow:NSNotFound inSection:NSNotFound]; // nothing selected
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2) {
        [self tableView:self didDoubleClickRow:selectedRow inSection:selectedSection];
    }
}

- (IBAction)reloadData:(id)sender
{
    [self reloadData];
}

- (void)reloadData
{
    if ([self superview] != clipView && [[self superview] isMemberOfClass:[NSClipView class]]) {
        clipView = (NSClipView *)[self superview];
        
        [clipView setPostsBoundsChangedNotifications:YES];
        [clipView setPostsFrameChangedNotifications:YES];
        [clipView setCopiesOnScroll:NO];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(viewBoundsChanged:)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:clipView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(viewFrameChanged:)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:clipView];
    }
    
    NSScrollView *scrollView = (NSScrollView *)[clipView superview];
    [scrollView setLineScroll:rowHeight];
    [scrollView setBackgroundColor:[NSColor whiteColor]];
    [scrollView setDrawsBackground:YES];
    
    calculatedHeight = 0;
    
    NSUInteger numberOfSections = [self numberOfSectionsInTableView:self];
    
    for (id view in headerCells) {
        if (view != [NSNull null]) {
            [(NSView *)view removeFromSuperview];
        }
    }
    
    for (NSArray *views in cellSections) {
        for (id view in views) {
            if (view != [NSNull null]) {
                [(NSView *)view removeFromSuperview];
            }
        }
    }
    
    [cellSections release];
    cellSections = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    [headerCells release];
    headerCells = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    
    for (int i = 0; i < numberOfSections; i++) {
        NSUInteger numberOfRows = [self tableView:self numberOfRowsInSection:i];
        //NSLog(@"Section %d, %d rows", i, numberOfRows);
        calculatedHeight += headerHeight + rowHeight*numberOfRows;
        NSMutableArray *cellRows = [[NSMutableArray alloc] initWithCapacity:numberOfRows];
        for (int j = 0; j < numberOfRows; j++) {
            [cellRows addObject:[NSNull null]];
        }
        [cellSections addObject:cellRows];
        [cellRows release];
        [headerCells addObject:[NSNull null]];
    }
    
    //[self deselectRow:NSNotFound inSection:NSNotFound];
    
    [self layoutSubviews];
}

- (void)viewBoundsChanged:(NSNotification *)aNotification
{
    [self layoutSubviews];
}

- (void)viewFrameChanged:(NSNotification *)aNotification
{
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    if ([clipView frame].size.height > calculatedHeight) {
        [self setFrame:NSMakeRect(0, 0, [clipView frame].size.width, [clipView frame].size.height)];
    } else {
        [self setFrame:NSMakeRect(0, 0, [clipView frame].size.width, calculatedHeight)];
    }
    
    CGFloat offset = calculatedHeight - [clipView frame].size.height - [clipView bounds].origin.y;
    if (offset < 0) offset = 0;
    
    CGFloat clipHeight = [clipView frame].size.height;
    CGFloat actualHeight = [self frame].size.height;
    CGFloat cellWidth = [self frame].size.width;
    
    NSUInteger numberOfSections = [cellSections count];
    
    CGFloat cellOrigin = 0;
    
    MDTableViewCell *recentHeader = nil;
    NSRect cellFrame;
    
    for (int section = 0; section < numberOfSections; section++) {
        NSUInteger numberOfRows = [[cellSections objectAtIndex:section] count];
        //NSLog(@"-Section %d, %d rows", section, numberOfRows);
        if (cellOrigin + headerHeight + rowHeight * numberOfRows < offset || cellOrigin >= offset+clipHeight) {
            [self setHeaderCell:nil forSection:section];
        } else {
            MDTableViewCell *cell = [self headerCellForSection:section];
            
            if (!cell) {
                cell = [self tableView:self cellForHeaderOfSection:section];
                [self setHeaderCell:cell forSection:section];
            }
            
            if ([cell superview] != self) {
                [self addSubview:cell];
            }
            
            if (cellOrigin >= offset) {
                //NSLog(@"%d A cell: %@", section, cell);
                cellFrame = NSMakeRect(0, actualHeight-cellOrigin-headerHeight, cellWidth, headerHeight);
            } else if (cellOrigin + rowHeight * numberOfRows < offset) {
                //NSLog(@"%d C cell: %@", section, cell);
                cellFrame = NSMakeRect(0, actualHeight-cellOrigin-rowHeight * numberOfRows-headerHeight, cellWidth, headerHeight);
            } else {
                //NSLog(@"%d B cell: %@", section, cell);
                cellFrame = NSMakeRect(0, actualHeight-offset-headerHeight, cellWidth, headerHeight);
            }
            
            NSRect cellFrameAdjustments = cell.frameAdjustments;
            
            cellFrame.origin.x += cellFrameAdjustments.origin.x;
            cellFrame.origin.y += cellFrameAdjustments.origin.y;
            cellFrame.size.width += cellFrameAdjustments.size.width;
            cellFrame.size.height += cellFrameAdjustments.size.height;
            
            [cell setFrame:cellFrame];
            
            if (recentHeader == nil)
                recentHeader = cell;
        }
        
        cellOrigin += headerHeight;
        
        for (int row = 0; row < numberOfRows; row++) {
            if (cellOrigin + rowHeight < offset || cellOrigin >= offset+clipHeight) {
                //NSLog(@"%d:%d cell: %@", section, row, [self cellForRow:row inSection:section]);
                [self setCell:nil forRow:row inSection:section];
            } else {
                MDTableViewCell *cell = [self cellForRow:row inSection:section];
                //NSLog(@"  %d:%d cell: %@", section, row, cell);
                if (!cell) {
                    cell = [self tableView:self cellForRow:row inSection:section];
                    [self setCell:cell forRow:row inSection:section];
                }
                
                if ([cell superview] != self) {
                    [self addSubview:cell positioned:NSWindowBelow relativeTo:nil];
                }
                
                cell.selected = (section == selectedSection && row == selectedRow);
                
                cell.alternatedRow = row % 2;
                
                cellFrame = NSMakeRect(0, actualHeight-cellOrigin-rowHeight, cellWidth, rowHeight);
                
                NSRect cellFrameAdjustments = cell.frameAdjustments;
                
                cellFrame.origin.x += cellFrameAdjustments.origin.x;
                cellFrame.origin.y += cellFrameAdjustments.origin.y;
                cellFrame.size.width += cellFrameAdjustments.size.width;
                cellFrame.size.height += cellFrameAdjustments.size.height;
                
                [cell setFrame:cellFrame];
            }
            cellOrigin += rowHeight;
        }
    }
}

- (MDTableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    MDTableViewCell *dequeuedCell = nil;
    for (MDTableViewCell *aCell in dequeuedCells) {
        if ([aCell.reuseIdentifier isEqualToString:identifier]) {
            dequeuedCell = aCell;
            break;
        }
    }
    if (dequeuedCell) {
        [dequeuedCell retain];
        [dequeuedCells removeObject:dequeuedCell];
    }
    return [dequeuedCell autorelease];
}

- (NSInteger)tableView:(MDSectionedTableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger returnValue = 0;
    
    if (dataSource && [dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)])
        returnValue = [dataSource tableView:tableView numberOfRowsInSection:section];
    
    return returnValue;
}

- (MDTableViewCell *)tableView:(MDSectionedTableView *)tableView cellForRow:(NSInteger)row inSection:(NSInteger)section
{
    MDTableViewCell *returnValue = nil;
    
    if (dataSource && [dataSource respondsToSelector:@selector(tableView:cellForRow:inSection:)])
        returnValue = [dataSource tableView:tableView cellForRow:row inSection:section];
    
    return returnValue;
}

- (MDTableViewCell *)tableView:(MDSectionedTableView *)tableView cellForHeaderOfSection:(NSInteger)section
{
    MDTableViewCell *returnValue = nil;
    
    if (dataSource && [dataSource respondsToSelector:@selector(tableView:cellForHeaderOfSection:)])
        returnValue = [dataSource tableView:tableView cellForHeaderOfSection:section];
    
    return returnValue;
}

- (NSInteger)numberOfSectionsInTableView:(MDSectionedTableView *)tableView
{
    NSInteger returnValue = 1;
    
    if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)])
        returnValue = [dataSource numberOfSectionsInTableView:tableView];
    
    return returnValue;
}

- (void)tableView:(MDSectionedTableView *)tableView didSelectRow:(NSUInteger)row inSection:(NSUInteger)section
{
    if (delegate && [delegate respondsToSelector:@selector(tableView:didSelectRow:inSection:)])
        [delegate tableView:tableView didSelectRow:row inSection:section];
}

- (void)tableView:(MDSectionedTableView *)tableView didDoubleClickRow:(NSUInteger)row inSection:(NSUInteger)section
{
    if (delegate && [delegate respondsToSelector:@selector(tableView:didDoubleClickRow:inSection:)])
        [delegate tableView:tableView didDoubleClickRow:row inSection:section];
}

- (MDTableViewCell *)headerCellForSection:(NSUInteger)section
{
    id cell = [headerCells objectAtIndex:section];
    
    if (cell == [NSNull null]) {
        cell = nil;
    }
    
    return cell;
}

- (MDTableViewCell *)cellForRow:(NSUInteger)row inSection:(NSUInteger)section
{
    id cell = [[cellSections objectAtIndex:section] objectAtIndex:row];
    
    if (cell == [NSNull null]) {
        cell = nil;
    }
    
    return cell;
}

- (void)setHeaderCell:(MDTableViewCell *)cell forSection:(NSUInteger)section
{
    id oldCell = [[headerCells objectAtIndex:section] retain];
    
    if (cell) {
        [headerCells replaceObjectAtIndex:section withObject:cell];
    } else {
        [headerCells replaceObjectAtIndex:section withObject:[NSNull null]];
    }
    
    if (oldCell && oldCell != [NSNull null]) {
        [dequeuedCells addObject:oldCell];
        
        [oldCell removeFromSuperview];
    }
    
    [oldCell release];
}

- (void)setCell:(MDTableViewCell *)cell forRow:(NSUInteger)row inSection:(NSUInteger)section
{
    id oldCell = [[[cellSections objectAtIndex:section] objectAtIndex:row] retain];
    
    if (cell) {
        [[cellSections objectAtIndex:section] replaceObjectAtIndex:row withObject:cell];
    } else {
        [[cellSections objectAtIndex:section] replaceObjectAtIndex:row withObject:[NSNull null]];
    }
    
    if (oldCell && oldCell != [NSNull null]) {
        [dequeuedCells addObject:oldCell];
        
        [oldCell removeFromSuperview];
    }
    
    [oldCell release];
}

@end
