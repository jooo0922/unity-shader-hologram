Shader "Custom/holo"
{
    Properties
    {
        // 노말맵을 받기 위해서 프로퍼티 추가함.
        _BumpMap ("NormalMap", 2D) = "bump" {}

        // 홀로그램 두께 및 색상을 인터페이스로 받아서 조절할 수 있도록 프로퍼티 추가함.
        _RimColor("RimColor", Color) = (0, 1, 0, 1)
        _RimPower("RimPower", Range(1, 10)) = 3

        // 홀로그램이 깜빡이는 속도를 인터페이스로 받아서 조절할 수 있도록 프로퍼티 추가함.
        _RimSpeed("RimSpeed", Range(1, 10)) = 3

        // 홀로그램 세로줄 두께 및 간격을 인터페이스로 받아서 조절할 수 있도록 프로퍼티 추가함.
        _LinePower("LinePower", Range(1, 30)) = 30
        _LineInterval("LineInterval", Range(1, 10)) = 3
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"} // 구조체 알파채널 적용에 필요한 설정 추가

        CGPROGRAM

        // 환경광 영향 제거
        // 더 이상 램버트 조명이 필요 없음. 투명도에 o.Emission 만 더해주면 끝이니까 알파채널만 리턴해주는 커스텀 라이팅은 nolight 를 만들어 사용하도록 함.
        #pragma surface surf nolight noambient alpha:fade // 구조체 알파채널 적용에 필요한 설정 추가

        sampler2D _BumpMap;
        float4 _RimColor;
        float _RimPower;
        float _RimSpeed;
        float _LinePower;
        float _LineInterval;

        struct Input
        {
            float2 uv_BumpMap; // 인터페이스로 받아온 노말맵 텍스쳐를 적용하기 위한 버텍스의 텍스쳐 uv 좌표를 구조체로부터 가져올 것임.
            float3 viewDir; // 각 버텍스 -> 카메라 방향의 뷰벡터를 구조체로부터 가져올 것임.
            float3 worldPos; // 줄무늬가 위로 올라가는 효과를 구현하는 데 필요한 각 버텍스의 월드좌표를 구조체로부터 가져올 것임. (Input 구조체에서 가져올 수 있는 각 버텍스의 프로퍼티는 p.342 참고)
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)); // UnpackNormal() 함수는 변환된 노말맵 텍스쳐 형식인 DXTnm 에서 샘플링해온 텍셀값 float4를 인자로 받아 float3 를 리턴해줌.
            // o.Albedo = c.rgb; // 순수한 프레넬 조명값을 확인하기 위해 Albedo 는 잠시 꺼둠.

            o.Emission = _RimColor; // 알파채널에는 rim값을 넣어주고, 구조체의 Emission 에는 홀로그램 색상값을 넣어주도록 함. (만약 알파채널에 rim 값을 안넣어주면 모델 전체 실루엣이 Emission 컬러로 찍히겠지)  

            // 전역좌표값에 따른 색상변화를 관찰하기 위해 o.Emission 에다가 넣어봄.
            // IN.worldPos.g 는 말그대로 전역공간 y좌표값이므로, 위로 올라갈수록 값이 밝아지게 됨.
            // 이 값을 frac() 내장함수를 이용해서, 소수점 부분만 떼어서 리턴해주도록 하면, 아무리 g값이 커지더라도 0.0 ~ 0.999... 사이의 값들만 반복해서 리턴해줌. -> 결과적으로 검정색 ~ 흰색의 그라데이션이 반복되는 효과를 낳음.
            // o.Emission = frac(IN.worldPos.g); 

            // pow()로 위의 값을 30제곱해서 흰색 부분을 좁혀주고, (Fresnel 에서 배웠음)
            // 흰색이 나타나는 간격을 줄이기 위해 전역좌표 y값인 IN.worldPos.g 에 3배를 곱해줌. -> 이렇게 해주면, 소수 부분의 값들에 3배가 곱해짐에 따라 0 ~ 0.999 로의 증가가 더 빨라지겠지. 
            // 왜냐? 0.3만 되어도 3배로 곱하면 벌써 0.9 에 도달하잖아. 
            // 그니까 사실상 소수부분이 0.0 ~ 0.333... 단위로 그라디언트가 반복되는 셈.
            // o.Emission = pow(frac(IN.worldPos.g * 3), 30);

            // 위에서 계산해 준 값에다 _Time 내장변수를 빼주면 라인이 올라가고, 더해주면 라인이 내려감.
            // 이게 왜 이러냐면, _Time.y 를 빼주지 않은 상태의 셰이더를 적용한 뒤에, 유니티에서 화살표로 모델의 y좌표를 직접 움직여보면 됨. 
            // 모델을 위로 움직이면 라인이 아래로 내려가는 것처럼 보이고, 모델을 아래로 움직이면 라인이 위로 올라가는 것처럼 보임.
            // 그러니까 여기서도 각 버텍스의 y좌표값에 _Time.y 를 빼줘야 라인이 위로 올라가는 것처럼 보이겠지!
            // o.Emission = pow(frac(IN.worldPos.g * 3 - _Time.y), 30); // 이제 이 값을 Emission 이 아니라 Alpha 채널에 더해주도록 함. -> 흰색 라인 부분만 투명도가 1에 가깝게 찍혀서 화면에 보이겠지

            float rim = saturate(dot(o.Normal, IN.viewDir)); // 내적연산은 -1 ~ 1 사이의 값을 리턴하므로, 음수값을 제거하기 위해 0 아래 값을 전부 잘라버리는 saturate() 함수 사용. (음수값이 없어야 Albedo와 더할 때 색이 제대로 나옴.)
            
            // 1 - rim 으로 뒤집어준 뒤 (그래야 가장자리가 밝게 나옴), 밝게 나온 영역을 줄이기 위해 프레넬 밝기값 그래프를 선형에서 n제곱 그래프로 바꿔줌으로써, 특정 구간부터 프레넬값이 확 밝아지도록 함.
            rim = pow(1 - rim, _RimPower);
            
            // rim 값을 계산한 뒤, 구조체의 알파채널 값에 할당하면, 가장자리 부분만 투명도가 1에 가까워지므로, 홀로그램 효과가 적용됨.
            // o.Alpha = rim;
            
            // 홀로그램에 애니메이션을 적용하기
            // o.Alpha = rim * sin(_Time.y); // _Time.y 내장변수를 sin 함수로 돌려서 -1 ~ 1 사이의 값을 리턴받아 곱해줌. 그런데 이대로 곱하면, 알파채널이 -1 ~ 0 사이, 즉 음수값이 곱해져서 깜빡임 속도도 느리고, 현재 Emission 과 반대색상이 나오는 기이한 현상이 발생함.
            // o.Alpha = rim * (sin(_Time.y) * 0.5 + 0.5); // 첫 번째 해결방법은, 하프램버트에서 사용했던 공식을 이용해서 -1 ~ 1 사이의 값을 0 ~ 1 사이의 값으로 매핑하는 방법이 있음. p.341 두 번째 그래프 참고.
            // o.Alpha = rim * abs(sin(_Time.y )); // 두 번째 해결항법은, abs() 내장함수로 음수값을 모두 양수화시키는 방법이 있음. -> 이러면 깜빡이는 느낌이 통통튀는 느낌으로 달라지기도 함. p.341 세 번째 그래프 참고.
            // o.Alpha = rim * (sin(_Time.y * _RimSpeed) * 0.5 + 0.5); // 첫 번째 방법에서 깜빡이는 속도를 조절할 수 있도록 인터페이스에서 받아온 값을 _Time 내장변수에 곱해줌.
            
            // sin() 함수로 깜빡이는 애니메이션을 만드는 공식을 sinTime 이라는 변수에 따로 빼놓음.
            float sinTime = sin(_Time.y * _RimSpeed) * 0.5 + 0.5;
            
            // 세로줄 인터벌 투명도에 0.2 정도를 곱해서 가장자리 투명도보다는 튀지 않게, 약간 흐릿하게 처리해 줌.
            float horizon = pow(frac(IN.worldPos.g * _LineInterval - _Time.y), _LinePower) * 0.2;

            // 가장자리 투명도만 1에 가깝게 해주는 rim 값에 세로줄 인터벌 투명도를 1에 가깝게 해주는 horizon 값을 더해준 뒤,
            // 깜빡임 애니메이션에 사용했던 공식으로 계산된 값 sinTime 을 곱해줌.
            o.Alpha = (rim + horizon) * sinTime;
        }

        // 투명도에 o.Emission 만 더해주면 끝이니까 알파채널만 리턴해주는 커스텀 라이팅은 nolight 를 만들어 사용하도록 함.
        float4 Lightingnolight(SurfaceOutput s, float3 lightDir, float atten) {
            return float4(0, 0, 0, s.Alpha); // 다른 값은 리턴하지 않고, surf 함수에서 계산한 o 구조체 알파채널인 o.Alpha만 가져와서 투명도로 할당해서 리턴함. -> 이렇게 하면 o.Emission 이랑 더해져서 최종 색상값이 나올거임. 
        }
        ENDCG
    }

    // 원래 FallBack 은 셰이더 연산 실패 시 처리할 대체 셰이더 이름을 적는 곳이지만,
    // 그림자 연산에 영향을 끼치기도 함. 그래서 홀로그램은 그림자가 필요없는 이펙트이므로,
    // Transparent/Diffuse 를 넣어줘서 그림자를 생성하지 않도록 한 것임.
    FallBack "Transparent/Diffuse"
}
