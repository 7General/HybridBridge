//
//  MsgObject.h
//  Hybrid Bridge
//
//  Created by zzg on 2019/7/11.
//  Copyright © 2019 zzg. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MsgObject;

//@protocol MsgObjectDelegate <NSObject>
//
//@optional
//- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;
//
//@end


typedef void(^HandlerBlock)(MsgObject * msg);

typedef void (^JSResponseCallback)(NSDictionary* responseData);

@interface MsgObject : NSObject

@property (nonatomic, copy, readonly) NSString * handler;
@property (nonatomic, copy, readonly) NSString * action;
@property (nonatomic, copy, readonly) NSDictionary * paramters;
@property (nonatomic, copy, readonly) NSString * callbackID;
@property (nonatomic, copy, readonly) NSString * callbackFunction;

@property (nonatomic, weak)  WKWebView* weakWKWebView;

@property (nonatomic, strong, readonly) NSMutableDictionary * handlerMap;

@property (nonatomic, copy) HandlerBlock HandlerBlock;

- (void)setCallback:(JSResponseCallback)callback; //block 作为属性，保存在msgObject的.m文件里
-(void)callback:(NSDictionary *)result;//在msgObject的.m文件里 调用保存在消息体里的block

- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (void)registerHandler:(NSString *)handlerName Action:(NSString *)actionName handler:(HandlerBlock)handler;
- (void)sendEventName:(NSString *)event withParams:(NSDictionary *)params withCallback:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))handler;


- (void)userContentControllerDidReceiveScriptMessage:(MsgObject *)message;

@end

NS_ASSUME_NONNULL_END
