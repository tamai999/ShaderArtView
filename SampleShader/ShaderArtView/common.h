
#import "shader.h"

typedef struct {
    float2 position;
    float2 texCoord;
} Vertex;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
    float u_time;
    float aspectRatio;
} ColorInOut;

constexpr sampler s = sampler(coord::normalized,
                              r_address::clamp_to_edge,
                              t_address::repeat,
                              filter::linear);

float2 random(float2 st);
