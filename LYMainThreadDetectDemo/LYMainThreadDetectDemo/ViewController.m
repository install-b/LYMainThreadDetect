//
//  ViewController.m
//  LYMainThreadDetectDemo
//
//  Created by Shangen Zhang on 2017/7/26.
//  Copyright © 2017年 Shangen Zhang. All rights reserved.
//

#import "ViewController.h"
#import "LYMainThreadDetect.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 开启主线程监测
    ly_start_detect_main_thread(iOS_SCREEN_FPS, nil);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // 打印一千次
    [self printLongLogsWithTimes:1000];
    //ly_close_detect_main_thread();
}

- (void)printLongLogsWithTimes:(NSInteger)times {
    for (NSInteger i = 0; i < times; i++) {
        NSLog(@"\n耗时打印:%zd",i);
    }
}

@end
