Shader "Hidden/Raymarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaxDistance("Max distance", Float) = 30.0
        _MaxSteps("Maximum Step", Integer) = 3
        _OutlineTreshold("Outline Treshold", Range(0, 1)) = 0.1
        _Smoothing("Smoothing", Float) = 0.1
        _Repetition("Repetition", Vector) = (5.0, 5.0, 5.0, 0.0)
        _OutlineColor("Outline Color", Color) = (1.0,1.0,1.0,1.0)
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
            float3 _Repetition;
            float3 _OutlineColor;

            #define SIZE 50


            uniform float4x4 _CamFrustum, _CamToWorld;

            uniform float3 _CamPosition;
            #define CIRCLE 0.0
            #define BOX 1
            #define DONUT 2.0
            #define LINE 3.0
            #define epsilon 1e-3
            uniform int objectCount;
            uniform float4x4 positions[SIZE];
            uniform float3 colors[SIZE];
            uniform float types[SIZE];
            uniform float extraData[SIZE];
            uniform float3 repetitions[SIZE];
            uniform float3 _Light;
            

            struct HitInfo {
                bool hit;
                float3 col;
                float3 normal;
                float dist;
                
            };


            float2 min( float a, float b, float k ){
                float h = 1.0 - min( abs(a-b)/(4.0*k), 1.0 );
                float w = h*h;
                float m = w*0.5;
                float s = w*k;
                return (a<b) ? float2(a-s,m) : float2(b-s,1.0-m);
            }

            float rand(float2 n){ 
                return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
            }

            float noise(float2 p) {
                float2 ip = floor(p);
                float2 u = frac(p);
                u = u * u * (3.0 - 2.0 * u);

                float res = lerp(
                    lerp(rand(ip), rand(ip + float2(1.0, 0.0)), u.x),
                    lerp(rand(ip + float2(0.0, 1.0)), rand(ip + float2(1.0, 1.0)), u.x),
                    u.y);
                return res * res;
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
            float SDFBox( float3 p, float roundness){
              float3 q = abs(p) - float3(.5,.5,.5);
              return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0)-roundness;
            }


            float3 normalDonut(float3 localPosition) {
                float3 closestPoint = normalize(float3(localPosition.x, 0,localPosition.z));
                return normalize(localPosition - closestPoint);
            }
            float3 SDFDonut(float3 localPosition){
                float3 closestPoint = normalize(float3(localPosition.x, 0,localPosition.z));
                return length(localPosition - closestPoint)/2-.1;
            }

            float3 SDFLine(float3 localPosition, float thickness){
                localPosition = abs(localPosition);
                localPosition.y -= min(.5, localPosition.y);
                return length(localPosition)-thickness;
            }

            float3 normalLine(float3 localPosition){
                return float3(1,1,1);
            }

            float3 repeat(float3 position, float3 axes){
                float3 nextPos = position;
                if (axes.x != 0)nextPos.x = abs(nextPos.x)%axes.x - axes.x/2;
                if (axes.y != 0)nextPos.y = abs(nextPos.y)%axes.y - axes.y/2;
                if (axes.z != 0)nextPos.z = abs(nextPos.z)%axes.z - axes.z/2;
                return nextPos;
            }

            float3 getNormal(float3 position, int index){
                float type = types[index];
                position = repeat(position, repetitions[index]);
                float3 pos = mul(positions[index], float4(position,1));

                if (type == CIRCLE) return normalCircle(pos);
                if (type == BOX) return normalBox(pos);
                if (type==DONUT) return normalDonut(pos);
                return normalLine(pos);
            }

            float getDistance(float3 position, int index){
                float type = types[index];
                float3 repeated = repeat(position, repetitions[index]);
                position = repeated;
                float3 pos = mul(positions[index],float4(position, 1.0));
                if (type == CIRCLE)return SDFCircle(pos);
                if (type == BOX) return SDFBox(pos, extraData[index]);
                if (type == DONUT) return SDFDonut(pos);
                return SDFLine(pos, extraData[index]);
            }

            HitInfo getHitInfo(float3 position){
                HitInfo info;
                float dist = getDistance(position, 0);
                float3 col = colors[0];
                float3 normal = getNormal(position, 0);
                for (int i = 1; i < objectCount; i++){
                    float dist2 = getDistance(position,i);
                    float3 nextCol = colors[i];
                    float3 nextNormal = getNormal(position, i);
                    float2 res = min(dist,dist2,_Smoothing);
                    dist = res.x;
                    col = lerp(col, nextCol, res.y);
                    normal = lerp(normal,nextNormal,res.y);
                }
                info.dist = dist;
                info.col = col;
                info.normal = normal;
                info.hit = info.dist <= epsilon;
                return info;
            }

            fixed4 frag (v2f i) : SV_Target{
                float2 uv = i.uv;
                float3 origin = _CamPosition;
                float3 horizontal = lerp(_CamFrustum[2], _CamFrustum[1], uv.x);
                float3 vertical = lerp(_CamFrustum[2], _CamFrustum[3],uv.y);
                float3 direction = float3(horizontal.x, vertical.y, horizontal.z);
                direction = normalize(mul(_CamToWorld, float4(-direction,0)));
                float3 position = origin;
                float totalDistance = 0;
                float oldDistance = -1;
                for (int i = 0; i < _MaxSteps; i++){
                    HitInfo info = getHitInfo(position);
                    totalDistance += info.dist;
                    position += direction * info.dist;
                    float _fog = 1.0-smoothstep(0, _MaxDistance, totalDistance);
                    if (info.hit) {
                        float light = lerp(.6,1.0,dot(info.normal,-_Light));
                        
                        return float4(info.col * light * _fog,1.0);
                    }
                    
                    if (oldDistance == -1) {
                        oldDistance = info.dist;
                        continue;
                    }
                    if (totalDistance > _MaxDistance)break;
                    if (oldDistance < info.dist && oldDistance <= _OutlineTreshold) return float4(_OutlineColor*_fog,1.0);
                    oldDistance = info.dist;
                }
                float _fog = 1.0-smoothstep(0, _MaxDistance, totalDistance);
                return float4(0.0,0.0,0.0, 1.0);
            }
            ENDCG
        }
    }
}
