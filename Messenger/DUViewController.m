//
//  DUViewController.m
//  Oxwall Messenger
//
//  Created by Thomas Ochman on 2013-09-11.
//  Copyright (c) 2013 Underplot ltd. All rights reserved.
//


#import "DUViewController.h"
#import "Constants.h"
#import "HUD.h"
#import "JSONModelLib.h"
#import "ConversationFeed.h"
#import "ConversationsModel.h"
#import "MessagesViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "SDSegmentedControl.h"
#import "Lockbox.h"

@interface DUViewController (){
    ConversationFeed* _feed;
    
    }

@end

@implementation DUViewController

@synthesize username;
@synthesize realname;
@synthesize sex;
@synthesize membersince;
@synthesize presentation;
@synthesize avatarURL;
@synthesize convAvatar;
@synthesize tableView = _tableView;
@synthesize profileView = _profileView;
@synthesize userid;
@synthesize senderAvatar;
@synthesize segmentedControl, selectedSegmentLabel;
@synthesize ConversationButton  = conversatinbutton;
@synthesize messageCountsArr, messageCountsArrCopy, messageCountsDic, messageCountsDicCopy, messageObserver, localNotif;

static NSString * kMessageCountChanged = @"NULL";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self fireUpdate];

    }
    return self;
}



- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    //Get everything together
    [self loadStandardUser];
    [self setLProfileLabels];
    
    //Segmented control
    segmentedControl.selectedSegmentIndex = 1;
    [self.tableView setHidden:NO];
    conversatinbutton.hidden = NO;
    [self.profileView setHidden:YES];
    
    // Title
    self.title = realname;
    [self.navigationItem setHidesBackButton:YES];
    
    //Some settings
    userid = [Lockbox stringForKey:@"userid"];
    [self updateSelectedSegmentLabel];
    
    
    //Profile view
    [self.profileView addSubview:membersinceLabel];
    [self.profileView addSubview:presentationTextview];
    [self.profileView addSubview:sexLabel];
    
    
    
    //Initialize all stuff
    messageCountsDic = [[NSMutableDictionary alloc]initWithCapacity:1000];
    messageCountsDicCopy = [[NSMutableDictionary alloc]initWithCapacity:1000];
    [messageCountsDic addObserver:self forKeyPath:@"results" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

    //Notifications
    localNotif = [[UILocalNotification alloc]init];
    // Notification details
    localNotif.alertBody = @"There is a new messege for you";
    // Set the action button
    localNotif.alertAction = @"View";
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.applicationIconBadgeNumber = 0;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    

}

-(void)viewDidAppear:(BOOL)animated
{
    
    //Set the identifier
    [self fireUpdate];
    timer1 = [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self
                                            selector: @selector(fireUpdate) userInfo: nil repeats: YES];
    
    
    
}

-(void)viewWillDisappear:(BOOL)animated  {
    [super viewWillDisappear:animated];
    
//        [self.messageCountsDic removeObserver:self
//                                forKeyPath:@"messagecount"
//                                   context:nil];

    
    [timer1 invalidate];
}

- (void)updateSelectedSegmentLabel
{
    self.selectedSegmentLabel.font = [UIFont boldSystemFontOfSize:self.selectedSegmentLabel.font.pointSize];
    self.selectedSegmentLabel.text = [NSString stringWithFormat:@"%d", self.segmentedControl.selectedSegmentIndex];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void)
                   {
                       self.selectedSegmentLabel.font = [UIFont systemFontOfSize:self.selectedSegmentLabel.font.pointSize];
                   });
}


-(void)fireUpdate  {
    //[HUD showUIBlockingIndicatorWithText:@"Getting Conversations"];
    NSString *callURL = [NSString stringWithFormat:@"%@/inbox_conversations.php?user=%@", BASE_URL, userid];
    
    //fetch the feed
    _feed = [[ConversationFeed alloc] initFromURLWithString:callURL
                                                 completion:^(JSONModel *model, JSONModelError *err) {
                                                     
                                                     //hide the loader view
                                                     //[HUD hideUIBlockingIndicator];
                                                     messageCountsDic = [[_feed toDictionary] objectForKey:@"conversations"];
                                                     
                                                     

                                                     [self.tableView reloadData];
                                                     NSLog(@"new dictionary inside block%@", messageCountsDic);
                                                     
                                               }];
//    //NSLog(@"new dictionary outside block%@", messageCountsDic);
//    if (messageCountsArr) {
//        
//        [messageCountsArr enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
//            //NSLog(@"%lu => %@", (unsigned long)idx, object);
//            [self.messageCountsDic setObject:object forKey:[NSString stringWithFormat:@"%lu-Key", (unsigned long)idx]];
//            //
//           
//        }];
//        NSLog(@"hur ser det ut? %@", messageCountsDic);
//        [messageCountsDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//           // [messageCountsDic addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
//        }];
//        
//        
//        for (id key in messageCountsDic) {
//            //[messageCountsDic addObserver:self forKeyPath:@"conversationid" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
//            //NSLog(@"There are %@ message(s) in %@", messageCountsDic[key], key);
//          [self.messageCountsDicCopy setObject:[messageCountsDic valueForKey:@"messagecount"] forKey:[NSString stringWithFormat:@"%@-Key", [messageCountsDic objectForKey:@"conversationid"]]];
//        }
//   
//    //NSLog(@"messageCountsDicCopy%@", messageCountsDicCopy);
//    }
//
// 
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadStandardUser {
    //NSUserDefaults *standardUserDefaults  = [NSUserDefaults standardUserDefaults];
    
    //username = [standardUserDefaults stringForKey:@"username"];
    username = [Lockbox stringForKey:@"username"];
    //realname = [standardUserDefaults stringForKey:@"realname"];
    realname = [Lockbox stringForKey:@"realname"];
    //sex = [standardUserDefaults stringForKey:@"sex"];
    sex = [Lockbox stringForKey:@"sex"];
    //membersince = [standardUserDefaults stringForKey:@"membersince"];
    membersince = [Lockbox stringForKey:@"membersince"];
    //presentation = [standardUserDefaults stringForKey:@"presentation"];
    presentation = [Lockbox stringForKey:@"presentation"];
    //avatarURL = [standardUserDefaults URLForKey:@"avatarURL"];
    avatarURL = [NSURL URLWithString:[Lockbox stringForKey:@"avatarURL"]];
}

-(void)setLProfileLabels
{
    
    usernameLabel.text = realname;
    sexLabel.text = sex;
    membersinceLabel.text = membersince;
    avatar.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:avatarURL]];
    avatar.layer.cornerRadius = 5.0;
    avatar.layer.masksToBounds = YES;
    avatar.layer.borderColor = [UIColor lightGrayColor].CGColor;
    avatar.layer.borderWidth = 1.0;
    presentationTextview.text = presentation;
    
}


- (IBAction)logOut:(UIBarButtonItem *)sender {
    [HUD showUIBlockingIndicatorWithText:@"Logging out..."];
    
    [Lockbox setString:@"" forKey:@"username"];
    [Lockbox setString:@"" forKey:@"realname"];
    [Lockbox setString:@"" forKey:@"sex"];
    [Lockbox setString:@"" forKey:@"membersince"];
    [Lockbox setString:@"" forKey:@"presentation"];
    [Lockbox setString:@"" forKey:@"avatarURL"];
    
    [NSThread sleepForTimeInterval:0.5];
    
    [HUD hideUIBlockingIndicator];
    [self performSegueWithIdentifier:@"start" sender:self];
    
    
}




#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _feed.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ConversationsModel* conversation = _feed.conversations[indexPath.row];
    static NSString *identifier = @"ConversationCell";
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    // Here we use the new provided setImageWithURL: method to load the web image
    
    [cell.imageView setImageWithURL:conversation.avatar
                   placeholderImage:[UIImage imageNamed:@"missingAvatar"]];
    
    cell.textLabel.text = conversation.title;
    
    if ([conversation.conversationflag intValue] == 0 | [conversation.conversationflag intValue] == 2) {
        // Red dot to be displayed for new messages
        
        UIImage     * thumbs;
        UIImageView * thumbsView;
        CGFloat       width;
        
        thumbs             = [UIImage imageNamed:@"red_dot_small.png"];
        thumbsView         = [[UIImageView alloc] initWithImage:thumbs] ;
        width              = (cell.frame.size.height * thumbs.size.width) / thumbs.size.height;
        thumbsView.frame   = CGRectMake(0, 0, 12, 12);
        cell.accessoryView = thumbsView;
        
        // Add a text notification as well?
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - new message", conversation.startedby ];
        localNotif.applicationIconBadgeNumber++;
        
    } else {
        
        
        
        
        
        cell.detailTextLabel.text = conversation.startedby;
    }
    
    //[self getMessageCountToArray:conversation.messagecount id:conversation.conversationid];
   
    return cell;
    
}
- (void)getMessageCountToArray:(NSNumber*)messagecount id:(NSString *)conversationid  {
    [self.messageCountsDic setObject:messagecount forKey:[NSString stringWithFormat:@"%@-Key", conversationid]];

//     [self.messageCountsDic  addObserver:self
//                          forKeyPath:[self.messageCountsDic allKeys]
//      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
    
    

    
       // Test kod
    
//    NSLog(@"We currently have %ld messeges", (unsigned long)[messageCountsDic count]);
//    for (id key in messageCountsDic) {
//        NSLog(@"There are %@ message(s) in %@", messageCountsDic[key], key);
//    }


    
    return;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"keyPath %@", keyPath);
    if (context == @"test")
    {
        id newValue = [object valueForKeyPath:keyPath];
        NSLog(@"The keyPath %@ changed to %@", keyPath, newValue);
    }
    else if ([keyPath rangeOfString:@"-Key"].location != NSNotFound)
    {
        id newValue = [change objectForKey:NSKeyValueChangeNewKey];
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        //NSLog(@"The keyPath %@ changed from %@ to %@", keyPath, oldValue, newValue);
        
        if (newValue != oldValue){
            
            //Notifications
            
            // Notification details
            localNotif.alertBody = @"There is a new messege for you";
            // Set the action button
            localNotif.alertAction = @"View";
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            localNotif.applicationIconBadgeNumber = 1;
            
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];

            NSLog(@"The keyPath %@ changed from %@ to %@", keyPath, oldValue, newValue);
            
        } else {
            
        // NSLog(@"No Change");
        }
    }
    else if ([object isEqual:messageCountsDic])
    {
        NSLog(@"Change!");
    }
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ConversationsModel* conversation = _feed.conversations[indexPath.row];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Here we are passing values to MessageVC. Can this be done in a better way?
    [MessagesViewController conversationIdMthd:conversation.conversationid];
    [MessagesViewController receiverIdMthd:conversation.sentto];
    [MessagesViewController senderAvatarMthd:conversation.avatar];
    [self performSegueWithIdentifier:@"getmessage" sender:self];
    
}

- (IBAction)newConversation: (UIButton *) sender{
    [self performSegueWithIdentifier:@"newConversation" sender:self];
    
}

- (IBAction)cancel {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)segmentDidChange:(id)sender
{
    if(segmentedControl.selectedSegmentIndex == 0){
		NSLog(@"1");
        [self.tableView setHidden:YES];
        conversatinbutton.hidden = YES;
        [self.profileView setHidden:NO];
	}
	if(segmentedControl.selectedSegmentIndex == 1){
        NSLog(@"2");
        [self.tableView setHidden:NO];
        conversatinbutton.hidden = NO;
        [self.profileView setHidden:YES];
	}
}


@end
