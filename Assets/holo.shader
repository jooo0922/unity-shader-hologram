Shader "Custom/holo"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        // 홀로그램 두께 및 색상을 인터페이스로 받아서 조절할 수 있도록 프로퍼티 추가함.
        _RimColor("RimColor", Color) = (0, 1, 0, 1)
        _RimPower("RimPower", Range(1, 10)) = 3

        // 홀로그램이 깜빡이는 속도를 인터페이스로 받아서 조절할 수 있도록 프로퍼티 추가함.
        _RimSpeed("RimSpeed", Range(1, 10)) = 3
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
        float _RimSpeed;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir; // 각 버텍스 -> 카메라 방향의 뷰벡터를 구조체로부터 가져올 것임.
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            // o.Albedo = c.rgb; // 순수한 프레넬 조명값을 확인하기 위해 Albedo 는 잠시 꺼둠.

            o.Emission = _RimColor; // 알파채널에는 rim값을 넣어주고, 구조체의 Emission 에는 홀로그램 색상값을 넣어주도록 함. (만약 알파채널에 rim 값을 안넣어주면 모델 전체 실루엣이 Emission 컬러로 찍히겠지)  

            float rim = saturate(dot(o.Normal, IN.viewDir)); // 내적연산은 -1 ~ 1 사이의 값을 리턴하므로, 음수값을 제거하기 위해 0 아래 값을 전부 잘라버리는 saturate() 함수 사용. (음수값이 없어야 Albedo와 더할 때 색이 제대로 나옴.)
            // o.Emission = pow(1 - rim, 3); // 1 - rim 으로 뒤집어준 뒤 (그래야 가장자리가 밝게 나옴), 밝게 나온 영역을 줄이기 위해 프레넬 밝기값 그래프를 선형에서 3제곱 그래프로 바꿔줌으로써, 특정 구간부터 프레넬값이 확 밝아지도록 함.
            
            // rim 값을 계산한 뒤, 구조체의 알파채널 값에 할당하면, 가장자리 부분만 투명도가 1에 가까워지므로, 홀로그램 효과가 적용됨.
            rim = pow(1 - rim, _RimPower);
            // o.Alpha = rim // 홀로그램 기본형
            
            // 홀로그램에 애니메이션을 적용하기
            // o.Alpha = rim * sin(_Time.y); // _Time.y 내장변수를 sin 함수로 돌려서 -1 ~ 1 사이의 값을 리턴받아 곱해줌. 그런데 이대로 곱하면, 알파채널이 -1 ~ 0 사이, 즉 음수값이 곱해져서 깜빡임 속도도 느리고, 현재 Emission 과 반대색상이 나오는 기이한 현상이 발생함.
            // o.Alpha = rim * (sin(_Time.y) * 0.5 + 0.5); // 첫 번째 해결방법은, 하프램버트에서 사용했던 공식을 이용해서 -1 ~ 1 사이의 값을 0 ~ 1 사이의 값으로 매핑하는 방법이 있음. p.341 두 번째 그래프 참고.
            // o.Alpha = rim * abs(sin(_Time.y )); // 두 번째 해결항법은, abs() 내장함수로 음수값을 모두 양수화시키는 방법이 있음. -> 이러면 깜빡이는 느낌이 통통튀는 느낌으로 달라지기도 함. p.341 세 번째 그래프 참고.
            o.Alpha = rim * (sin(_Time.y * _RimSpeed) * 0.5 + 0.5); // 첫 번째 방법에서 깜빡이는 속도를 조절할 수 있도록 인터페이스에서 받아온 값을 _Time 내장변수에 곱해줌.
        }
        ENDCG
    }
    FallBack "Diffuse"
}
