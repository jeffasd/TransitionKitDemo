//
//  ViewController.m
//  StateMachineDemo
//
//  Created by zhangchaojie on 15/8/29.
//  Copyright (c) 2015年 zcj. All rights reserved.
//

#import "ViewController.h"
#import "TKState.h"
#import "TKStateMachine.h"
#import "TKEvent.h"


//发射火箭的有三种状态，待机、计时、发射
static const NSString *coundDownStart = @"coundDownStart";
static const NSString *resumeStandby = @"resumeStandby";
static const NSString *launch = @"launch";

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *rocketView;
@property (weak, nonatomic) IBOutlet UILabel *countDownLbl;
@property (weak, nonatomic) IBOutlet UIButton *fireBtn;
@property (weak, nonatomic) IBOutlet UIButton *abortBtn;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rocketViewButtomSpaceConstraint;

@property (nonatomic,strong) TKStateMachine *stateMachine;
@property (nonatomic,strong) NSTimer *launchReadyTimer;
@property (nonatomic) NSInteger count;
@end

@implementation ViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupStateMachine];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setupStateMachine {
    _stateMachine = [[TKStateMachine alloc] init];
    
    //create some state
    TKState *standbyState = [TKState stateWithName:@"Standby"];
    TKState *countDownState = [TKState stateWithName:@"CountDown"];
    TKState *launchState = [TKState stateWithName:@"Launch"];
    
    //set the action of the state
    [standbyState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        self.countDownLbl.text = @"Standby";
        self.fireBtn.enabled = YES;
        self.abortBtn.enabled = NO;
        
        if (self.launchReadyTimer)
        {
            [self.launchReadyTimer invalidate];
            self.launchReadyTimer = nil;
        }
        
        self.rocketViewButtomSpaceConstraint.constant = 0;
    }];
    [countDownState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        self.fireBtn.enabled = NO;
        self.abortBtn.enabled = YES;
        
        self.count = 5;
        self.launchReadyTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countDownToFire:) userInfo:nil repeats:YES];
    }];
    [launchState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        if (self.launchReadyTimer)
        {
            [self.launchReadyTimer invalidate];
            self.launchReadyTimer = nil;
        }
        
        self.countDownLbl.text = @"Launch";
        self.fireBtn.enabled = NO;
        self.abortBtn.enabled = NO;
        
        [UIView beginAnimations:@"RocketLaunch" context:nil];
        [UIView setAnimationDuration:3];
        
        self.rocketViewButtomSpaceConstraint.constant = self.view.bounds.size.height;
        [self.view layoutIfNeeded];
        
        [UIView commitAnimations];
    }];
    
    [_stateMachine addStates:@[standbyState, countDownState,launchState]];
    [_stateMachine isInState:@"Standby"];
    
    //add some path which state to state
    TKEvent *countDownEvent = [TKEvent eventWithName:@"coundDownStart" transitioningFromStates:@[standbyState] toState:countDownState];
    TKEvent *standbyEvent = [TKEvent eventWithName:@"resumeStandby" transitioningFromStates:@[countDownState,launchState] toState:standbyState];
    TKEvent *launchEvent = [TKEvent eventWithName:@"launch" transitioningFromStates:@[countDownState] toState:launchState];
    
    [_stateMachine addEvents:@[countDownEvent,standbyEvent,launchEvent]];
    
    // Activate the state machine
    [_stateMachine activate];
}

#pragma mark - event response
// Fire some events
- (IBAction)fire:(id)sender
{
    [_stateMachine fireEvent:coundDownStart userInfo:nil error:nil];
}

- (IBAction)abort:(id)sender
{
    [_stateMachine fireEvent:resumeStandby userInfo:nil error:nil];
}

- (IBAction)refresh:(id)sender
{
    [_stateMachine fireEvent:resumeStandby userInfo:nil error:nil];
}

-(void)countDownToFire:(NSTimer *)timer
{
    self.count--;
    if (self.count == 0)
    {
        [self.launchReadyTimer invalidate];
        self.launchReadyTimer = nil;
        
        [_stateMachine fireEvent:launch userInfo:nil error:nil];
    }
}

#pragma mark - getters and setters
-(void)setCount:(NSInteger)count
{
    _count = count;
    self.countDownLbl.text = [NSString stringWithFormat:@"%ld", (long)_count];
}
@end
