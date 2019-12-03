//
//  WebViewJavascriptBridgeBase.h
//  HybridJSBridge
//
//  Created by zzg on 2019/11/30.
//  Copyright © 2019 zzg. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^WVJBResponseCallback)(id responseData);
typedef void (^WVJBHandler)(id data, WVJBResponseCallback responseCallback);
typedef NSDictionary WVJBMessage;

@protocol WebViewJavascriptBridgeBaseDelegate <NSObject>
- (NSString*) _evaluateJavascript:(NSString*)javascriptCommand;
@end


@interface WebViewJavascriptBridgeBase : NSObject

@property (nonatomic, weak) id<WebViewJavascriptBridgeBaseDelegate>  delegate;

@property (strong, nonatomic) NSMutableArray* startupMessageQueue;
@property (strong, nonatomic) NSMutableDictionary* responseCallbacks;
@property (strong, nonatomic) NSMutableDictionary* messageHandlers;
@property (strong, nonatomic) WVJBHandler messageHandler;


+ (void)enableLogging;
+ (void)setLogMaxLength:(int)length;

- (BOOL)isWebViewJavascriptBridgeURL:(NSURL*)url;
- (BOOL)isSchemeMatch:(NSURL*)url;
- (BOOL)isQueueMessageURL:(NSURL*)url;
- (BOOL)isBridgeLoadedURL:(NSURL*)url;
- (void)injectJavascriptFile:(NSURL *)url;
- (void)logUnkownMessage:(NSURL*)url;

- (void)reset;

- (void)flushMessageQueue:(NSString *)messageQueueString;
- (NSString *)webViewJavascriptFetchQueyCommand;

- (void)sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName;
@end

NS_ASSUME_NONNULL_END
