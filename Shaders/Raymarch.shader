Shader "Hidden/Raymarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaxDistance("Max distance", Float) = 30.0
        _MaxSteps("Maximum Step", Integer) = 3
        _OutlineTreshold("Outline Treshold", Range(0, 1)) = 0.1
        _Smoothing("Smoothing", Float) = 0.1
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float _MaxDistance;
            float _OutlineTreshold;
            int _MaxSteps;
            float _Smoothing;
            
            #define SIZE 50


            uniform float4x4 _CamFrustum, _CamToWorld;

            uniform float3 _CamPosition;
            #define CIRCLE 0.0
            #define BOX 1
            #define DONUT = 2.0
            #define epsilon = .1
            uniform int objectCount;
            uniform float4x4 positions[SIZE];
            uniform float3 colors[SIZE];
            uniform float types[SIZE];
            uniform float extraData[SIZE];
            uniform float3 _Light;

            struct HitInfo {
                bool hit;
                float3 col;
                float3 normal;
                float dist;
                
            };

            float smoothMax(float a, float b, float t){
                return log(exp(t*a)+exp(t*b))/t;
            }

            float smoothMin(float a, float b, float t){
                return -smoothMax(-a,-b,t);
            }

            float3 normalCircle(float3 localPosition){
                return normalize(localPosition);
            }
            float SDFCircle(float3 localPosition){
                return length(localPosition)-.5f;
            }

            float3 normalBox(float3 localPosition) {
                float3 p = abs(localPosition);
                float3 n;

                // Check the major axis for each face
                if (p.x > p.y && p.x > p.z) {
                    n = float3(sign(localPosition.x), 0, 0);
                } else if (p.y > p.x && p.y > p.z) {
                    n = float3(0, sign(localPosition.y), 0);
                } else {
                    n = float3(0, 0, sign(localPosition.z));
                }

                // Ensure normalization of the normal vector
                return normalize(n);
            }
            float SDFBox(float3 localPosition) {
                float3 boxSize = float3(.5,.5,.5);
                float3 d = abs(localPosition) - boxSize;

                // Calculate the inside distance
                float insideDist = max(max(d.x, d.y), d.z);

                // Calculate the outside distance
                float outsideDist = length(max(d, 0.0));

                // Return the correct distance
                return min(insideDist, outsideDist);
            }


            float3 normalDonut(float3 localPosition) {
                float3 closestPoint = normalize(float3(localPosition.x, 0,localPosition.z));
                return normalize(localPosition - closestPoint);
            }
            float3 SDFDonut(float3 localPosition, float thickness){
                float3 closestPoint = normalize(float3(localPosition.x, 0,localPosition.z));
                return length(localPosition - closestPoint)-.25;
            }

            float3 getNormal(float3 position, int index){
                float type = types[index];
                float3 pos = mul(positions[index], float4(position,1));

                if (type == CIRCLE) return normalCircle(pos);
                if (type == BOX) return normalBox(pos);
                return normalDonut(pos);
            }

            float getDistance(float3 position, int index){
                float type = types[index];
                float3 pos = mul(positions[index],float4(position, 1));
                if (type == CIRCLE)return SDFCircle(pos);
                if (type == BOX) return SDFBox(pos);
                else return SDFDonut(pos, extraData[index]);
            }
            HitInfo getHitInfo(float3 position){
                HitInfo info;
                float dist = getDistance(position, 0);                
                float3 col = colors[0];
                float3 normal = getNormal(position, 0);
                for (int i = 1; i < objectCount; i++){
                    float dist1 = dist;
                    float dist2 = getDistance(position,i);
                    if (dist2 == -500)continue;
                    float3 nextCol = colors[i];
                    float3 nextNormal = getNormal(position, i);
                    dist = smoothMin(dist1,dist2,_Smoothing);
                    float t = smoothstep(dist1, dist2, dist);
                    col = lerp(col, nextCol, t);
                    normal = lerp(normal,nextNormal,t);
                }
                info.dist = dist;
                info.col = col;
                info.normal = normal;
                info.hit = dist <= .001;
                return info;
            }

            fixed4 frag (v2f i) : SV_Target{
                float2 uv = i.uv;
                float3 origin = _CamPosition;
                float3 horizontal = lerp(_CamFrustum[2], _CamFrustum[1], uv.x);
                float3 vertical = lerp(_CamFrustum[2], _CamFrustum[3],uv.y);
                float3 direction = float3(horizontal.x, vertical.y, horizontal.z);
                direction = normalize(mul(_CamToWorld, -direction));
                float3 position = origin;
                float totalDistance = 0;
                float oldDistance = -1;
                for (int i = 0; i < _MaxSteps; i++){
                    HitInfo info = getHitInfo(position);
                    position += direction * info.dist;
                    if (info.hit) {
                        float light = lerp(.5,1.0,dot(info.normal,-_Light));
                        return float4(info.col * light,1.0);
                    }
                    if (oldDistance == -1) {
                        oldDistance = info.dist;
                        continue;
                    }
                    if (oldDistance < info.dist && oldDistance <= _OutlineTreshold) return float4(0.0,0.0,0.0,1.0);
                    oldDistance = info.dist;
                }
                return tex2D(_MainTex, uv);
            }
            ENDCG
        }
    }
}
