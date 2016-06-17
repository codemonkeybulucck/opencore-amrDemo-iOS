//
//  ViewController.m
//  -01VoiceForAMR
//
//  Created by 势必可赢 on 16/6/16.
//  Copyright © 2016年 势必可赢. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"首页";
    self.button1.layer.cornerRadius = 10;
    self.button2.layer.cornerRadius = 10;
    self.button1.layer.masksToBounds = YES;
    self.button2.layer.masksToBounds  = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
