//
//  ViewController.h
//  JKRWechatPayDemo
//
//  Created by tronsis_ios on 16/8/29.
//  Copyright © 2016年 tronsis_ios. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import "DataMD5.h"
#import "XMLDictionary.h"

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

#define WX_APPID @"wx40xxxxxxxxxxxxxx"
#define WX_APPSecret @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
#define MCH_ID @"13xxxxxxxxx"
#define WX_PartnerKey @"nXXXXX2XXXXXXXXXXXXXXXXXXXXXXXX"

#define TRADE_TYPE @"APP"
#define NOTIFY_URL @"http://wxpay.weixin.qq.com/pub_v2/pay/notify.v2.php"
#define PRICE @"1"

#define WXAPPID @"appid"                                                    // 应用id
#define WXMCHID @"mch_id"                                                   // 商户号
#define WXNONCESTR @"nonce_str"                                             // 随机字符串
#define WXSIGN @"sign"                                                      // 签名
#define WXBODY @"body"                                                      // 商品描述
#define WXOUTTRADENO @"out_trade_no"                                        // 商户订单号
#define WXTOTALFEE @"total_fee"                                             // 总金额
#define WXEQUIPMENTIP @"spbill_create_ip"                                   // 终端IP
#define WXNOTIFYURL @"notify_url"                                           // 通知地址
#define WXTRADETYPE @"trade_type"                                           // 交易类型
#define WXPREPAYID @"prepay_id"                                             // 预支付交易会话
#define WXUNIFIEDORDERURL @"https://api.mch.weixin.qq.com/pay/unifiedorder" // 微信统一下单接口连接

@interface ViewController : UIViewController


@end

