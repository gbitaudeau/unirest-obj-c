/*
 The MIT License
 
 Copyright (c) 2013 Mashape (http://mashape.com)
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "HttpRequest.h"
#import "HttpClientHelper.h"

@interface HttpRequest()

- (void)invokeAsync:(HttpResponse * (^)(void))asyncBlock resultBlock:(void (^)(id))resultBlock errorBlock:(void (^)(id))errorBlock;

@end

@implementation HttpRequest

@synthesize httpMethod = _httpMethod;
@synthesize headers = _headers;
@synthesize url = _url;


// invokeAsync snippet got from: https://gist.github.com/raulraja/1176022

- (void)invokeAsync:(HttpResponse * (^)(void))asyncBlock resultBlock:(void (^)(id))resultBlock errorBlock:(void (^)(id))errorBlock {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        HttpResponse * result = nil;
        id error = nil;
        @try {
            result = asyncBlock();
            if (result.error != nil) {
                error = result.error;
            }
        } @catch (NSException *exception) {
            NSLog(@"caught exception: %@", exception);
            error = exception;
        }
        // tell the main thread
        if (error != nil) {
            if (errorBlock != nil) {
                errorBlock(error);
            }
        } else {
            resultBlock(result);
        };
    });
}

-(HttpRequest*) initWithSimpleRequest:(HttpMethod) httpMethod url:(NSString*) url headers:(NSDictionary*) headers {
    self = [super init];
    [self setHttpMethod:httpMethod];
    [self setUrl:url];
    NSMutableDictionary* lowerCaseHeaders = [[NSMutableDictionary alloc] init];
    if (headers != nil) {
        for(id key in headers) {
            id value = [headers objectForKey:key];
            [lowerCaseHeaders setObject:value forKey:[key lowercaseString]];
        }
    }
    [self setHeaders:lowerCaseHeaders];
    return self;
}

-(HttpStringResponse*) asString {
    HttpResponse* response = [HttpClientHelper request:self];
    return [[HttpStringResponse alloc] initWithSimpleResponse:response];
}

-(void) asStringAsync:(void (^)(HttpStringResponse*)) response withError:(void (^)(id))errorBlock {
    [self invokeAsync:^{
        return [self asString];
    }     resultBlock:response errorBlock:errorBlock];
}

-(HttpBinaryResponse*) asBinary {
    HttpResponse* response = [HttpClientHelper request:self];
    return [[HttpBinaryResponse alloc] initWithSimpleResponse:response];
}

-(void) asBinaryAsync:(void (^)(HttpBinaryResponse*)) response withError:(void (^)(id))errorBlock {
    [self invokeAsync:^{
        return [self asBinary];
    }     resultBlock:response errorBlock:errorBlock];
}

-(HttpJsonResponse*) asJson {
    HttpResponse* response = [HttpClientHelper request:self];
    return [[HttpJsonResponse alloc] initWithSimpleResponse:response];
}

-(void) asJsonAsync:(void (^)(HttpJsonResponse*)) response withError:(void (^)(id))errorBlock {
    [self invokeAsync:^{
        return [self asJson];
    }     resultBlock:response errorBlock:errorBlock];
}

@end
