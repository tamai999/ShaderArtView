#include <metal_stdlib>
using namespace metal;

#import "common.h"

vertex ColorInOut vertexShader(const device Vertex *vertices [[ buffer(0) ]],
                               constant Uniforms &uniforms [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]]) {
    ColorInOut out;
    const device Vertex& vert = vertices[vid];
    out.position = float4(vert.position, 0.0, 1.0);
    out.texCoord = vert.texCoord;
    out.u_time = uniforms.u_time;
    out.aspectRatio = uniforms.aspectRatio;
    return out;
}

float2 random(float2 st) {
    st = float2(dot(st, float2(127.1, 311.7)), dot(st, float2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}
