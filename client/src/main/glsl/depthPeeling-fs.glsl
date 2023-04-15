#version 300 es
precision highp float;

out vec4 fragmentColor;
in vec4 texCoord;
in vec4 worldNormal;
in vec4 worldTangent;
in vec4 worldPosition;

uniform struct {
  mat4 viewProjMatrix;
  vec3 position;
} camera;

uniform struct {
  vec4 position;
  vec3 powerDensity;
} lights[1];

uniform samplerCube depthTexture;
uniform samplerCube prevDepthTexture;

uniform struct {
  //samplerCube depthTexture;
  //samplerCube prevDepthTexture;
  vec3 kr;
  int layer;
  int maxLayer;
} material;

vec3 brdf(vec3 normal, vec3 lightDir, vec3 viewDir) {
  return material.kr;
}

vec3 shade(vec3 powerDensity, vec3 normal, vec3 lightDir, vec3 viewDir) {
  return powerDensity * clamp(dot(normal, lightDir), 0.0f, 1.0f) * brdf(normal, lightDir, viewDir);
}

void main(void) {
  float step = 0.0001f;
  vec3 normal = normalize(worldNormal.xyz);
  vec3 bitangent = cross(normal, worldTangent.xyz);
  vec3 tangent = cross(bitangent, normal);

  vec3 x = worldPosition.xyz / worldPosition.w;
  vec3 viewDir = normalize(camera.position - x);

  vec3 radianceToEye = vec3(0, 0, 0);

  for (int i = 0; i < 1; i++) {
    vec3 lightDiff = lights[i].position.xyz - x * lights[i].position.w;
    float lightDistSquared = dot(lightDiff, lightDiff);
    vec3 lightDir = lightDiff / sqrt(lightDistSquared);
    vec3 powerDensity = lights[i].powerDensity / lightDistSquared;

    // Perform depth peeling
    vec3 texCoord = normalize(worldPosition.xyz - x);
    vec3 peelTexCoord = texCoord - texCoord * (float(material.layer + 1) / float(material.maxLayer + 1) * step);
    vec3 prevDepth = shade(powerDensity, normal, lightDir, texture(prevDepthTexture, peelTexCoord).rgb);
    vec3 currDepth = shade(powerDensity, normal, lightDir, texture(depthTexture, peelTexCoord).rgb);

    if (currDepth.r > prevDepth.r) {
      radianceToEye = material.kr * currDepth;
    } else {
      radianceToEye = material.kr * prevDepth;
    }
  }
  fragmentColor = vec4(radianceToEye, 1);
}
