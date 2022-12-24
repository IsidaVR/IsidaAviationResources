// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Isida/CloudShadows"
{
	Properties
	{
		_Tint("Tint", Color) = (0,0,0,0)
		_Density("Density", Range( 0 , 1)) = 0.07354859
		_Softness("Softness", Range( 0 , 1)) = 0.8224365
		_TextureSample0("Texture Sample 0", 2D) = "white" {}
		_Scale("Scale", Float) = 0
		_ShadowStrenght("Shadow Strenght", Float) = 0
		_Speed("Speed", Vector) = (1,0,0,0)

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend One OneMinusSrcAlpha
		AlphaToMask Off
		Cull Front
		ColorMask RGBA
		ZWrite Off
		ZTest Always
		
		
		
		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="Forwardbase" }
			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform float4 _Tint;
			UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
			uniform float4 _CameraDepthTexture_TexelSize;
			uniform sampler2D _CameraNormalsTexture;
			uniform float _ShadowStrenght;
			uniform float _Density;
			uniform float _Softness;
			uniform sampler2D _TextureSample0;
			uniform float2 _Speed;
			uniform float _Scale;
			float2 UnStereo( float2 UV )
			{
				#if UNITY_SINGLE_PASS_STEREO
				float4 scaleOffset = unity_StereoScaleOffset[ unity_StereoEyeIndex ];
				UV.xy = (UV.xy - scaleOffset.zw) / scaleOffset.xy;
				#endif
				return UV;
			}
			
			float3 InvertDepthDir72_g4( float3 In )
			{
				float3 result = In;
				#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301
				result *= float3(1,1,-1);
				#endif
				return result;
			}
			

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord1 = screenPos;
				
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float4 screenPos = i.ase_texcoord1;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 UV22_g5 = ase_screenPosNorm.xy;
				float2 localUnStereo22_g5 = UnStereo( UV22_g5 );
				float2 break64_g4 = localUnStereo22_g5;
				float clampDepth69_g4 = SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy );
				#ifdef UNITY_REVERSED_Z
				float staticSwitch38_g4 = ( 1.0 - clampDepth69_g4 );
				#else
				float staticSwitch38_g4 = clampDepth69_g4;
				#endif
				float3 appendResult39_g4 = (float3(break64_g4.x , break64_g4.y , staticSwitch38_g4));
				float4 appendResult42_g4 = (float4((appendResult39_g4*2.0 + -1.0) , 1.0));
				float4 temp_output_43_0_g4 = mul( unity_CameraInvProjection, appendResult42_g4 );
				float3 temp_output_46_0_g4 = ( (temp_output_43_0_g4).xyz / (temp_output_43_0_g4).w );
				float3 In72_g4 = temp_output_46_0_g4;
				float3 localInvertDepthDir72_g4 = InvertDepthDir72_g4( In72_g4 );
				float4 appendResult49_g4 = (float4(localInvertDepthDir72_g4 , 1.0));
				float4 temp_output_5_0 = mul( unity_CameraToWorld, appendResult49_g4 );
				float3 worldToObj10 = mul( unity_WorldToObject, float4( temp_output_5_0.xyz, 1 ) ).xyz;
				float smoothstepResult85 = smoothstep( 0.5 , 1.0 , ( 1.0 - length( ( worldToObj10 * 0.3 ) ) ));
				float3 worldToObjDir52 = mul( unity_WorldToObject, float4( (tex2D( _CameraNormalsTexture, ase_screenPosNorm.xy )*2.0 + -1.0).rgb, 0 ) ).xyz;
				float3 ase_objectScale = float3( length( unity_ObjectToWorld[ 0 ].xyz ), length( unity_ObjectToWorld[ 1 ].xyz ), length( unity_ObjectToWorld[ 2 ].xyz ) );
				float smoothstepResult67 = smoothstep( 0.0 , 1.0 , (( worldToObjDir52 * ase_objectScale )).y);
				float temp_output_150_0 = (-0.0 + (_Density - 0.0) * (1.0 - -0.0) / (1.0 - 0.0));
				float4 temp_cast_4 = (temp_output_150_0).xxxx;
				float4 temp_cast_5 = (( temp_output_150_0 + _Softness )).xxxx;
				float3 worldToObjDir57 = mul( unity_WorldToObject, float4( temp_output_5_0.xyz, 0 ) ).xyz;
				float2 temp_output_11_0 = ( (( worldToObjDir57 * _Scale )).xz + float2( 1,1 ) );
				float2 panner139 = ( _Time.y * _Speed + temp_output_11_0);
				float4 smoothstepResult152 = smoothstep( temp_cast_4 , temp_cast_5 , tex2D( _TextureSample0, panner139 ));
				float4 temp_output_28_0 = ( smoothstepResult85 * ( ( saturate( smoothstepResult67 ) + _ShadowStrenght ) * smoothstepResult152 ) );
				float4 appendResult37 = (float4((( _Tint * temp_output_28_0 )).rgb , temp_output_28_0.r));
				
				
				finalColor = appendResult37;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18900
412.8;251.2;1288;787;69.93488;2026.156;2.334151;True;False
Node;AmplifyShaderEditor.CommentaryNode;80;-386.9202,126.2948;Inherit;False;1953;389;Comment;9;29;67;16;55;52;2;3;4;54;Projection mask from local Y normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;4;-336.92,176.2948;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;86;28.70787,-559.1005;Inherit;False;1291;453;Comment;11;57;59;58;9;12;11;20;27;56;136;137;Caustics projection;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;5;-400,-880;Inherit;False;Reconstruct World Position From Depth;-1;;4;e7094bcbcc80eb140b2a3dbe6a861de8;0;0;1;FLOAT4;0
Node;AmplifyShaderEditor.SamplerNode;3;-96.91968,176.2948;Inherit;True;Global;_CameraNormalsTexture;_CameraNormalsTexture;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;2;239.0809,176.2948;Inherit;False;3;0;COLOR;0,0,0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;137;59.70129,-182.2944;Inherit;False;Property;_Scale;Scale;8;0;Create;True;0;0;0;False;0;False;0;2.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;57;78.70789,-509.1005;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformDirectionNode;52;511.0801,176.2948;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;58;366.7079,-509.1005;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ObjectScaleNode;54;559.0801,336.2949;Inherit;False;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;94;396.3164,-1134.76;Inherit;False;1066;234;Comment;5;10;48;82;83;85;Circle;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;12;615.7079,-418.1005;Inherit;False;Constant;_Vector0;Vector 0;4;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;55;783.0802,176.2948;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;9;542.7079,-509.1005;Inherit;False;True;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NegateNode;147;667.9639,-1447.184;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;148;391.963,-1549.526;Inherit;False;Property;_Density;Density;3;0;Create;True;0;0;0;False;0;False;0.07354859;0.329;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;140;747.8826,-773.3583;Inherit;False;Property;_Speed;Speed;11;0;Create;True;0;0;0;False;0;False;1,0;0.02,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleTimeNode;141;761.228,-621.9145;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;11;813.7079,-497.1005;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ComponentMaskNode;16;975.0798,176.2948;Inherit;False;False;True;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;10;436.082,-1086.149;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TFHCRemapNode;150;854.9287,-1529.545;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;67;1215.079,176.2948;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;149;401.388,-1381.615;Inherit;False;Property;_Softness;Softness;5;0;Create;True;0;0;0;False;0;False;0.8224365;0.208;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;48;742.1761,-1073.21;Inherit;False;0.3;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PannerNode;139;1034.936,-734.5815;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;138;1249.739,-35.38712;Inherit;False;Property;_ShadowStrenght;Shadow Strenght;9;0;Create;True;0;0;0;False;0;False;0;0.36;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;29;1391.079,176.2948;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;151;1119.917,-1390.009;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;133;1266.068,-762.2606;Inherit;True;Property;_TextureSample0;Texture Sample 0;7;0;Create;True;0;0;0;False;0;False;-1;None;cd460ee4ac5c1e746b7a734cc7cc64dd;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LengthOpNode;82;895.8992,-1078.947;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;83;1034.964,-1084.549;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;152;1599.282,-1292.385;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;132;1443.639,-195.4618;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;85;1244.425,-1088.937;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;1668.307,-363.659;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;1808,-448;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;38;1787.527,-749.5345;Inherit;False;Property;_Tint;Tint;1;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0.04321036,0.1037734,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;77;2048,-512;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SwizzleNode;130;2208,-512;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;129;-216.3705,1363.031;Inherit;False;1905;860;Uses different texture (requires camera script to activate it);15;117;112;110;108;111;109;113;96;99;106;114;126;127;128;119;Projection mask from local Y normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;93;-1296.566,1297.404;Inherit;False;923.3894;307.4255;Comment;4;90;89;88;87;Square;1,1,1,1;0;0
Node;AmplifyShaderEditor.VoronoiNode;20;1033.329,-448.5176;Inherit;True;1;0;1;0;1;False;10;False;True;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;5;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT;1;FLOAT2;2
Node;AmplifyShaderEditor.ScreenPosInputsNode;119;-168.3702,1427.031;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VectorFromMatrixNode;110;167.6297,1843.031;Inherit;False;Row;1;1;0;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ObjectScaleNode;59;46.20913,-358.503;Inherit;False;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;95;865.7482,-87.84583;Inherit;False;Property;_Smoothness;Smoothness;6;0;Create;True;0;0;0;False;0;False;0.82;0.3;0;0.3;0;1;FLOAT;0
Node;AmplifyShaderEditor.VectorFromMatrixNode;112;167.6297,2019.031;Inherit;False;Row;2;1;0;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.AbsOpNode;90;-1246.566,1351.83;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;37;2384,-464;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SmoothstepOpNode;127;1335.63,1411.031;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;87;-608.1765,1347.404;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;143;493.1427,-748.4666;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;126;1095.63,1411.031;Inherit;False;False;True;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;136;256.679,-360.85;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;100,100,100;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransposeMVMatrix;117;-168.3702,1667.031;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.VectorFromMatrixNode;108;167.6297,1667.031;Inherit;False;Row;0;1;0;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;158;1996.896,-1065.295;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;27;814.7079,-333.1005;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;88;-817.5114,1347.93;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;128;1511.63,1411.031;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;111;359.6297,1843.031;Inherit;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.NormalizeNode;109;359.6297,1667.031;Inherit;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;114;919.6299,1411.031;Inherit;False;2;2;0;FLOAT3x3;0,0,0,1,1,1,1,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;113;359.6297,2019.031;Inherit;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.BreakToComponentsNode;89;-1071.216,1349.23;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleAddOpNode;146;520.8982,-900.5477;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;56;814.7079,-221.1005;Inherit;False;Property;_CausticsScale;Caustics Scale;2;0;Create;True;0;0;0;False;0;False;0;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.MatrixFromVectors;106;615.6298,1667.031;Inherit;False;FLOAT3x3;True;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3x3;0
Node;AmplifyShaderEditor.DecodeDepthNormalNode;99;471.6295,1411.031;Inherit;False;1;0;FLOAT4;0,0,0,0;False;2;FLOAT;0;FLOAT3;1
Node;AmplifyShaderEditor.RangedFloatNode;154;1639.089,-926.1;Inherit;False;Property;_Float1;Float 1;12;0;Create;True;0;0;0;False;0;False;0;1.08;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;96;103.6299,1411.031;Inherit;True;Global;_CameraDepthNormalsTexture;_CameraDepthNormalsTexture;4;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;153;2189.576,-725.511;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;142;208.9465,-858.4475;Inherit;False;Property;_DrawDistance;Draw Distance;10;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;2560,-464;Float;False;True;-1;2;ASEMaterialInspector;100;1;Isida/CloudShadows;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;3;1;False;-1;10;False;-1;0;5;False;-1;10;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;1;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;7;False;-1;True;False;0;False;-1;0;False;-1;True;2;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Forwardbase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;False;0
WireConnection;3;1;4;0
WireConnection;2;0;3;0
WireConnection;57;0;5;0
WireConnection;52;0;2;0
WireConnection;58;0;57;0
WireConnection;58;1;137;0
WireConnection;55;0;52;0
WireConnection;55;1;54;0
WireConnection;9;0;58;0
WireConnection;11;0;9;0
WireConnection;11;1;12;0
WireConnection;16;0;55;0
WireConnection;10;0;5;0
WireConnection;150;0;148;0
WireConnection;150;3;147;0
WireConnection;67;0;16;0
WireConnection;48;0;10;0
WireConnection;139;0;11;0
WireConnection;139;2;140;0
WireConnection;139;1;141;0
WireConnection;29;0;67;0
WireConnection;151;0;150;0
WireConnection;151;1;149;0
WireConnection;133;1;139;0
WireConnection;82;0;48;0
WireConnection;83;0;82;0
WireConnection;152;0;133;0
WireConnection;152;1;150;0
WireConnection;152;2;151;0
WireConnection;132;0;29;0
WireConnection;132;1;138;0
WireConnection;85;0;83;0
WireConnection;97;0;132;0
WireConnection;97;1;152;0
WireConnection;28;0;85;0
WireConnection;28;1;97;0
WireConnection;77;0;38;0
WireConnection;77;1;28;0
WireConnection;130;0;77;0
WireConnection;20;0;11;0
WireConnection;20;1;27;0
WireConnection;20;2;56;0
WireConnection;20;3;95;0
WireConnection;110;0;117;0
WireConnection;112;0;117;0
WireConnection;37;0;130;0
WireConnection;37;3;28;0
WireConnection;127;0;126;0
WireConnection;87;0;88;0
WireConnection;87;1;89;2
WireConnection;126;0;114;0
WireConnection;136;0;59;0
WireConnection;108;0;117;0
WireConnection;158;1;154;0
WireConnection;88;0;89;0
WireConnection;88;1;89;1
WireConnection;128;0;127;0
WireConnection;111;0;110;0
WireConnection;109;0;108;0
WireConnection;114;0;106;0
WireConnection;114;1;99;1
WireConnection;113;0;112;0
WireConnection;89;0;90;0
WireConnection;146;0;10;0
WireConnection;146;1;142;0
WireConnection;106;0;109;0
WireConnection;106;1;111;0
WireConnection;106;2;113;0
WireConnection;99;0;96;0
WireConnection;96;1;119;0
WireConnection;0;0;37;0
ASEEND*/
//CHKSM=1B0353B09EF860A89B50205EEDB32F510F125945