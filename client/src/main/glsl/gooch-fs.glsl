#version 300 es 
precision highp float;

out vec4 fragmentColor;
in vec4 texCoord;
in vec4 worldNormal;
in vec4 worldTangent;
in vec4 worldPosition;

uniform struct{
  mat4 viewProjMatrix;
  vec3 position;
} camera;

uniform struct {
  vec4 position;
  vec3 powerDensity;
} lights[8];

uniform struct{
  samplerCube environment;
    vec3 light_position;
    vec3 light_color;
    vec3 warm_color;
    vec3 cool_color;
    float surface_brightness;
    float warm_factor;
    float cool_factor;
    float edge_threshold;
    float edge_intensity;
} material;

vec3 gooch_shading(vec3 N, vec3 L, vec3 V, vec3 H){
    // diffuse lighting
    float diffuse = max(dot(N, L), 0.0);
    vec3 diffuse_color = mix(material.cool_color, material.warm_color, diffuse * material.warm_factor + diffuse * material.cool_factor);

    // ambient lighting
    float ambient = 0.5 + 0.5 * dot(N, vec3(0, 1, 0));
    vec3 ambient_color = mix(material.cool_color, material.warm_color, ambient * material.warm_factor + ambient * material.cool_factor);

    // combine lighting and surface brightness
    vec3 final_color = material.surface_brightness * (diffuse_color * material.light_color  + ambient_color * 0.5) * material.light_position;

    // edge detection and highlighting
    float edge = 1.0 - smoothstep(material.edge_threshold, material.edge_threshold + 0.01, length(dFdx(material.light_position)) + length(dFdy(material.light_position)));
    final_color = mix(final_color, vec3(1.0), edge * material.edge_intensity);

    return final_color;
}

void main(void) {
    vec3 normal = normalize(worldNormal.xyz);
    vec3 bitangent = cross(normal, worldTangent.xyz);
    vec3 tangent = cross(bitangent, normal);
    vec3 x = worldPosition.xyz / worldPosition.w;
    vec3 viewDir = normalize(camera.position - x);
    vec3 radianceToEye = vec3(0, 0, 0);

    for (int i=0; i<1; i++){
        vec3 lightDiff = lights[i].position.xyz -
        x * lights[i].position.w;
        float lightDistSquared = dot(lightDiff, lightDiff);
        vec3 lightDir = lightDiff / sqrt(lightDistSquared);
        vec3 powerDensity = lights[i].powerDensity / lightDistSquared;

        vec3 final_color = gooch_shading(normal, lightDir, viewDir, normalize(lightDir+viewDir));

        fragmentColor= vec4(final_color, 1.0);
    }
}