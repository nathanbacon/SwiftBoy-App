//
//  Shaders.metal
//  GB
//
//  Created by Nathan Gelman on 7/30/18.
//  Copyright © 2018 Nathan Gelman. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[ attribute(0) ]];
    float2 textureCoordinates [[ attribute(1) ]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinates [[ attribute(1) ]];
};

vertex VertexOut vertex_shader(const VertexIn vertexIn [[ stage_in ]]) {
    VertexOut vertexOut;
    vertexOut.position = vertexIn.position;
    vertexOut.textureCoordinates = vertexIn.textureCoordinates;
    return vertexOut;
}

fragment half4 textured_fragment(VertexOut vertexIn [[ stage_in ]], texture2d<float> texture [[ texture(0) ]] ) {
    constexpr sampler defaultSampler;
    float4 color = texture.sample(defaultSampler, vertexIn.textureCoordinates);
    return half4(color.r, color.g, color.b, 1);
}
