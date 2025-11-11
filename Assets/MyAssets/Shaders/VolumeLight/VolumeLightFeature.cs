using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
[Serializable]
public class VolumeLightFeature : ScriptableRendererFeature {
  public float intensity = 1;
  public float mieScattering = 0.5f;
  public float extingctionFactor = 0.5f;
  public int blurTimes = 4;
  public float bilateralFilterStandardDeviation = 0.01f;
  [Serializable]
  public class VolumeLightPass : ScriptableRenderPass {
    public Material material;
    public float intensity;
    public float mieScattering;
    public float extingctionFactor;
    public int blurTimes;
    public float deviation;
    [Serializable]
    class PassData {
      public Material material;
      public MaterialPropertyBlock properties;
      public TextureHandle texture;
    }
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameContext) {
      var resourceData = frameContext.Get<UniversalResourceData>();
      var activeColorTexture = resourceData.activeColorTexture;
      var textureDesc = resourceData.activeColorTexture.GetDescriptor(renderGraph);
      textureDesc.width /= 2;
      textureDesc.height /= 2;
      textureDesc.format = UnityEngine.Experimental.Rendering.GraphicsFormat.R16_SFloat;
      textureDesc.name = "VolumeLightTexture1";
      var texture1 = renderGraph.CreateTexture(textureDesc);
      textureDesc.name = "VolumeLightTexture2";
      var texture2 = renderGraph.CreateTexture(textureDesc);
      using (var builder = renderGraph.AddRasterRenderPass("VolumeLightMarchingPass",
          out PassData passData)) {
        passData.material = material;
        MaterialPropertyBlock properties = new();
        properties.SetFloat("_MieScattering", mieScattering);
        properties.SetFloat("_ExtingctionFactor", extingctionFactor);
        passData.properties = properties;
        passData.texture = resourceData.activeDepthTexture;
        builder.UseTexture(resourceData.activeDepthTexture, AccessFlags.Read);
        builder.SetRenderAttachment(texture1, 0, AccessFlags.WriteAll);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.properties.SetTexture("_MainTex", data.texture);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3, 1, data.properties);
        });
      }
      for (int i = 0, blurStep = 1; i < blurTimes; ++i, blurStep <<= 2) {
        using (var builder = renderGraph.AddRasterRenderPass("VolumeLightBlurPass",
            out PassData passData)) {
          passData.material = material;
          MaterialPropertyBlock properties = new();
          properties.SetInt("_BlurStep", blurStep);
          properties.SetFloat("_Deviation", deviation);
          passData.properties = properties;
          passData.texture = texture1;
          builder.UseTexture(texture1);
          if (i == blurTimes - 1) {
            properties.SetFloat("_Intensity", intensity);
            builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.Write);
            builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
              data.properties.SetTexture("_MainTex", data.texture);
              context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 2, MeshTopology.Triangles, 3, 1, data.properties);
            });
          } else {
            builder.SetRenderAttachment(texture2, 0, AccessFlags.WriteAll);
            builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
              data.properties.SetTexture("_MainTex", data.texture);
              context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3, 1, data.properties);
            });
          }
        }
        (texture1, texture2) = (texture2, texture1);
      }
    }
  }
  private VolumeLightPass volumeLightPass;
  public override void Create() {
    Material material = new(Shader.Find("Custom/VolumeLightShader"));
    volumeLightPass = new VolumeLightPass() {
      renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing,
      blurTimes = Mathf.Max(blurTimes, 1),
      material = material,
      intensity = intensity,
      mieScattering = mieScattering,
      extingctionFactor = extingctionFactor,
      deviation = bilateralFilterStandardDeviation
    };
  }
  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
    renderer.EnqueuePass(volumeLightPass);
  }
}
