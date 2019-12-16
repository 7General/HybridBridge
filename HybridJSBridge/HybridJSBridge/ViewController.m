//
//  ViewController.m
//  HybridJSBridge
//
//  Created by zzg on 2019/11/30.
//  Copyright © 2019 zzg. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "WKWebViewJavascriptBridge.h"



typedef void (^WWJBResponseCallback)(id responseData);
typedef void (^WWJBHandler)(id data, WWJBResponseCallback responseCallback);
@interface ViewController ()<WKNavigationDelegate,WKUIDelegate>

@property (nonatomic, strong)WKWebView  * webView;
@property (nonatomic, strong) WKWebViewConfiguration * webConfig;
@property (nonatomic, strong) WKWebViewJavascriptBridge * bridge;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 设置webConfig
    self.webConfig = [[WKWebViewConfiguration alloc] init];
    // 设置偏好设置
    _webConfig.preferences = [[WKPreferences alloc] init];
    // 默认为0
    _webConfig.preferences.minimumFontSize = 10;
    // 默认认为YES
    _webConfig.preferences.javaScriptEnabled = YES;
    // 在iOS上默认为NO，表示不能自动通过窗口打开
    _webConfig.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    
    // 初始化wkwebview
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:self.webConfig];
    if (@available(iOS 9.0, *)) {
        self.webView.customUserAgent = [NSString stringWithFormat:@"%@app",self.webView.customUserAgent];
    } else {
        // Fallback on earlier versions
    }
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSURL *baseUrl = [NSURL fileURLWithPath:bundlePath isDirectory:YES];
    NSString * path = [[NSBundle mainBundle] pathForResource:@"bridge.html" ofType:nil];
    NSString *indexContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    [self.webView loadHTMLString:indexContent baseURL:baseUrl];
    
    
    [WKWebViewJavascriptBridge enableLogging];
    self.bridge = [WKWebViewJavascriptBridge bridgeForWebView:self.webView];
    

    
    UIButton *occalljs = [UIButton buttonWithType:UIButtonTypeCustom];
    occalljs.frame = CGRectMake(0, 200, 200, 50);
    occalljs.backgroundColor = [UIColor grayColor];
    [occalljs setTitle:@"oc call js 无回调-无参数" forState:UIControlStateNormal];
    [occalljs addTarget:self action:@selector(ocCallJs) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:occalljs];
    
    UIButton *occalljsData = [UIButton buttonWithType:UIButtonTypeCustom];
    occalljsData.frame = CGRectMake(0, 260, 200, 50);
    occalljsData.backgroundColor = [UIColor grayColor];
    [occalljsData setTitle:@"oc call js 无回调-有参数" forState:UIControlStateNormal];
    [occalljsData addTarget:self action:@selector(occalljsData) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:occalljsData];
    
    UIButton *occalljsPar = [UIButton buttonWithType:UIButtonTypeCustom];
    occalljsPar.frame = CGRectMake(0, 320, 200, 50);
    occalljsPar.backgroundColor = [UIColor grayColor];
    [occalljsPar setTitle:@"oc call js 有参数-有回调" forState:UIControlStateNormal];
    [occalljsPar addTarget:self action:@selector(ocCallJspars) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:occalljsPar];
    
    
    
    
    [self.bridge registerHandler:@"reloadUrl" handler:^(id  _Nonnull data, WVJBResponseCallback  _Nonnull responseCallback) {
        NSLog(@"------------WVJBResponseCallback：%@---WVJBResponseCallback",data);
        responseCallback(@"发送你回调数据responsCallBack");
    }];

    [self.bridge registerHandler:@"reloadTest" handler:^(id  _Nonnull data, WVJBResponseCallback  _Nonnull responseCallback) {
        NSLog(@"------------WVJBResponseCallback：%@---WVJBResponseCallback",data);
        responseCallback(@"reloadTest:发送你回调数据responsCallBack");
    }];
    
    
    [self.bridge registerHandler:@"reloadTesttest" handler:^(id  _Nonnull data, WVJBResponseCallback  _Nonnull responseCallback) {
        NSLog(@"reloadTesttests------------WVJBResponseCallback：%@---WVJBResponseCallback",data);
    }];
    
    // 1:
    // 2:
    // 3:
    // 4:

    // 5:
    // 6:
    // 7 :
    
    
    // 11:
    // 12:
    // 13:
    // 14:
    // 5:

    // 6:
    // 7 :

    
//    WWJBResponseCallback wwResponseCallBack = ^(NSString * data){
//        NSLog(@"-----执行了wwResponseCallBack");
//    };
//
//    WWJBHandler wwHandler = ^(NSString * data,WWJBResponseCallback callBacck) {
//        NSLog(@"----:%@",data);
//    };
//
//
//    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
//    dict[@"ver"] = wwHandler;
//
//    WWJBHandler handler = dict[@"ver"];
//    handler(@"123456",wwResponseCallBack);
    

    
    
    
    
}

- (void)ocCallJs {
    [self.bridge callHandler:@"changeNameNull"];
}

- (void)occalljsData {
    NSString * jsonStr = @"{\"name\":\"张三\",\"sex\":\"男\"}";
    [self.bridge callHandler:@"changeNameArgument" data:jsonStr];
}

- (void)ocCallJspars {
    [self.bridge callHandler:@"changeName" data:@"123" responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"====回调数据-%@",responseData);
    }];
}


@end
