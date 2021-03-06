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

#import "HttpJsonResponse.h"

@implementation HttpJsonResponse

@synthesize body = _body;

-(HttpJsonResponse*) initWithSimpleResponse:(HttpResponse*) httpResponse {
    self = [super init];
    [self setCode:[httpResponse code]];
    [self setHeaders:[httpResponse headers]];
    [self setRawBody:[httpResponse rawBody]];
    [self setError:[httpResponse error]];
    
    JsonNode* body = nil;
    if (self.error == nil) {
        body = [[JsonNode alloc] init];
        
        NSError * error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:[httpResponse rawBody] options:0 error:&error];
        
        if (error == nil) {
            if ([json isKindOfClass:[NSArray class]]) {
                [body setArray:json];
            } else {
                [body setObject:json];
            }
        } else {
            
            NSLog(@"NSJSONSerialization error body : %@", [httpResponse rawBody]);
            body = nil;
            NSLog(@"NSJSONSerialization error : %@", [error description]);
            [self setError:error];
        }
    }
    
    [self setBody:body];
    return self;
}

@end
