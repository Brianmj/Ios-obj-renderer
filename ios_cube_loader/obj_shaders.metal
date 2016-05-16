//
//  obj_shaders.metal
//  ios_cube_loader
//
//  Created by Brian Jones on 5/13/16.
//  Copyright © 2016 Brian Jones. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct TransformationMatricies{
    float4x4 projection;
    float4x4 model_view;
};

struct Vertex {
    float4 pos [[position]];
};

struct VertexNormal {
    float4 pos [[position]];
    float4 normal;
};

struct VertexOutput {
    float4 pos [[position]];
    float4 normal [[user(NORMAL)]];
};

struct FragmentInput {
    float4 normal[[user(NORMAL)]];
};


// for vertex_normals
vertex VertexOutput obj_vertex_normal_vertex_func(constant VertexNormal *vertices [[buffer(0)]],
                                                constant TransformationMatricies &matrices [[buffer(1)]],
                                     const uint id [[vertex_id]]) {
    VertexOutput output;
    output.pos = matrices.projection * matrices.model_view * vertices[id].pos;
    
    // do something here for the time being until lighting is implemented
    output.normal = vertices[id].normal;
    
    return output;
}

fragment float4 obj_vertex_normal_fragment_func(FragmentInput input [[stage_in]]) {
    
    // for now just return a white color
    return float4(1.0, 1.0, 1.0, 1.0f);
}
