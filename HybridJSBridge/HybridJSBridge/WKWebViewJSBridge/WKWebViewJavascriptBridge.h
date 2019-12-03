//
//  WKWebViewJavascriptBridge.h
//  HybridJSBridge
//
//  Created by zzg on 2019/11/30.
//  Copyright © 2019 zzg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "WebViewJavascriptBridgeBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKWebViewJavascriptBridge : NSObject<WKNavigationDelegate,WebViewJavascriptBridgeBaseDelegate>

+ (instancetype)bridgeForWebView:(WKWebView*)webView;
+ (void)enableLogging;


- (void)registerHandler:(NSString*)handlerName handler:(WVJBHandler)handler;
- (void)callHandler:(NSString*)handlerName;
- (void)callHandler:(NSString*)handlerName data:(id)data;
- (void)callHandler:(NSString*)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback;


- (void)setWebViewDelegate:(id)webViewDelegate;

@end

NS_ASSUME_NONNULL_END
