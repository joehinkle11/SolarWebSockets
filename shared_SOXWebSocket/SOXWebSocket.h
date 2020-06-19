//
//  SOXWebSocket.h
//
//  Copyright (c) 2014 Malcolm Jarvis (github.com/mjarvis). All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SOXWebSocketState)
{
    SOXWebSocketStateConnecting = 0,
    SOXWebSocketStateOpen = 1,
    SOXWebSocketStateClosing = 2,
    SOXWebSocketStateClosed = 3
};

typedef NS_ENUM(NSUInteger, SOXWebSocketStatusCode)
{
    SOXWebSocketStatusCodeNormalClosure = 1000,
    SOXWebSocketStatusCodeGoingAway = 1001,
    SOXWebSocketStatusCodeProtocolError = 1002,
    SOXWebSocketStatusCodeUnsupportedData = 1003,
    SOXWebSocketStatusCodeNoStatusReceived = 1005,
    SOXWebSocketStatusCodeAbnormalClosure = 1006,
    SOXWebSocketStatusCodeInvalidFramePayloadData = 1007,
    SOXWebSocketStatusCodePolicyViolation = 1008,
    SOXWebSocketStatusCodeMessageTooBig = 1009,
    SOXWebSocketStatusCodeMandatoryExtension = 1010,
    SOXWebSocketStatusCodeInternalServerError = 1011,
    SOXWebSocketStatusCodeTLSHandshake = 1015
};

@class SOXWebSocket;

@protocol SOXWebSocketDelegate <NSObject>

- (void)webSocket:(SOXWebSocket *)webSocket
didReceiveMessage:(id)message;

@optional

- (void)webSocketDidOpen:(SOXWebSocket *)webSocket;

- (void)webSocket:(SOXWebSocket *)webSocket
 didCloseWithCode:(NSUInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean;

- (void)webSocket:(SOXWebSocket *)webSocket
 didFailWithError:(NSError *)error;

@end

@interface SOXWebSocket : NSObject

- (id)initWithURLRequest:(NSURLRequest *)request;

@property (nonatomic, readonly) NSURL *url;
@property (atomic, readonly) SOXWebSocketState state;

- (void)send:(id)data;

- (void)closeWithCode:(NSUInteger)code
               reason:(NSString *)reason;

@property (nonatomic, weak) id <SOXWebSocketDelegate> delegate;
@property (nonatomic, weak) id delegateQueue;

@end
