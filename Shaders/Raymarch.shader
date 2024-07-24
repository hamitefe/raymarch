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
            const float CIRCLE = 0;
            const float BOX = 1;
            uniform int objectCount;
            uniform float4x4 positions[SIZE];
            uniform float3 colors[SIZE];
            uniform float types[SIZE];
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

            //float3 normalBox(float3 localPosition) {
            //    float3 p = abs(localPosition);

            //    if (p.x <= .5 && p.y <= .5){
            //        return float3(0,0,sign(localPosition.z));
            //    }

            //    if (p.y <= .5&&p.z <= .5){
            //        return float3(sign(localPosition.x),0,0);
            //    }

            //    if (p.x <= .5 && p.z <= .5){
            //        return float3(0,sign(localPosition.y),0);
            //    }

            //    if (p.x <= .5){
            //        return normalize(float3(0,sign(localPosition.y), sign(localPosition.z)));
            //    }

            //    if (p.y <= .5){
            //        return normalize(float3(sign(localPosition.x),0, sign(localPosition.z)));
            //    }

            //    if (p.z <= .5){
            //        return normalize(float3(sign(localPosition.z),sign(localPosition.y), 0));
            //    }

            //    if (p.x <= .5){
            //        return float3(0,p.y-.5, p.z-.5);
            //    }

            //    if (p.y <= .5){
            //        return float3(p.x-.5, 0,p.z-.5);
            //    }

            //    if (p.z <= .5){
            //        return float3(p.x-.5, p.y-.5,0);
            //    }

            //    return normalize(float3(
            //        sign(localPosition.x),
            //        sign(localPosition.y),
            //        sign(localPosition.z)
            //    ));
            //}

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


            //float SDFBox(float3 localPosition) {
            //    float3 p = abs(localPosition);

            //    if (p.x <= .5 && p.y <= .5){
            //        return p.z-.5;
            //    }

            //    if (p.y <= .5&&p.z <= .5){
            //        return p.x-.5;
            //    }

            //    if (p.x <= .5 && p.z <= .5){
            //        return p.y-.5;
            //    }

            //    return length(float3(p.x-.5, p.y-.5,p.z-.5));
            //}
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



            float getDistance(float3 position, int type){
                if (type == CIRCLE) return SDFCircle(position);
                else return SDFBox(position);
            }

            float3 getDistance(float3 position, float4x4 mat, int type){
                return getDistance(mul(mat,float4(position,1)), type);
            }

            float3 getNormal(float3 position, int type){
                if (type == CIRCLE) return normalCircle(position);
                else return normalBox(position);
            }

            float3 getNormal(float3 position, float4x4 mat, int type){
                return getNormal(mul(mat,float4(position,1)), type);
            }

            HitInfo getHitInfo(float3 position){
                HitInfo info;
                float dist = getDistance(position,positions[0], types[0]);                
                float3 col = colors[0];
                float3 totalCol = float3(0,0,0);
                float3 normal = getNormal(position,positions[0],types[0]);
                float totalWeight = 0;
                for (int i = 1; i < objectCount; i++){
                    float dist1 = dist;
                    float dist2 = getDistance(position,positions[i],types[i]);
                    if (dist2 == -500)continue;
                    float3 nextCol = colors[i];
                    float3 nextNormal = getNormal(position,positions[i],types[i]);
                    dist = smoothMin(dist1,dist2,_Smoothing);
                    float t = smoothstep(dist1,dist2, dist);
                    float weight1 = abs(dist2-t)/_Smoothing;
                    float weight2 = abs(dist1-t)/_Smoothing;
                    totalCol += col * abs(weight1-weight2);
                    totalCol += nextCol * abs(weight2-weight1);
                    totalWeight += abs(weight1-weight2)+abs(weight2-weight1);
                    col = lerp(col, nextCol, t);
                    normal = lerp(normal,nextNormal,t);
                }
                info.dist = dist;
                info.col = totalCol/totalWeight;
                info.normal = normal;
                info.hit = dist <= .01;
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
                for (int i = 0; i < _MaxSteps; i++){
                    HitInfo info = getHitInfo(position);
                    position += direction * info.dist;
                    if (info.hit) {
                        float light = lerp(.5,1.0,dot(info.normal,-_Light));
                        return float4(info.col * light,1.0);
                    }
                }
                return tex2D(_MainTex, uv);
            }
            ENDCG
        }
    }
}
