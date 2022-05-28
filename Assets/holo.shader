Shader "Custom/holo"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert noambient // 램버트 라이팅 적용 및 환경광 영향 제거

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir; // 각 버텍스 -> 카메라 방향의 뷰벡터를 구조체로부터 가져올 것임.
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            // o.Albedo = c.rgb; // 순수한 프레넬 조명값을 확인하기 위해 Albedo 는 잠시 꺼둠.
            float rim = saturate(dot(o.Normal, IN.viewDir)); // 내적연산은 -1 ~ 1 사이의 값을 리턴하므로, 음수값을 제거하기 위해 0 아래 값을 전부 잘라버리는 saturate() 함수 사용. (음수값이 없어야 Albedo와 더할 때 색이 제대로 나옴.)
            o.Emission = pow(1 - rim, 3); // 1 - rim 으로 뒤집어준 뒤 (그래야 가장자리가 밝게 나옴), 밝게 나온 영역을 줄이기 위해 프레넬 밝기값 그래프를 선형에서 3제곱 그래프로 바꿔줌으로써, 특정 구간부터 프레넬값이 확 밝아지도록 함.
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
