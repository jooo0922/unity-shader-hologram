Shader "Custom/holo"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        // 홀로그램 두께 및 색상을 인터페이스로 받아서 조절할 수 있도록 프로퍼티 추가함.
        _RimColor ("RimColor", Color) = (0, 1, 0, 1) 
        _RimPower ("RimPower", Range(1, 10)) = 3 
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"} // 구조체 알파채널 적용에 필요한 설정 추가

        CGPROGRAM

        // 램버트 라이팅 적용 및 환경광 영향 제거
        #pragma surface surf Lambert noambient alpha:fade // 구조체 알파채널 적용에 필요한 설정 추가

        sampler2D _MainTex;
        float4 _RimColor;
        float _RimPower;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir; // 각 버텍스 -> 카메라 방향의 뷰벡터를 구조체로부터 가져올 것임.
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            // o.Albedo = c.rgb; // 순수한 프레넬 조명값을 확인하기 위해 Albedo 는 잠시 꺼둠.

            o.Emission = _RimColor.rgb; // 알파채널에는 rim값을 넣어주고, 구조체의 Emission 에는 홀로그램 색상값을 넣어주도록 함. (만약 알파채널에 rim 값을 안넣어주면 모델 전체 실루엣이 Emission 컬러로 찍히겠지)  

            float rim = saturate(dot(o.Normal, IN.viewDir)); // 내적연산은 -1 ~ 1 사이의 값을 리턴하므로, 음수값을 제거하기 위해 0 아래 값을 전부 잘라버리는 saturate() 함수 사용. (음수값이 없어야 Albedo와 더할 때 색이 제대로 나옴.)
            // o.Emission = pow(1 - rim, 3); // 1 - rim 으로 뒤집어준 뒤 (그래야 가장자리가 밝게 나옴), 밝게 나온 영역을 줄이기 위해 프레넬 밝기값 그래프를 선형에서 3제곱 그래프로 바꿔줌으로써, 특정 구간부터 프레넬값이 확 밝아지도록 함.
            
            // rim 값을 계산한 뒤, 구조체의 알파채널 값에 할당하면, 가장자리 부분만 투명도가 1에 가까워지므로, 홀로그램 효과가 적용됨.
            rim = pow(1 - rim, _RimPower);
            o.Alpha = rim;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
