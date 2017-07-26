//
//  LYMainThreadDetect.h
//  LYMainThreadDetect
//
//  Created by shangen zhang on 2016/10/8.
//  Copyright © 2016年 hhly. All rights reserved.
//

#import <Foundation/Foundation.h>

#define iOS_SCREEN_FPS 60

typedef void(^ly_stack_block)(NSArray <NSString *>*slow_stack);

/**
 开始检测 主线程耗时操作
        -- 必须在主线程中回调

 @param fps 刷新频率 （iOS的屏幕刷新平率为60帧）
 @param on_stack_detected 检测主线程 刷新频率低于设定值
 */
FOUNDATION_EXTERN void ly_start_detect_main_thread(unsigned int fps,ly_stack_block on_stack_detected);


/**
 结束检测
 */
FOUNDATION_EXTERN void ly_close_detect_main_thread(void);
