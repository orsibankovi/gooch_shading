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
} lights[1];

uniform struct{
    vec3 light_position;
    vec3 light_color;
    vec3 warm_color;
    vec3 cool_color;
    float surface_brightness;
    float warm_factor;
    float cool_factor;
} material;

vec3 gooch_shading(vec3 N, vec3 L, vec3 V, vec3 H){
    float edge_threshold = 0.5f;
    float edge_intensity = 0.1f;
    float diffuse = max(dot(N, L), 0.0);
    vec3 diffuse_color = mix(material.cool_color, material.warm_color, diffuse * material.warm_factor + diffuse * material.cool_factor);

    vec3 final_color = material.surface_brightness * diffuse_color * material.light_color * material.light_position;

    float edge = 1.0 - smoothstep(edge_threshold, edge_threshold, length(dFdx(material.light_position)) + length(dFdy(material.light_position)));
    final_color = mix(final_color, vec3(1.0), edge * edge_intensity);

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