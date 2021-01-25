Shader "Custom/hologram"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		_EdgeColor("EdgeColor", Color) = (0,1,0,1)
		_scanDistortTex("Scan Distortion (Packed Map)", 2D) = "white" {}
		_ScanlineSize ("Scanline Size", Range(0,1)) = 0.5
		_ScanSpeed("Scanline Speed", Range(0,1)) = 0.5
		_DistortSpeed("Distortion Speed", Range(0,1)) = 0.5
		_DistortStrength("Distortion Strength", Range(0,20)) = 5
		_Emissive("Glow Strength", Range(0,5)) = 1
		_Bias("Bias (Fresnel)", Range(0,1)) = 0.5
		_Scale("Scale (Fresnel)", Range(0,1)) = 0.5
		_Power("Power (Fresnel)", Range(0,4)) = 2
    }	
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
        LOD 200
		
		Pass
		{
		CGPROGRAM
		#pragma vertex vertShader
		#pragma fragment fragShader
		#include "UnityCG.cginc"
		sampler2D _scanDistortTex;
		float _Bias;
		float _Scale;
		float _Power;
		float _DistortSpeed;
		float _DistortStrength;
		float4 _Color;
		float4 _EdgeColor;
		float _ScanlineSize;
		float _ScanSpeed;
		float _Emissive;

		// STRUCTS
		struct vertInput {
			float3 normal	: NORMAL;
			float4 vertex	: POSITION;
			float2 uv		: TEXCOORD0;
		};

		struct vert2frag {
			float2 uv				: TEXCOORD0;
			float4 pos				: SV_POSITION;
			float4 worldPos			: TEXCOORD1;
			float fresnel			: TEXCOORD2;
			float3 normal			: TEXCOORD3;
		};

		struct fragOutput {
			fixed4 color : SV_Target;
		};

		// FUNCTIONS
		float random(float2 uv)
		{
			return frac(sin(dot(uv, float2(12.98989, 78.233)))*4375.23094);
		}

		// SHADER PROGRAMS
		vert2frag vertShader(vertInput input)
		{
			vert2frag output;
			float4 clip_pos;
			float2 uvs = input.uv;
			
			clip_pos = UnityObjectToClipPos(input.vertex); //now a position in clip space. 
			
			// vertex displacement attempt
			float offset;
			float2 screenspace = clip_pos.xy;
			float v_offset = _Time * _DistortSpeed;
			float2 uv_per_time = screenspace.xy / 100;
			uv_per_time.y += v_offset;
			input.vertex.y += tex2Dlod(_scanDistortTex, float4(uv_per_time, 1, 0)).g*_DistortStrength;
			output.pos = UnityObjectToClipPos(input.vertex);
			
			// uv, worldPosition, normal
			output.uv = input.uv;
			output.worldPos = mul(unity_ObjectToWorld, input.vertex);
			output.normal = UnityObjectToWorldNormal(input.normal);

			// fresnel
			float3 view_vec = normalize(output.worldPos - _WorldSpaceCameraPos.xyz);
			output.fresnel = _Bias + _Scale * pow(1.0 + dot(view_vec, output.normal), _Power);
			return output;
		}


		fragOutput fragShader(vert2frag input)
		{
			fragOutput output;
			float2 time_2 = (_Time, _SinTime);
			float random_per_frame = random(time_2);
			float2 uv_per_time;
			float v_offset;
			v_offset = _Time * _ScanSpeed;
			uv_per_time = input.pos.xy*_ScanlineSize/100;
			uv_per_time.y += v_offset;
			output.color.rgba = _Color;
			output.color *= tex2D(_scanDistortTex, uv_per_time).r+.5;
			output.color = lerp(output.color.rgba, _EdgeColor.rgba,  input.fresnel);
			output.color *= max(random_per_frame, 0.8);
			output.color += _Emissive;

			return output;
		}

		ENDCG
		}
    }
    FallBack "Diffuse"
}
