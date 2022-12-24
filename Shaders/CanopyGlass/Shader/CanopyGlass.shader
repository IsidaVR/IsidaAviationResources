// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Isida/CanopyGlass"
{
	Properties
	{
		_FresnelColor2("Fresnel Color 2", Color) = (0,1,0.07791209,0)
		_FresnelColor1("Fresnel Color 1", Color) = (0,0.1269569,1,0)
		_FresnelScale("Fresnel Scale", Float) = 11.56
		_FresnelBias("Fresnel Bias", Float) = 0
		_FresnelPower("Fresnel Power", Float) = 1.69
		[Header(Translucency)]
		_Translucency("Strength", Range( 0 , 50)) = 1
		_TransNormalDistortion("Normal Distortion", Range( 0 , 1)) = 0.1
		_TransScattering("Scaterring Falloff", Range( 1 , 50)) = 2
		_TransDirect("Direct", Range( 0 , 1)) = 1
		_TransAmbient("Ambient", Range( 0 , 1)) = 0.2
		_TransShadow("Shadow", Range( 0 , 1)) = 0.9
		_Texture1("Texture 1", 2D) = "white" {}
		_Texture2("Texture 2", 2D) = "white" {}
		_InnerGlassSmoothnes("Inner Glass Smoothnes", Range( 0 , 1)) = 1
		_InnerMetalic("Inner Metalic", Range( 0 , 1)) = 0
		_InnerOpacity("Inner Opacity", Range( 0 , 1)) = 0
		_SurficeRougness("Surfice Rougness", 2D) = "white" {}
		_InnerRoughnessPowerSunside("Inner Roughness Power Sunside", Float) = 0
		_InnerOuterRoughnessPower("Inner-Outer Roughness Power", Float) = 0
		_TextureGradientBias("Texture Gradient Bias", Float) = 0.4
		_GradientPower("Gradient Power", Float) = 1.33
		[Header(Refraction)]
		_ChromaticAberration("Chromatic Aberration", Range( 0 , 0.3)) = 0.1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" }
		Cull Back
		ZTest LEqual
		Blend One OneMinusSrcAlpha
		
		AlphaToMask On
		GrabPass{ }
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma multi_compile _ALPHAPREMULTIPLY_ON
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldPos;
			half3 worldNormal;
			INTERNAL_DATA
			float2 uv_texcoord;
			float4 screenPos;
		};

		struct SurfaceOutputStandardCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			half3 Translucency;
		};

		uniform half4 _FresnelColor1;
		uniform half4 _FresnelColor2;
		uniform half _FresnelBias;
		uniform half _FresnelScale;
		uniform half _FresnelPower;
		uniform half _InnerMetalic;
		uniform half _InnerGlassSmoothnes;
		uniform half _Translucency;
		uniform half _TransNormalDistortion;
		uniform half _TransScattering;
		uniform half _TransDirect;
		uniform half _TransAmbient;
		uniform half _TransShadow;
		uniform sampler2D _SurficeRougness;
		uniform half4 _SurficeRougness_ST;
		uniform half _InnerRoughnessPowerSunside;
		uniform sampler2D _Texture2;
		uniform half4 _Texture2_ST;
		uniform sampler2D _Texture1;
		uniform half4 _Texture1_ST;
		uniform half _GradientPower;
		uniform half _InnerOuterRoughnessPower;
		uniform half _InnerOpacity;
		uniform half _TextureGradientBias;
		uniform sampler2D _GrabTexture;
		uniform float _ChromaticAberration;

		inline half4 LightingStandardCustom(SurfaceOutputStandardCustom s, half3 viewDir, UnityGI gi )
		{
			#if !DIRECTIONAL
			float3 lightAtten = gi.light.color;
			#else
			float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, _TransShadow );
			#endif
			half3 lightDir = gi.light.dir + s.Normal * _TransNormalDistortion;
			half transVdotL = pow( saturate( dot( viewDir, -lightDir ) ), _TransScattering );
			half3 translucency = lightAtten * (transVdotL * _TransDirect + gi.indirect.diffuse * _TransAmbient) * s.Translucency;
			half4 c = half4( s.Albedo * translucency * _Translucency, 0 );

			SurfaceOutputStandard r;
			r.Albedo = s.Albedo;
			r.Normal = s.Normal;
			r.Emission = s.Emission;
			r.Metallic = s.Metallic;
			r.Smoothness = s.Smoothness;
			r.Occlusion = s.Occlusion;
			r.Alpha = s.Alpha;
			return LightingStandard (r, viewDir, gi) + c;
		}

		inline void LightingStandardCustom_GI(SurfaceOutputStandardCustom s, UnityGIInput data, inout UnityGI gi )
		{
			#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
				gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
			#else
				UNITY_GLOSSY_ENV_FROM_SURFACE( g, s, data );
				gi = UnityGlobalIllumination( data, s.Occlusion, s.Normal, g );
			#endif
		}

		inline float4 Refraction( Input i, SurfaceOutputStandardCustom o, float indexOfRefraction, float chomaticAberration ) {
			float3 worldNormal = o.Normal;
			float4 screenPos = i.screenPos;
			#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
			#else
				float scale = 1.0;
			#endif
			float halfPosW = screenPos.w * 0.5;
			screenPos.y = ( screenPos.y - halfPosW ) * _ProjectionParams.x * scale + halfPosW;
			#if SHADER_API_D3D9 || SHADER_API_D3D11
				screenPos.w += 0.00000000001;
			#endif
			float2 projScreenPos = ( screenPos / screenPos.w ).xy;
			float3 worldViewDir = normalize( UnityWorldSpaceViewDir( i.worldPos ) );
			float3 refractionOffset = ( indexOfRefraction - 1.0 ) * mul( UNITY_MATRIX_V, float4( worldNormal, 0.0 ) ) * ( 1.0 - dot( worldNormal, worldViewDir ) );
			float2 cameraRefraction = float2( refractionOffset.x, refractionOffset.y );
			float4 redAlpha = tex2D( _GrabTexture, ( projScreenPos + cameraRefraction ) );
			float green = tex2D( _GrabTexture, ( projScreenPos + ( cameraRefraction * ( 1.0 - chomaticAberration ) ) ) ).g;
			float blue = tex2D( _GrabTexture, ( projScreenPos + ( cameraRefraction * ( 1.0 + chomaticAberration ) ) ) ).b;
			return float4( redAlpha.r, green, blue, redAlpha.a );
		}

		void RefractionF( Input i, SurfaceOutputStandardCustom o, inout half4 color )
		{
			#ifdef UNITY_PASS_FORWARDBASE
			color.rgb = color.rgb + Refraction( i, o, 1.0, _ChromaticAberration ) * ( 1 - color.a );
			color.a = 1;
			#endif
		}

		void surf( Input i , inout SurfaceOutputStandardCustom o )
		{
			o.Normal = float3(0,0,1);
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half3 ase_worldNormal = WorldNormalVector( i, half3( 0, 0, 1 ) );
			half fresnelNdotV255 = dot( ase_worldNormal, ase_worldViewDir );
			half fresnelNode255 = ( _FresnelBias + _FresnelScale * pow( 1.0 - fresnelNdotV255, _FresnelPower ) );
			half clampResult153 = clamp( fresnelNode255 , 0.0 , 1.0 );
			half4 lerpResult152 = lerp( _FresnelColor1 , _FresnelColor2 , clampResult153);
			half4 FresnelColor253 = lerpResult152;
			half4 temp_output_254_0 = FresnelColor253;
			o.Albedo = temp_output_254_0.rgb;
			half temp_output_44_0 = _InnerMetalic;
			o.Metallic = temp_output_44_0;
			half temp_output_38_0 = _InnerGlassSmoothnes;
			o.Smoothness = temp_output_38_0;
			float2 uv_SurficeRougness = i.uv_texcoord * _SurficeRougness_ST.xy + _SurficeRougness_ST.zw;
			half4 tex2DNode225 = tex2D( _SurficeRougness, uv_SurficeRougness );
			float2 uv_Texture2 = i.uv_texcoord * _Texture2_ST.xy + _Texture2_ST.zw;
			float2 uv_Texture1 = i.uv_texcoord * _Texture1_ST.xy + _Texture1_ST.zw;
			half4 temp_output_224_0 = ( tex2D( _Texture2, uv_Texture2 ) * tex2D( _Texture1, uv_Texture1 ) );
			half4 color207 = IsGammaSpace() ? half4(1,1,1,0) : half4(1,1,1,0);
			half dotResult116 = dot( ase_worldNormal , _WorldSpaceLightPos0.xyz );
			half4 temp_output_209_0 = ( ( ( ( tex2DNode225 * _InnerRoughnessPowerSunside ) + temp_output_224_0 ) * color207 ) * pow( -dotResult116 , _GradientPower ) );
			half4 clampResult210 = clamp( temp_output_209_0 , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
			o.Translucency = clampResult210.rgb;
			half4 temp_output_240_0 = ( tex2DNode225 * _InnerOuterRoughnessPower );
			half4 temp_output_237_0 = ( temp_output_240_0 + temp_output_224_0 );
			half4 color193 = IsGammaSpace() ? half4(1,1,1,0) : half4(1,1,1,0);
			half temp_output_179_0 = abs( dotResult116 );
			half4 temp_output_221_0 = ( ( ( temp_output_237_0 * color193 ) + _InnerOpacity ) * pow( ( temp_output_179_0 - _TextureGradientBias ) , _GradientPower ) );
			half4 clampResult220 = clamp( temp_output_221_0 , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
			o.Alpha = clampResult220.r;
			o.Normal = o.Normal + 0.00001 * i.screenPos * i.worldPos;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustom keepalpha finalcolor:RefractionF fullforwardshadows exclude_path:deferred 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			AlphaToMask Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.screenPos = ComputeScreenPos( o.pos );
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.screenPos = IN.screenPos;
				SurfaceOutputStandardCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandardCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}
/*ASEBEGIN
Version=18900
300.8;583.2;1288;646;391.0512;151.2519;1.589878;True;False
Node;AmplifyShaderEditor.WorldSpaceLightPos;202;-890.8987,996.8447;Inherit;False;0;3;FLOAT4;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;225;-984.3615,-651.3462;Inherit;True;Property;_SurficeRougness;Surfice Rougness;24;0;Create;True;0;0;0;False;0;False;-1;None;af5f46dfacb91c749be3c34d42a00dfe;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;223;-1008.098,71.95682;Inherit;True;Property;_Texture2;Texture 2;16;0;Create;True;0;0;0;False;0;False;-1;None;a68789ba50055df42a757c9a30ff944a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;115;-1019.227,680.1196;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;1;-1016.62,-207.8778;Inherit;True;Property;_Texture1;Texture 1;15;0;Create;True;0;0;0;False;0;False;-1;a68789ba50055df42a757c9a30ff944a;9403d6b62fc4d694ebf590d63f5c8ab5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;0,0;False;1;FLOAT2;1,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;241;-903.8822,-751.6789;Inherit;False;Property;_InnerOuterRoughnessPower;Inner-Outer Roughness Power;26;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;145;-990.3082,1954.506;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;258;-541.7799,2459.303;Inherit;False;Property;_FresnelPower;Fresnel Power;5;0;Create;True;0;0;0;False;0;False;1.69;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;147;-1054.071,2163.839;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;240;-523.2935,-630.6863;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0.02830189;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;256;-527.7799,2315.303;Inherit;False;Property;_FresnelBias;Fresnel Bias;4;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;224;-642.2164,-5.64037;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;257;-526.7799,2391.303;Inherit;False;Property;_FresnelScale;Fresnel Scale;3;0;Create;True;0;0;0;False;0;False;11.56;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;233;-978.6158,-462.0494;Inherit;False;Property;_InnerRoughnessPowerSunside;Inner Roughness Power Sunside;25;0;Create;True;0;0;0;False;0;False;0;0.005;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;116;-653.9618,871.6282;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;193;-614.4984,439.2033;Inherit;False;Constant;_Transperency;Transperency;22;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;232;-527.7888,-500.8398;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0.02830189;False;1;COLOR;0
Node;AmplifyShaderEditor.AbsOpNode;179;-384.7939,748.039;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;255;-255.5007,2276.199;Inherit;True;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;11.56;False;3;FLOAT;1.69;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;237;-400.973,33.71231;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;162;-417.9318,976.3575;Inherit;False;Property;_TextureGradientBias;Texture Gradient Bias;32;0;Create;True;0;0;0;False;0;False;0.4;-7.48;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;110;-186.6786,449.7059;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;252;-488.3187,1869.286;Inherit;False;Property;_FresnelColor2;Fresnel Color 2;1;0;Create;True;0;0;0;False;0;False;0,1,0.07791209,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;153;-78.19205,2156.887;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;159;-140.4934,874.3309;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;250;-492.3755,1677.719;Inherit;False;Property;_FresnelColor1;Fresnel Color 1;2;0;Create;True;0;0;0;False;0;False;0,0.1269569,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;235;-31.73333,-122.1166;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NegateNode;201;-627.3794,1436.374;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;207;-165.9331,77.0368;Inherit;False;Constant;_TranscluencyColor;Transcluency Color;30;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;39;-371.5318,611.7182;Inherit;False;Property;_InnerOpacity;Inner Opacity;19;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;196;-555.9149,1268.88;Inherit;False;Property;_GradientPower;Gradient Power;33;0;Create;True;0;0;0;False;0;False;1.33;0.42;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;199;-312.7984,1375.088;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;204;82.32256,254.0798;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;190;33.2732,1252.701;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;114;-27.3617,566.6783;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;152;46.70866,1901.75;Inherit;True;3;0;COLOR;3,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;221;190.4013,564.5345;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;253;355.7009,1919.937;Inherit;False;FresnelColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;209;209.3302,338.9382;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;185;-2463.662,2328.042;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;148;-722.4987,2030.942;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;151;-282.5163,2062.074;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;128;-1898.267,2682.921;Inherit;False;Property;_Float2;Float 2;30;0;Create;True;0;0;0;False;0;False;18.75;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;144;502.3378,759.9169;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;126;-936.1989,871.2938;Inherit;False;Property;_Float1;Float 1;27;0;Create;True;0;0;0;False;0;False;1.69;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;266;988.204,-213.6975;Inherit;False;Property;_OuterMetalic;Outer Metalic;21;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;268;310.4194,-708.8907;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;273;847.4773,-62.6022;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;263;1002.71,-363.7641;Inherit;False;Property;_OuterGlassSmoothnes;Outer Glass Smoothnes;20;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;265;567.9561,-290.7719;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceViewDirHlpNode;165;-2838.431,2594.898;Inherit;False;1;0;FLOAT4;0,0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;97;1195.518,484.8036;Inherit;False;Constant;_Float0;Float 0;9;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;167;-2400.897,2482.575;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;150;-532.2109,2043.657;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;149;-547.8287,2224.97;Inherit;False;Property;_FresnelGradientSubstract;Fresnel Gradient Substract;31;0;Create;True;0;0;0;False;0;False;0.71;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;169;-2056.808,2456.943;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;262;575.1573,-414.9082;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;166;-2575.91,2588.367;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;168;-2243.874,2471.283;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;210;696.3536,385.8926;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;272;-28.65379,-822.7776;Inherit;False;Property;_InnerGlassFresnelColoring;Inner Glass Fresnel Coloring;7;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;129;-738.9097,742.6786;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;119;233.2689,766.9315;Inherit;True;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;100;-352.2306,-888.6755;Inherit;False;Property;_InnerGlassColor;Inner Glass Color;0;0;Create;True;0;0;0;False;0;False;0,0,0,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;247;972.8054,-139.0963;Inherit;False;Property;_OuterOpacity;Outer Opacity;22;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;146;-819.2166,2224.993;Inherit;False;Property;_FresnelGradientMultiplayer;Fresnel Gradient Multiplayer;29;0;Create;True;0;0;0;False;0;False;1.65;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;275;-456.9433,2739.973;Inherit;False;Constant;_3;3;41;0;Create;True;0;0;0;False;0;False;8.12;8.12;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;259;246.2617,-523.821;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;38;1017.609,-440.1166;Inherit;False;Property;_InnerGlassSmoothnes;Inner Glass Smoothnes;17;0;Create;True;0;0;0;False;0;False;1;0.838;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;245;561.4063,-159.9986;Inherit;False;3;0;COLOR;1,1,1,0;False;1;COLOR;1,1,1,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;220;597.3956,541.9232;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;243;163.5791,-355.497;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;282;1373.723,23.96679;Inherit;False;278;OuterFresnel;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;281;1885.803,-660.3422;Inherit;False;Property;_FrasnelOuterRim;Frasnel Outer Rim;6;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;267;-240.1053,2531.39;Inherit;True;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0.36;False;3;FLOAT;7.54;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;274;1229.25,-8.179016;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;277;-460.9433,2665.973;Inherit;False;Constant;_2;2;40;0;Create;True;0;0;0;False;0;False;-96.1;-96.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;176;-1782.689,2438.016;Inherit;True;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;280;1749.963,-406.7086;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;279;1589.39,-260.2227;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;244;583.3983,-542.4271;Inherit;False;3;0;COLOR;1,0.08962262,0.08962262,0;False;1;COLOR;0,0.3077016,1,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;254;-249.296,-646.1469;Inherit;False;253;FresnelColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;278;162.2274,2568.979;Inherit;False;OuterFresnel;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;184;-2865.944,2445.557;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;44;997.2408,-293.0655;Inherit;False;Property;_InnerMetalic;Inner Metalic;18;0;Create;True;0;0;0;False;0;False;0;0.11;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;270;105.8557,36.16102;Inherit;False;Property;_OuterTexturePower;Outer Texture Power;28;0;Create;True;0;0;0;False;0;False;11.16;11.16;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;271;-103.2341,-336.7416;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;269;223.6946,-85.58432;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;276;-456.0993,2592.263;Inherit;False;Constant;_1;1;38;0;Create;True;0;0;0;False;0;False;25.4;25.4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;246;518.1753,98.79181;Inherit;False;3;0;COLOR;1,0.08962262,0.08962262,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;909.5775,291.0664;Half;False;True;-1;2;;0;0;Standard;Isida/CanopyGlass;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;3;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;True;Transparent;;Transparent;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;0;4;10;25;False;0.5;True;3;1;False;-1;10;False;-1;0;4;False;-1;1;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;23;8;34;-1;0;True;0;0;False;-1;-1;0;False;-1;0;0;0;False;0;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;240;0;225;0
WireConnection;240;1;241;0
WireConnection;224;0;223;0
WireConnection;224;1;1;0
WireConnection;116;0;115;0
WireConnection;116;1;202;1
WireConnection;232;0;225;0
WireConnection;232;1;233;0
WireConnection;179;0;116;0
WireConnection;255;0;145;0
WireConnection;255;4;147;0
WireConnection;255;1;256;0
WireConnection;255;2;257;0
WireConnection;255;3;258;0
WireConnection;237;0;240;0
WireConnection;237;1;224;0
WireConnection;110;0;237;0
WireConnection;110;1;193;0
WireConnection;153;0;255;0
WireConnection;159;0;179;0
WireConnection;159;1;162;0
WireConnection;235;0;232;0
WireConnection;235;1;224;0
WireConnection;201;0;116;0
WireConnection;199;0;201;0
WireConnection;199;1;196;0
WireConnection;204;0;235;0
WireConnection;204;1;207;0
WireConnection;190;0;159;0
WireConnection;190;1;196;0
WireConnection;114;0;110;0
WireConnection;114;1;39;0
WireConnection;152;0;250;0
WireConnection;152;1;252;0
WireConnection;152;2;153;0
WireConnection;221;0;114;0
WireConnection;221;1;190;0
WireConnection;253;0;152;0
WireConnection;209;0;204;0
WireConnection;209;1;199;0
WireConnection;148;0;145;0
WireConnection;148;1;146;0
WireConnection;151;0;150;0
WireConnection;151;1;149;0
WireConnection;144;0;119;0
WireConnection;268;0;272;0
WireConnection;268;1;237;0
WireConnection;265;0;44;0
WireConnection;265;1;266;0
WireConnection;265;2;243;0
WireConnection;167;0;184;0
WireConnection;167;1;166;0
WireConnection;150;0;148;0
WireConnection;150;1;147;0
WireConnection;169;0;185;0
WireConnection;169;1;168;0
WireConnection;262;0;38;0
WireConnection;262;1;281;0
WireConnection;262;2;243;0
WireConnection;166;0;185;0
WireConnection;168;0;167;0
WireConnection;210;0;209;0
WireConnection;272;1;100;0
WireConnection;272;0;254;0
WireConnection;129;0;115;0
WireConnection;129;1;126;0
WireConnection;119;2;179;0
WireConnection;259;0;254;0
WireConnection;259;1;237;0
WireConnection;245;0;221;0
WireConnection;245;1;274;0
WireConnection;245;2;243;0
WireConnection;220;0;221;0
WireConnection;281;1;263;0
WireConnection;281;0;280;0
WireConnection;267;0;145;0
WireConnection;267;4;147;0
WireConnection;267;1;276;0
WireConnection;267;2;277;0
WireConnection;267;3;275;0
WireConnection;274;0;247;0
WireConnection;274;1;269;0
WireConnection;176;0;169;0
WireConnection;176;1;128;0
WireConnection;280;0;279;0
WireConnection;279;0;282;0
WireConnection;279;1;263;0
WireConnection;244;0;268;0
WireConnection;244;1;259;0
WireConnection;244;2;243;0
WireConnection;278;0;267;0
WireConnection;271;0;240;0
WireConnection;271;1;224;0
WireConnection;269;0;271;0
WireConnection;269;1;270;0
WireConnection;246;0;209;0
WireConnection;246;2;243;0
WireConnection;0;0;254;0
WireConnection;0;3;44;0
WireConnection;0;4;38;0
WireConnection;0;7;210;0
WireConnection;0;8;97;0
WireConnection;0;9;220;0
ASEEND*/
//CHKSM=0EE391477F06938669E80DCD66B5C8A28CAB6706