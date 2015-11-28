//
//  SettingsTableViewController.m
//  TinMail
//
//  Created by Ashley Tjahjadi on 11/24/15.
//  Copyright © 2015 Tiffany Tjahjadi. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "ActionsTableViewController.h"
#import "GmailService.h"
#import <Firebase/Firebase.h>

@interface SettingsTableViewController ()

@property (strong, nonatomic) GmailService *gmail;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.gmail = [GmailService sharedService];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
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
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingCell" forIndexPath:indexPath];
    
    // Configure the cell...
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Left Action";
        cell.detailTextLabel.text = self.gmail.actionNames[self.gmail.leftIndex];
    } else {
        cell.textLabel.text = @"Right Action";
        cell.detailTextLabel.text = self.gmail.actionNames[self.gmail.rightIndex];
    }
    
    return cell;
}

- (IBAction)doneButtonTapped:(id)sender {
    [self updateSettings];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateSettings {
    GTLQueryGmail *query = [GTLQueryGmail queryForUsersGetProfile];
    [self.gmail.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        GTLGmailProfile *profile = object;
        NSString *email = profile.emailAddress;
        NSArray *tokens = [email componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@."]];
        Firebase *root = [[Firebase alloc] initWithUrl:@"https://tinmail.firebaseio.com/users"];
        Firebase *user = [root childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", tokens[2], tokens[1], tokens[0]]];
        NSDictionary *dict = @{ @"left" : [NSNumber numberWithUnsignedInteger:self.gmail.leftIndex] , @"right" : [NSNumber numberWithUnsignedInteger:self.gmail.rightIndex] };
        [user updateChildValues:dict];
    }];
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    ActionsTableViewController *dest = segue.destinationViewController;
    if (self.tableView.indexPathForSelectedRow.row == 0) {
        dest.isLeftAction = YES;
        dest.title = @"Left Action";
    } else {
        dest.isLeftAction = NO;
        dest.title = @"Right Action";
    }
}

@end
