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
				return col;
			}
			ENDCG
		}
	}
}
