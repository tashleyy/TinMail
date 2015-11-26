//
//  ActionsTableViewController.m
//  TinMail
//
//  Created by Ashley Tjahjadi on 11/24/15.
//  Copyright © 2015 Tiffany Tjahjadi. All rights reserved.
//

#import "ActionsTableViewController.h"
#import "GmailService.h"

@interface ActionsTableViewController ()

@property (strong, nonatomic) GmailService *gmail;

@end

@implementation ActionsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.gmail = [GmailService sharedService];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"actionCell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = self.gmail.actionNames[indexPath.row];
    if (self.isLeftAction) {
        if (indexPath.row == self.gmail.leftIndex) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        if (indexPath.row == self.gmail.rightIndex) cell.accessoryType = UITableViewCellAccessoryCheckmark;        
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    for (int i = 0; i < 6; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:path];
        if (i == indexPath.row) {
            if (self.isLeftAction) self.gmail.leftIndex = i;
            else self.gmail.rightIndex = i;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
