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
        #pragma surface surf Lambert noambient // ����Ʈ ������ ���� �� ȯ�汤 ���� ����

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir; // �� ���ؽ� -> ī�޶� ������ �交�͸� ����ü�κ��� ������ ����.
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            // o.Albedo = c.rgb; // ������ ������ ������ Ȯ���ϱ� ���� Albedo �� ��� ����.
            float rim = saturate(dot(o.Normal, IN.viewDir)); // ���������� -1 ~ 1 ������ ���� �����ϹǷ�, �������� �����ϱ� ���� 0 �Ʒ� ���� ���� �߶������ saturate() �Լ� ���. (�������� ����� Albedo�� ���� �� ���� ����� ����.)
            o.Emission = pow(1 - rim, 3); // 1 - rim ���� �������� �� (�׷��� �����ڸ��� ��� ����), ��� ���� ������ ���̱� ���� ������ ��Ⱚ �׷����� �������� 3���� �׷����� �ٲ������ν�, Ư�� �������� �����ڰ��� Ȯ ��������� ��.
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
