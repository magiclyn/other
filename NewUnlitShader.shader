Shader "Unlit/NewUnlitShader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma hull hull
			#pragma domain MyDomainProgram
			#pragma geometry MyGeometryProgram
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			struct VertexData {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
					float2 uv : TEXCOORD0;
					float2 uv1 : TEXCOORD1;
					float2 uv2 : TEXCOORD2;
			};


			struct TessellationFactors {
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			struct TessellationControlPoint {
				float4 vertex : INTERNALTESSPOS;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float2 uv2 : TEXCOORD2;
			};

			struct v2f
			{
				float2 uv9:TEXCOORD9;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
					float4 vertex : SV_POSITION;
			};


			TessellationFactors MyPatchConstantFunction(InputPatch<TessellationControlPoint, 3> patch) {
				TessellationFactors f;
				f.edge[0] = 3;
				f.edge[1] = 3;
				f.edge[2] = 3;
				f.inside = 3;
				return f;
			}



			TessellationControlPoint vert(VertexData v)
			{
				TessellationControlPoint p;
				p.vertex = v.vertex;
				p.normal = v.normal;
				p.tangent = v.tangent;
				p.uv = v.uv;
				p.uv1 = v.uv1;
				p.uv2 = v.uv2;
				return p;
			}

			v2f vert2(VertexData v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}


			[domain("tri")]
			[UNITY_outputcontrolpoints(3)]
			[UNITY_outputtopology("triangle_cw")]
			[UNITY_partitioning("integer")]
			[UNITY_patchconstantfunc("MyPatchConstantFunction")]
			[maxtessfactor(64.0)]
			TessellationControlPoint hull(InputPatch<TessellationControlPoint, 3> input, uint controlPointId : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
			{

				return input[controlPointId];
			}


			[UNITY_domain("tri")]
			v2f  MyDomainProgram(
				TessellationFactors factors,
				OutputPatch<TessellationControlPoint, 3> patch,
				float3 barycentricCoordinates : SV_DomainLocation
			) {
				VertexData data;
			#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
		            patch[0].fieldName * barycentricCoordinates.x + \
		            patch[1].fieldName * barycentricCoordinates.y + \
		            patch[2].fieldName * barycentricCoordinates.z;


				MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
					MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
					MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)
					MY_DOMAIN_PROGRAM_INTERPOLATE(uv)
					MY_DOMAIN_PROGRAM_INTERPOLATE(uv1)
					MY_DOMAIN_PROGRAM_INTERPOLATE(uv2)

					v2f v = vert2(data);
				return v;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				UNITY_APPLY_FOG(i.fogCoord, col);

				float3 barys;
				barys.xy = i.uv9;
				barys.z = 1 - barys.x - barys.y;
				float3 deltas = fwidth(barys);



				float3 smoothing = deltas * 0.5;
				float3 thickness = deltas * 0.5;



				barys = smoothstep(thickness, thickness + smoothing, barys);
				float minBary = min(barys.x, min(barys.y, barys.z));

				float3 v =  lerp(float3(1,0,0), col.xyz, minBary);

				return fixed4(v.x,v.y,v.z,col.w);
				//return fixed4(d1, col.w);
			}

				[maxvertexcount(3)]
			void MyGeometryProgram(
				triangle v2f i[3],
				inout TriangleStream<v2f> stream
			) {
				//float3 p0 = i[0].worldPos.xyz;
				//float3 p1 = i[1].worldPos.xyz;
				//float3 p2 = i[2].worldPos.xyz;

				//float3 triangleNormal = normalize(cross(p1 - p0, p2 - p0));
				//i[0].normal = triangleNormal;
				//i[1].normal = triangleNormal;
				//i[2].normal = triangleNormal;

				//InterpolatorsGeometry g0, g1, g2;
				//g0.data = i[0];
				//g1.data = i[1];
				//g2.data = i[2];

				i[0].uv9 = float2(1, 0);
				i[1].uv9 = float2(0, 1);
				i[2].uv9 = float2(0, 0);

				stream.Append(i[0]);
				stream.Append(i[1]);
				stream.Append(i[2]);
			}
			ENDCG
		}
	}
}
