Shader "New Chromantics/Kinect Point Cloud"
{
	Properties
	{
		Colour("ColourTexture", 2D) = "white" {}
		Depth("DepthTexture", 2D) = "white" {}
		DepthFovHorz("DepthFovHorz",Range(10,90) ) = 45
		DepthFovVert("DepthFovVert",Range(10,90) ) = 45
		DepthScalar("DepthScalar",Range(0.01,1))  = 1
		DepthNearClip("DepthNearClip", Range(-10,10) ) = -2
		DepthFarClip("DepthFarClip", Range(0,10) ) = 10
		KinectFarMm("KinectFarMm", Range(100,10000) ) = 9998	//	invalid after 9998mm
		KinectNearMm("KinectNearMm", Range(0,1000) ) = 1		//	invalid when too close
		ParticleSize("ParticleSize",Range(0.001,0.1) ) = 0.1
		Radius("Radius", Range(0,1) ) = 0.5
		ShowInvalidAndClipped("ShowInvalidAndClipped", Range(0,1) ) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
#pragma exclude_renderers d3d11_9x
			#pragma vertex vert
			#pragma fragment frag
			
			#define GEOMETRY_TRIANGULATION

			#ifdef GEOMETRY_TRIANGULATION
			#pragma geometry geom
			#endif

			#include "UnityCG.cginc"
			#define lengthsq(x)	dot( (x), (x) )
			#define squared(x)	( (x)*(x) )

			struct appdata
			{
				float4 vertex : POSITION;
			};

			
			struct vert2geo
			{
			#ifdef GEOMETRY_TRIANGULATION
				float4 WorldPos : TEXCOORD2;
			#else
				float4 ScreenPos : SV_POSITION;
			#endif
				float2 uv : TEXCOORD0;
				float Depth : TEXCOORD1;
			};

			struct FragData
			{
				float3 LocalOffset : TEXCOORD1;
				float4 ScreenPos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float Depth : TEXCOORD2;
			};

			sampler2D ColourTexture;
			float4 ColourTexture_ST;
			float4 ColourTexture_TexelSize;

			sampler2D DepthTexture;
			float4 DepthTexture_ST;
			float4 DepthTexture_TexelSize;

			float DepthFovHorz;
			float DepthFovVert;
			float DepthScalar;
			float DepthNearClip;
			float DepthFarClip;
			float KinectFarMm;
			float KinectNearMm;
			float ParticleSize;
			float Radius;
			int ShowInvalidAndClipped;

			float3 GetParticleSize3()
			{
				//	gr: thought it length of each row was scale but... doesn't seem to be. row vs col major issue?
				//float WorldScale = length(unity_ObjectToWorld[0]) + length(unity_ObjectToWorld[1]) + length(unity_ObjectToWorld[2]);
				//WorldScale /= 3.0;

				float3 OneTrans = mul( unity_ObjectToWorld, float4(1,0,0,0 ) );
				float3 ZeroTrans = mul( unity_ObjectToWorld, float4(0,0,0,0 ) );
				float WorldScale = length(OneTrans - ZeroTrans);
				float3 ParticleSize3 = float3( ParticleSize * WorldScale, ParticleSize * WorldScale, ParticleSize * WorldScale );
				return ParticleSize3;
			}


			FragData MakeFragData(float3 TriangleIndexer,float3 input_WorldPos,float2 input_uv,float input_depth,float3 ParticleSize3)
			{
				float isa = TriangleIndexer.x ;
				float isb = TriangleIndexer.y ;
				float isc = TriangleIndexer.z ;

				FragData x = (FragData)0;

				//	gr: use maths to work out biggest circle 
				float Top = -0.6;
				float Bottom = 0.3;
				float Width = 0.5;
				x.LocalOffset = isa * float3( 0,Top,0 );
				x.LocalOffset += isb * float3( -Width,Bottom,0 );
				x.LocalOffset += isc * float3( Width,Bottom,0 );

				float3 x_WorldPos = mul( UNITY_MATRIX_V, float4(input_WorldPos,1) ) + (x.LocalOffset * ParticleSize3);
				x.ScreenPos = mul( UNITY_MATRIX_P, float4(x_WorldPos,1) );
				x.uv = input_uv;
				x.Depth = input_depth;
				return x;
			}


			float GetDepth(float2 uv)
			{
				float4 DepthRgba = tex2Dlod( DepthTexture, float4(uv,0,0) );
				float Depth = DepthRgba.g * 255.0f * 255.0f;
				Depth += DepthRgba.r * 255.0f;
				Depth /= 255.0f * 255.0f + 255.0f;
				Depth *= 10000;	//	mm

				//	invalid
				if ( Depth >= KinectFarMm )
					return -1;
				if ( Depth <= KinectNearMm )
					return -1;

				Depth /= 1000;	//	metres
				Depth += DepthNearClip;

				if ( Depth-DepthNearClip >= DepthFarClip )
					return -1;

				Depth *= DepthScalar;

				//	spot invalid
				if ( DepthRgba.a < 1.0f )
					return -1;
				if ( DepthRgba.b > 0 )
					return -1;

				return Depth;
			}

			void GetPixelRay(float2 uv,out float3 Start,out float3 Dir)
			{
				//	0..1 to -1...1
				uv -= 0.5f;
				uv *= 2.0f;

				//	project uv by fov & distortion
				Start = float3( uv.x, uv.y, 0 );
				Dir = float3(0,0,-1);
			}

			float3 GetProjection(float2 uv)
			{
				float Depth = GetDepth(uv);
				float3 RayStart,RayDir;
				GetPixelRay( uv, RayStart, RayDir );
				return RayStart + (RayDir*Depth);
			}

			vert2geo vert (appdata v)
			{
				vert2geo o;

				float2 uv = v.vertex.xy * DepthTexture_TexelSize.xy;
				float4 LocalPos = float4( GetProjection( uv ), 1 );
				float4 WorldPos = mul( unity_ObjectToWorld, LocalPos );
				//o.ScreenPos = UnityWorldToClipPos(WorldPos);
				o.WorldPos = WorldPos;
				o.uv = uv;
				o.Depth = GetDepth(uv);
				return o;
			}
			
		#ifdef GEOMETRY_TRIANGULATION
			[maxvertexcount(9)]
			void geom(point vert2geo _input[1], inout TriangleStream<FragData> OutputStream)
			{
				int v=0;
				//	get particle size in worldspace
				float3 ParticleSize3 = GetParticleSize3();

				{
					vert2geo input = _input[v];

					FragData a = MakeFragData( float3(1,0,0), input.WorldPos, input.uv, input.Depth, ParticleSize3 );
					FragData b = MakeFragData( float3(0,1,0), input.WorldPos, input.uv, input.Depth, ParticleSize3 );
					FragData c = MakeFragData( float3(0,0,1), input.WorldPos, input.uv, input.Depth, ParticleSize3 );

					OutputStream.Append(a);
					OutputStream.Append(b);
					OutputStream.Append(c);
				}
			}
		#endif//GEOMETRY_TRIANGULATION

			fixed4 frag (FragData i) : SV_Target
			{
				if ( i.Depth < 0 )
				{
					if ( ShowInvalidAndClipped )
						return float4(0,0,1,1);
					discard;
				}

				float DistanceFromCenterSq = lengthsq(i.LocalOffset);
				if ( DistanceFromCenterSq > squared(Radius) )
					discard;

				// sample the texture
				fixed4 col = tex2D( ColourTexture, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
