#ifdef GL_ES
precision mediump float;
#endif

layout(location = 0) out vec4 fragColor;

uniform float iTime;
uniform vec2 iResolution;
uniform vec2 splashPoint;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform float circleMixFactor;

uniform float devicePixelRatio;
uniform float shockStrength;
uniform float lensingSpread;
uniform float powExp;
uniform float maxRadius;


void main() {
    // iResolution is PHYSICAL. gl_FragCoord is PHYSICAL.
    // uv becomes 0.0 - 1.0 covering the screen.
    vec2 unscaledUv = gl_FragCoord.xy / iResolution.xy;
    vec2 uv = unscaledUv; 

    // splashPoint is LOGICAL.
    // logical_resolution = iResolution.xy / devicePixelRatio.
    vec2 origin = splashPoint.xy / (iResolution.xy / devicePixelRatio);

    float localTime = iTime;

    float aspect = iResolution.x / iResolution.y;

    vec2 scaledUv     = vec2(uv.x * aspect, uv.y);
    vec2 scaledOrigin = vec2(origin.x * aspect, origin.y);

    // Constants
    const float HALF_PI = 3.14;

    float radius = maxRadius * localTime;

    float circle = radius - distance(scaledOrigin, scaledUv);

    // Damping: Wave amplitude decreases as it travels further
    // Simple linear damping based on time
    float damping = 1.0 - localTime; 

    // Main ripple factor
    float factor = shockStrength
    * damping 
    * sin(localTime * HALF_PI)
    * pow(clamp(1.0 - abs(circle), 0.0, 1.0), powExp);

    // Lensing offset
    vec2 offsetVec = (lensingSpread * factor) * normalize(origin - uv);

    // Sample both textures
    vec3 color0 = texture(iChannel0, uv + offsetVec).rgb;
    vec3 color1 = texture(iChannel1, uv + offsetVec).rgb;

    // Transition mix factor
    float mixVal = clamp(localTime + circle * circleMixFactor, 0.0, 1.0);

    // Final color
    vec3 color = mix(color0, color1, mixVal);
    fragColor = vec4(color, 1.0);
}