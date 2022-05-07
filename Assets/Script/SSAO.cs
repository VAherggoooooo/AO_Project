using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[ImageEffectAllowedInSceneView]
public class SSAO : MonoBehaviour
{
    private Material mat_ao, mat_blur;
    private Camera cam { get { return GetComponent<Camera>(); } }

    [Range(1, 128)]public int sampleCount = 20;
    [Range(0f, 0.8f)]public float radius = 0.5f;
    [Range(0f, 10f)]public float rangeCheck = 0f;
    [Range(0f, 10f)]public float aoInt = 1f;
    [Range(0f, 3f)]public float blurRadius = 1f;
    [Range(0f, 1f)]public float bilaterFilterFactor = 0.1f;
    public Color aoColor = Color.black;
    public bool aoOnly = false;
    private void Awake()
    {
        mat_ao = GetMaterial("Hidden/SSAO");
        mat_blur = GetMaterial("Hidden/BilateralBlur");
    }


    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (mat_ao == null)
        {
            Graphics.Blit(source, destination);
        }
        else
        {
            SetMatData();

            if (aoOnly)
            {
                Graphics.Blit(source, destination, mat_ao, 0);
                return;
            }

            RenderTexture temp1 = RenderTexture.GetTemporary(Screen.width, Screen.height);
            Graphics.Blit(source, temp1, mat_ao, 0);
            mat_blur.SetTexture("_AOTex", temp1);

            RenderTexture temp2 = RenderTexture.GetTemporary(Screen.width / 2, Screen.height / 2);

            Graphics.Blit(temp1, temp2, mat_blur, 0);
            mat_blur.SetTexture("_AOTex", temp2);
            Graphics.Blit(temp2, temp1, mat_blur, 1);
            mat_blur.SetTexture("_AOTex", temp1);
            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);

            temp1 = RenderTexture.GetTemporary(Screen.width, Screen.height);
            temp2 = RenderTexture.GetTemporary(Screen.width, Screen.height);

            Graphics.Blit(temp1, temp2, mat_blur, 0);
            mat_blur.SetTexture("_AOTex", temp2);
            Graphics.Blit(temp2, temp1, mat_blur, 1);

            mat_ao.SetTexture("_AOTex", temp1);
            Graphics.Blit(temp1, destination, mat_ao, 1);

            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);

        }
    }

    private Material GetMaterial(string shaderName)
    {
        Shader s = Shader.Find(shaderName);
        if (s == null)
        {
            Debug.Log("shader not found");
            return null;
        }
        Material mat = new Material(s);
        mat.hideFlags = HideFlags.HideAndDontSave;
        return mat;
    }
    private void SetMatData()
    {
        Matrix4x4 vp_Matrix = cam.projectionMatrix * cam.worldToCameraMatrix;
        mat_ao.SetMatrix("_VPMatrix_invers", vp_Matrix.inverse);

        Matrix4x4 v_Matrix = cam.worldToCameraMatrix;
        mat_ao.SetMatrix("_VMatrix", v_Matrix);

        Matrix4x4 p_Matrix = cam.projectionMatrix;
        mat_ao.SetMatrix("_PMatrix", p_Matrix);

        mat_ao.SetFloat("_SampleCount", sampleCount);
        mat_ao.SetFloat("_Radius", radius);
        mat_ao.SetFloat("_RangeCheck", rangeCheck);
        mat_ao.SetFloat("_AOInt", aoInt);
        mat_ao.SetColor("_AOCol", aoColor);

        mat_blur.SetFloat("_BlurRadius", blurRadius);
        mat_blur.SetFloat("_BilaterFilterFactor", bilaterFilterFactor);
    }
}
