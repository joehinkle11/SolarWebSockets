//
//  SOXWebSocket.m
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

#import <Endian.h>
#import <CommonCrypto/CommonDigest.h>
#import "SOXWebSocket.h"

CF_INLINE CFStringRef SecWebSocketAccept(NSString *key)
{
    NSData *data = [[[NSString alloc] initWithFormat:@"%@258EAFA5-E914-47DA-95CA-C5AB0DC85B11", key] dataUsingEncoding:NSASCIIStringEncoding];

    uint8_t buffer[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([data bytes], (CC_LONG)[data length], buffer);

    data = [[NSData alloc] initWithBytes:buffer
                                  length:CC_SHA1_DIGEST_LENGTH];

    return (__bridge CFStringRef)([data base64EncodedStringWithOptions:0]);
}

typedef NS_ENUM(NSUInteger, SOXWebSocketOpCode)
{
    SOXWebSocketOpCodeContinuationFrame = 0x0,
    SOXWebSocketOpCodeTextFrame = 0x1,
    SOXWebSocketOpCodeBinaryFrame = 0x2,
    SOXWebSocketOpCodeConnectionCloseFrame = 0x8,
    SOXWebSocketOpCodePingFrame = 0x9,
    SOXWebSocketOpCodePongFrame = 0xA
};

@interface SOXWebSocket ()
{
    CFWriteStreamRef _writeStream;
    CFMutableDataRef _writeBuffer;
    dispatch_queue_t _writeQueue;

    CFReadStreamRef  _readStream;
    CFMutableDataRef _readBuffer;
    dispatch_queue_t _readQueue;

    CFMutableDataRef   _frameBuffer;
    SOXWebSocketOpCode _frameOpCode;

    uint64_t _readBufferOffset;
    uint64_t _writeBufferOffset;
}

@property (nonatomic, strong) NSURLRequest *URLRequest;
@property (atomic, assign) SOXWebSocketState state;

- (void)dispatch:(void (^)(void))block;

- (void)send:(SOXWebSocketOpCode)opCode
     payload:(uint8_t *)payload
      length:(uint64_t)length;

- (void)write;
- (void)read;

@end

static void SOXStreamClientCallBack(void *stream, CFStreamEventType event, SOXWebSocket *webSocket)
{
    switch (event)
    {
        case kCFStreamEventHasBytesAvailable:
        {
            [webSocket read];
        }
        break;

        case kCFStreamEventCanAcceptBytes:
        {
            [webSocket write];
        }
        break;

        case kCFStreamEventErrorOccurred:
        {
            // ...
        }
        break;

        case kCFStreamEventEndEncountered:
        {
            // ...
        }
        break;

        default:
            break;
    }
}

@implementation SOXWebSocket
{
    NSString *_key;
}

- (void)dealloc
{
    CFRelease(_writeStream);
    CFRelease(_writeBuffer);

    CFRelease(_readStream);
    CFRelease(_readBuffer);

    if (_frameBuffer)
        CFRelease(_frameBuffer);
}

- (id)initWithURLRequest:(NSURLRequest *)request
{
    NSURL *url = request.URL;
    NSAssert([url scheme] && [url host] && [url fragment] == nil && ([[url scheme] isEqualToString:@"ws"] || [[url scheme] isEqualToString:@"wss"]),
             @"websocket url must be in format: \"ws[s]:\" \"//\" host [ \":\" port ] path [ \"?\" query ]");

    if ((self = [super init]))
    {
        _URLRequest = request;

        @autoreleasepool
        {
            NSNumber *port = [url port] ?: ([[url scheme] isEqualToString:@"wss"] ? @443 : @80);
            CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)([url host]), [port unsignedIntValue], &_readStream, &_writeStream);

            CFStreamClientContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
            CFOptionFlags flags = kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered;

            _readBuffer = CFDataCreateMutable(NULL, 0);
            _readQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);

            CFReadStreamSetDispatchQueue(_readStream, _readQueue);
            CFReadStreamSetClient(_readStream, flags | kCFStreamEventHasBytesAvailable, (CFReadStreamClientCallBack)&SOXStreamClientCallBack, &context);

            _writeBuffer = CFDataCreateMutable(NULL, 0);
            _writeQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);

            CFWriteStreamSetDispatchQueue(_writeStream, _writeQueue);
            CFWriteStreamSetClient(_writeStream, flags | kCFStreamEventCanAcceptBytes, (CFWriteStreamClientCallBack)&SOXStreamClientCallBack, &context);

            CFHTTPMessageRef message = CFHTTPMessageCreateRequest(NULL, CFSTR("GET"), (__bridge CFURLRef)(url), kCFHTTPVersion1_1);

            NSString *host = [url port] ? [[NSString alloc] initWithFormat:@"%@:%u", [url host], [[url port] unsignedIntValue]] : [url host];
            CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Host"), (__bridge CFStringRef)(host));

            CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Upgrade"), CFSTR("websocket"));
            CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Connection"), CFSTR("Upgrade"));

            NSMutableData *buffer = [[NSMutableData alloc] initWithLength:16];
            SecRandomCopyBytes(kSecRandomDefault, [buffer length], [buffer mutableBytes]);

            _key = [buffer base64EncodedStringWithOptions:0];

            CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Sec-WebSocket-Key"), (__bridge CFStringRef)(_key));
            CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Sec-WebSocket-Version"), CFSTR("13"));

            [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {

                CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)(key), (__bridge CFStringRef)(value));
            }];

            CFDataRef data = CFHTTPMessageCopySerializedMessage(message);
            CFRelease(message);
            
            CFDataAppendBytes(_writeBuffer, CFDataGetBytePtr(data), CFDataGetLength(data));
            CFRelease(data);
            
            CFReadStreamOpen(_readStream), CFWriteStreamOpen(_writeStream);
        }
    }

    return self;
}

- (void)send:(id)data
{
    SOXWebSocketOpCode opCode = SOXWebSocketOpCodeBinaryFrame;

    if ([data isKindOfClass:[NSString class]])
    {
        opCode = SOXWebSocketOpCodeTextFrame;
        data = [(NSString *)data dataUsingEncoding:NSUTF8StringEncoding];
    }

    NSAssert(data && [data isKindOfClass:[NSData class]],
             @"websocket data must be NSString (UTF-8) or NSData");

    [self send:opCode
       payload:(uint8_t *)[data bytes]
        length:[data length]];
}

- (void)closeWithCode:(NSUInteger)code
               reason:(NSString *)reason
{
    if (self.state == SOXWebSocketStateConnecting || self.state == SOXWebSocketStateOpen)
    {
        if (self.state == SOXWebSocketStateOpen)
        {
            uint8_t payload[sizeof(uint16_t)];
            *((uint16_t *)payload) = EndianU16_BtoN(code);

            [self send:SOXWebSocketOpCodeConnectionCloseFrame
               payload:payload
                length:sizeof(uint16_t)];
        }

        self.state = SOXWebSocketStateClosing;

        [self dispatch:^{

            dispatch_group_t group = dispatch_group_create();

            dispatch_group_enter(group);
            dispatch_async(_readQueue, ^{

                CFReadStreamSetDispatchQueue(_readStream, NULL);
                CFReadStreamSetClient(_readStream, 0, NULL, NULL);
                CFReadStreamClose(_readStream);

                dispatch_group_leave(group);
            });

            dispatch_group_enter(group);
            dispatch_async(_writeQueue, ^{

                CFWriteStreamSetDispatchQueue(_writeStream, NULL);
                CFWriteStreamSetClient(_writeStream, 0, NULL, NULL);
                CFWriteStreamClose(_writeStream);
                
                dispatch_group_leave(group);
            });
            
            dispatch_group_notify(group, self.delegateQueue, ^{
                
                self.state = SOXWebSocketStateClosed;

                if ([self.delegate respondsToSelector:@selector(webSocket:didCloseWithCode:reason:wasClean:)])
                {
                    [self.delegate webSocket:self
                            didCloseWithCode:SOXWebSocketStatusCodeNormalClosure
                                      reason:nil
                                    wasClean:YES];
                }
            });
        }];
    }
}

- (void)setDelegateQueue:(id)delegateQueue
{
    NSAssert([delegateQueue isKindOfClass:[NSOperationQueue class]] || [delegateQueue isKindOfClass:NSClassFromString(@"OS_dispatch_queue")],
             @"websocket delegate queue must NSOperationQueue or dispatch_queue_t");

    _delegateQueue = delegateQueue;
}

- (void)dispatch:(void (^)(void))block
{
    NSAssert(self.delegate && self.delegateQueue,
             @"websocket requires a delegate and a queue");

    if ([self.delegateQueue isKindOfClass:[NSOperationQueue class]])
    {
        [self.delegateQueue addOperationWithBlock:block];
    }
    else
    {
        dispatch_async(self.delegateQueue, block);
    }
}

- (void)send:(SOXWebSocketOpCode)opCode
     payload:(uint8_t *)payload
      length:(uint64_t)length
{
    uint8_t *frame = (uint8_t *)malloc(sizeof(uint8_t) * (size_t)((2 + sizeof(uint64_t) + sizeof(uint32_t)) + length));

    frame[0] = 0x80 | opCode;
    frame[1] = 0x80;

    uint8_t header = 2;

    if (length < 126)
    {
        frame[1] |= length;
    }
    else
    {
        if (length <= UINT16_MAX)
        {
            *((uint16_t *)(frame + header)) = EndianU16_BtoN((uint16_t)length);

            frame[1] |= 126;
            header += sizeof(uint16_t);
        }
        else
        {
            *((uint64_t *)(frame + header)) = EndianU64_BtoN(length);

            frame[1] |= 127;
            header += sizeof(uint64_t);
        }
    }

    uint8_t *mask = &frame[header];
    SecRandomCopyBytes(kSecRandomDefault, 4, mask);

    header += 4;

    for (uint64_t index = 0; index < length; index++)
    {
        frame[header + index] = payload[index] ^ mask[index % 4];
    }

    dispatch_async(_writeQueue, ^{

        CFDataAppendBytes(_writeBuffer, frame, (CFIndex)(header + length));
        free(frame);

        [self write];
    });
}

- (void)write
{
    while (CFWriteStreamCanAcceptBytes(_writeStream) && (CFDataGetLength(_writeBuffer) - _writeBufferOffset) > 0)
    {
        CFIndex numberOfBytesWritten = CFWriteStreamWrite(_writeStream, (const UInt8 *)(CFDataGetBytePtr(_writeBuffer) + _writeBufferOffset), CFDataGetLength(_writeBuffer) - (CFIndex)_writeBufferOffset);
        if (numberOfBytesWritten > 0)
        {
            _writeBufferOffset += numberOfBytesWritten;

            if (_writeBufferOffset > 65536)
            {
                CFDataDeleteBytes(_writeBuffer, CFRangeMake(0, (CFIndex)_writeBufferOffset));
                _writeBufferOffset = 0;
            }
        }
    }
}

- (void)read
{
    while (CFReadStreamHasBytesAvailable(_readStream))
    {
        uint8_t buffer[1024];

        CFIndex numberOfBytesRead = CFReadStreamRead(_readStream, buffer, 1024);
        if (numberOfBytesRead > 0)
        {
            CFDataAppendBytes(_readBuffer, buffer, numberOfBytesRead);
        }
    }

    if (self.state == SOXWebSocketStateConnecting)
    {
        const uint8_t *bytes = CFDataGetBytePtr(_readBuffer);

        CFIndex index = CFDataGetLength(_readBuffer) - 1;
        while (index >= 4)
        {
            if (bytes[index] == '\n' && (index - 3) >= 0 && bytes[index - 1] == '\r' && bytes[index - 2] == '\n' && bytes[index - 3] == '\r')
            {
                index += 1;
                break;
            }

            index--;
        }

        /*
            If we never received a properly formatted HTTP response,
            the websocket will forever be in a connecting state...
         */

        if (index == -1)
            return;

        CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(NULL, FALSE);
        CFHTTPMessageAppendBytes(message, bytes, index);

        _readBufferOffset += index;

        CFDictionaryRef headers = CFHTTPMessageCopyAllHeaderFields(message);

        BOOL success = CFHTTPMessageGetResponseStatusCode(message) == 101
            && CFStringCompare(CFDictionaryGetValue(headers, CFSTR("Upgrade")), CFSTR("websocket"), kCFCompareCaseInsensitive) == 0
            && CFStringCompare(CFDictionaryGetValue(headers, CFSTR("Connection")), CFSTR("upgrade"), kCFCompareCaseInsensitive) == 0
            && CFStringCompare(CFDictionaryGetValue(headers, CFSTR("Sec-WebSocket-Accept")), SecWebSocketAccept(_key), kCFCompareCaseInsensitive) == 0;

        CFRelease(headers), CFRelease(message);

        if (success)
        {
            self.state = SOXWebSocketStateOpen;

            [self dispatch:^{

                if ([self.delegate respondsToSelector:@selector(webSocketDidOpen:)])
                {
                    [self.delegate webSocketDidOpen:self];
                }
            }];
        }
    }

    if (self.state == SOXWebSocketStateOpen)
    {
        while ((CFDataGetLength(_readBuffer) - _readBufferOffset) >= 2)
        {
            uint8_t *frame = (uint8_t *)(CFDataGetBytePtr(_readBuffer) + _readBufferOffset);

            uint64_t length = 0x7F & frame[1], header = 2;
            if (length == 126)
            {
                length = EndianU16_BtoN(*((uint16_t *)(frame + header)));
                header += sizeof(uint16_t);
            }
            else if (length == 127)
            {
                length = EndianU64_BtoN(*((uint64_t *)(frame + header)));
                header += sizeof(uint64_t);
            }

            if (length > 0 && (CFDataGetLength(_readBuffer) - _readBufferOffset) < (header + length))
                break;

            SOXWebSocketOpCode opCode = 0x0F & frame[0];

            if (((opCode & 0x8) && (length > 125 || (0x80 & frame[0]) == 0))
                || (opCode == SOXWebSocketOpCodeContinuationFrame && _frameBuffer == NULL)
                || (((opCode == SOXWebSocketOpCodeBinaryFrame || opCode == SOXWebSocketOpCodeTextFrame) && (0x80 & frame[0]) == 0x80) && _frameBuffer)
                || ((opCode > 0x2 && opCode < 0x8) || opCode > 0xA)
                || (0x70 & frame[0]))
            {
                [self dispatch:^{

                    [self closeWithCode:SOXWebSocketStatusCodeProtocolError
                                 reason:nil];
                }];

                return;
            }

            if (opCode & 0x8)
            {
                switch (opCode)
                {
                    case SOXWebSocketOpCodeConnectionCloseFrame:
                    {
                        NSUInteger code = SOXWebSocketStatusCodeNormalClosure;
                        if (length == 1)
                        {
                            code = SOXWebSocketStatusCodeProtocolError;
                        }
                        else if (length >= 2)
                        {
                            uint16_t *bytes = (uint16_t *)&frame[header];
                            code = EndianU16_BtoN(*bytes);

                            if (code < 1000 || (code >= 1004 && code <= 1006) || (code >= 1012 && code <= 1016) || code == 1100 || code == 2000 || code == 2999)
                            {
                                code = SOXWebSocketStatusCodeProtocolError;
                            }
                            else
                            {
                                NSString *string = [[NSString alloc] initWithBytesNoCopy:&frame[header + 2]
                                                                                  length:(NSUInteger)(length - 2)
                                                                                encoding:NSUTF8StringEncoding
                                                                            freeWhenDone:NO];
                                if (string == nil)
                                {
                                    code = SOXWebSocketStatusCodeInvalidFramePayloadData;
                                }
                            }
                        }

                        [self dispatch:^{

                            [self closeWithCode:code
                                         reason:nil];
                        }];
                    }
                        break;

                    case SOXWebSocketOpCodePingFrame:
                    {
                        uint8_t *buffer = NULL;

                        if (length > 0)
                        {
                            buffer = malloc(sizeof(uint8_t) * (size_t)length);
                            memcpy(buffer, &frame[header], (size_t)length);
                        }

                        [self dispatch:^{

                            [self send:SOXWebSocketOpCodePongFrame
                               payload:buffer
                                length:length];

                            free(buffer);
                        }];
                    }
                        break;

                    default:
                        break;
                }
            }
            else
            {
                if ((0x80 & frame[0]) == 0x80)
                {
                    if (_frameBuffer)
                    {
                        CFDataAppendBytes(_frameBuffer, &frame[header], (CFIndex)length);
                    }

                    id message = nil;

                    const uint8_t *bytes = _frameBuffer ? CFDataGetBytePtr(_frameBuffer) : &frame[header];
                    uint64_t L = _frameBuffer ? CFDataGetLength(_frameBuffer) : length;

                    if ((opCode ?: _frameOpCode) == SOXWebSocketOpCodeTextFrame)
                    {
                        message = [[NSString alloc] initWithBytes:bytes
                                                           length:(NSUInteger)L
                                                         encoding:NSUTF8StringEncoding];

                        if (message == nil)
                        {
                            [self closeWithCode:SOXWebSocketStatusCodeInvalidFramePayloadData
                                         reason:nil];
                        }
                    }
                    else
                    {
                        message = [[NSData alloc] initWithBytes:bytes
                                                         length:(NSUInteger)L];
                    }
                    
                    if (_frameBuffer)
                    {
                        CFRelease(_frameBuffer);
                        
                        _frameBuffer = NULL;
                        _frameOpCode = 0;
                    }
                    
                    if (message)
                    {
                        [self dispatch:^{
                            
                            [self.delegate webSocket:self
                                   didReceiveMessage:message];
                        }];
                    }
                }
                else
                {
                    if (_frameBuffer == NULL)
                    {
                        _frameBuffer = CFDataCreateMutable(NULL, 0);
                        _frameOpCode = opCode;
                    }
                    
                    CFDataAppendBytes(_frameBuffer, &frame[header], (CFIndex)length);
                }
            }

            _readBufferOffset += (header + length);

            if (_readBufferOffset > 65536)
            {
                CFDataDeleteBytes(_readBuffer, CFRangeMake(0, (CFIndex)_readBufferOffset));
                _readBufferOffset = 0;
            }
        }
    }
}

@end
