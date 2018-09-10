//
//  Objc_Gb_Apu.m
//  GB
//
//  Created by Nathan Gelman on 9/7/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

#include "Gb_Apu.h"

#import <Foundation/Foundation.h>
#import "Objc_Stereo_Buffer.mm"

/*@interface Gb_Apu_Wrapper: NSObject

@end

@interface Gb_Apu_Wrapper ()
@property (nonatomic, readwrite, assign) Gb_Apu *gb_apu;
@end

@implementation Gb_Apu_Wrapper
@synthesize gb_apu = _gb_apu;

- (id)init {
    self = [super init];
    if(self) {
        _gb_apu = new Gb_Apu();
    }
    return self;
}

- (void)dealloc {
    delete _gb_apu;
}

- (void) write_register:(uint32_t)time :(uint32_t)addr :(int32_t)data {
    _gb_apu->write_register(time, addr, data);
}

- (int) read_register:(uint32_t)time :(uint32_t)addr {
    return _gb_apu->read_register(time, addr);
}

- (void)end_frame:(uint32_t)time {
    _gb_apu->end_frame(time);
}

- (void)set_output:(Stereo_Buffer_Wrapper*)stereo_buffer_wrapper {
    _gb_apu->set_output(stereo_buffer_wrapper.stereo_buffer->center(), stereo_buffer_wrapper.stereo_buffer->left(), stereo_buffer_wrapper.stereo_buffer->left());
}

@end
*/
