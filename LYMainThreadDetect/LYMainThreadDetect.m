//
//  LYMainThreadDetect.h
//  LYMainThreadDetect
//
//  Created by shangen zhang on 2016/10/8.
//  Copyright © 2016年 hhly. All rights reserved.
//


#import "LYMainThreadDetect.h"


#include <signal.h>
#include <pthread.h>

#include <libkern/OSAtomic.h>
#include <execinfo.h>

#define CALLSTACK_SIG SIGUSR1

static pthread_t                         _main_thread_ID;
static dispatch_source_t                 _ping_timer;
static dispatch_source_t                 _pong_timer;
static ly_stack_block                    _on_stack_detected;


// 创建子线程 GCD定时器 source 源（repeat forever）
static dispatch_source_t create_GCD_subthread_timer(uint64_t interval,dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    
    if (timer) {
        // 设置定时处理
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, interval), interval, interval / 10000);
        // 设置定时处理block 回调
        dispatch_source_set_event_handler(timer, block);
        // 开启source源定时器
        dispatch_resume(timer);
    }
    return timer;
}



// block 信号回调函数
static void thread_singal_handler(int sig)
{
    NSLog(@"main thread catch signal: %d", sig);
    
    if (sig != CALLSTACK_SIG) {
        return;
    }
    
    NSArray* callStack = [NSThread callStackSymbols];
    // blcok 回调
    if (_on_stack_detected) {
        // block回调
        _on_stack_detected(callStack);
    }else {
        NSLog(@"detect slow call stack on main thread! \n");
        for (NSString* call in callStack) {
            NSLog(@"%@\n", call);
        }
    }
    
    return;
}

// 初始化 回调 设置
static void install_signal_handler(ly_stack_block on_stack_detected)
{
    // 获取当前线程ID
    _main_thread_ID = pthread_self();
    // 回调注册
    _on_stack_detected = on_stack_detected;
    // 回调
    signal(CALLSTACK_SIG, thread_singal_handler);
}


// 销毁响应定时器
static void cancel_pong_timer()
{
    if (_pong_timer) {
        dispatch_source_cancel(_pong_timer);
        _pong_timer = nil;
    }
}
// 销毁请求定时器
static void cancel_ping_timer()
{
    if (_ping_timer) {
        dispatch_source_cancel(_ping_timer);
        _ping_timer = nil;
    }
}

// 回调超时了  杀死主线程
static void on_pong_timeout()
{
    // 结束定时器
    cancel_pong_timer();
    NSLog(@"sending signal(%d) timeout to main thread", CALLSTACK_SIG);
    // 停止主线程工作
    pthread_kill(_main_thread_ID, CALLSTACK_SIG);
}


// 子线程中 开启一个定时器 并加入主线程中销毁  若加入主线程的
static void ping_main_thread(uint64_t interval)
{
    // 子线程中开启 回应定时器  有回应即改定时器没有被销毁
    _pong_timer  = create_GCD_subthread_timer(interval, ^{
        // 定时器没被销毁  就会执行 （响应超时）
         on_pong_timeout();
    });
    
    // 加入到主队列 移除定时器
    dispatch_async(dispatch_get_main_queue(), ^{
        // 超时之前 响应
        cancel_pong_timer();
    });
}

// 关闭主线程检测
void ly_close_detect_main_thread(void) {
    cancel_pong_timer();
    cancel_ping_timer();
    _main_thread_ID = NULL;
    _on_stack_detected = nil;
}

// 开启主线程检测
void ly_start_detect_main_thread(unsigned int fps,ly_stack_block on_stack_detected) {
    // 非主线程校验
    if ([NSThread isMainThread] == false) {
        NSLog(@"Error: start detect must be called from main thread!");
        return;
    }
    
    // 关闭定时器
    ly_close_detect_main_thread();
    
    // 注册回调
    install_signal_handler(on_stack_detected);
    
    // 根据FPS 获取 GCD 时间差
    uint64_t interval = (1.0f / fps) * NSEC_PER_SEC;
    
    // 开启子线程 开始 PIN 主线程
    _ping_timer = create_GCD_subthread_timer(interval, ^{
        // PIN
        ping_main_thread(interval);
    });
}
