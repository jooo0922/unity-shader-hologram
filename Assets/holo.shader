Shader "Custom/holo"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        // Ȧ�α׷� �β� �� ������ �������̽��� �޾Ƽ� ������ �� �ֵ��� ������Ƽ �߰���.
        _RimColor ("RimColor", Color) = (0, 1, 0, 1) 
        _RimPower ("RimPower", Range(1, 10)) = 3 
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"} // ����ü ����ä�� ���뿡 �ʿ��� ���� �߰�

        CGPROGRAM

        // ����Ʈ ������ ���� �� ȯ�汤 ���� ����
        #pragma surface surf Lambert noambient alpha:fade // ����ü ����ä�� ���뿡 �ʿ��� ���� �߰�

        sampler2D _MainTex;
        float4 _RimColor;
        float _RimPower;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir; // �� ���ؽ� -> ī�޶� ������ �交�͸� ����ü�κ��� ������ ����.
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            // o.Albedo = c.rgb; // ������ ������ ������ Ȯ���ϱ� ���� Albedo �� ��� ����.

            o.Emission = _RimColor.rgb; // ����ä�ο��� rim���� �־��ְ�, ����ü�� Emission ���� Ȧ�α׷� ������ �־��ֵ��� ��. (���� ����ä�ο� rim ���� �ȳ־��ָ� �� ��ü �Ƿ翧�� Emission �÷��� ��������)  

            float rim = saturate(dot(o.Normal, IN.viewDir)); // ���������� -1 ~ 1 ������ ���� �����ϹǷ�, �������� �����ϱ� ���� 0 �Ʒ� ���� ���� �߶������ saturate() �Լ� ���. (�������� ����� Albedo�� ���� �� ���� ����� ����.)
            // o.Emission = pow(1 - rim, 3); // 1 - rim ���� �������� �� (�׷��� �����ڸ��� ��� ����), ��� ���� ������ ���̱� ���� ������ ��Ⱚ �׷����� �������� 3���� �׷����� �ٲ������ν�, Ư�� �������� �����ڰ��� Ȯ ��������� ��.
            
            // rim ���� ����� ��, ����ü�� ����ä�� ���� �Ҵ��ϸ�, �����ڸ� �κи� ������ 1�� ��������Ƿ�, Ȧ�α׷� ȿ���� �����.
            rim = pow(1 - rim, _RimPower);
            o.Alpha = rim;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
