using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
[Serializable]
public class BloomFeature : ScriptableRendererFeature {
  public float bloomThreshold = 1.0f;
  public float bloomIntensity = 1.5f;
  public int bloomTimes = 5;
  [Serializable]
  public class BloomPass : ScriptableRenderPass {
    public Material material;
    public Material materialBlurX;
    public Material materialBlurY;
    public float bloomThreshold;
    public float bloomIntensity;
    public int bloomTimes;
    [Serializable]
    class PassData {
      public Material material;
      public MaterialPropertyBlock properties;
      public TextureHandle texture;
    }
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameContext) {
      if (bloomTimes <= 0) {
        return;
      }
      var resourceData = frameContext.Get<UniversalResourceData>();
      // avoid auto texture allocate miss
      // if (rthTexture1 == null) {
      //   var textureDesc = resourceData.activeColorTexture.GetDescriptor(renderGraph);
      //   rthTexture1 = RTHandles.Alloc(textureDesc.width, textureDesc.height, textureDesc.format, useDynamicScale: true, useMipMap: true, autoGenerateMips: false, name: "BloomTexture1");
      //   rthTexture2 = RTHandles.Alloc(textureDesc.width, textureDesc.height, textureDesc.format, useDynamicScale: true, useMipMap: true, autoGenerateMips: false, name: "BloomTexture2");
      // }
      // var texture1 = renderGraph.ImportTexture(rthTexture1);
      // var texture2 = renderGraph.ImportTexture(rthTexture2);
      var textureDesc = resourceData.activeColorTexture.GetDescriptor(renderGraph);
      textureDesc.useMipMap = true;
      textureDesc.autoGenerateMips = false;
      textureDesc.filterMode = FilterMode.Point;
      textureDesc.name = "BloomTexture1";
      var texture1 = renderGraph.CreateTexture(textureDesc);
      textureDesc.name = "BloomTexture2";
      var texture2 = renderGraph.CreateTexture(textureDesc);
      // renderGraph.AddBlitPass(resourceData.activeColorTexture, texture1, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 0, 0, 1);
      // can not read a mip level and write another mip level in same pass
      for (int i = 0; i < bloomTimes; ++i) {
        using (var builder = renderGraph.AddRasterRenderPass("BloomDownsamplePass",
            out PassData passData)) {
          passData.material = material;
          MaterialPropertyBlock properties = new();
          properties.SetFloat("_BloomThreshold", bloomThreshold);
          properties.SetInt("_MipLevel", i);
          passData.properties = properties;
          if (i == 0) {
            passData.texture = resourceData.activeColorTexture;
            builder.UseTexture(resourceData.activeColorTexture);
          } else {
            passData.texture = texture1;
            builder.UseTexture(texture1);
          }
          builder.SetRenderAttachment(texture2, 0, AccessFlags.WriteAll, i + 1, -1);
          builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
            data.properties.SetTexture("_MainTex", data.texture);
            context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3, 1, data.properties);
          });
        }
        (texture1, texture2) = (texture2, texture1);
      }
      for (int i = bloomTimes; i > 0; --i) {
        using (var builder = renderGraph.AddRasterRenderPass("BloomBlurPass1",
            out PassData passData)) {
          passData.material = materialBlurX;
          MaterialPropertyBlock properties = new();
          properties.SetInt("_MipLevel", i);
          passData.properties = properties;
          passData.texture = texture1;
          builder.UseTexture(texture1);
          builder.SetRenderAttachment(texture2, 0, AccessFlags.WriteAll, i, -1);
          builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
            data.properties.SetTexture("_MainTex", data.texture);
            context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3, 1, data.properties);
          });
        }
        using (var builder = renderGraph.AddRasterRenderPass("BloomBlurPass2",
            out PassData passData)) {
          passData.material = materialBlurY;
          MaterialPropertyBlock properties = new();
          properties.SetInt("_MipLevel", i);
          passData.properties = properties;
          passData.texture = texture2;
          builder.UseTexture(texture2);
          builder.SetRenderAttachment(texture1, 0, AccessFlags.WriteAll, i, -1);
          builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
            data.properties.SetTexture("_MainTex", data.texture);
            context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3, 1, data.properties);
          });
        }
        using (var builder = renderGraph.AddRasterRenderPass("BloomUpsamplePass",
            out PassData passData)) {
          passData.material = material;
          MaterialPropertyBlock properties = new();
          properties.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
          properties.SetInt("_MipLevel", i);
          passData.properties = properties;
          passData.texture = texture1;
          builder.UseTexture(texture1);
          if (i == 1) {
            builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.Write, i - 1, -1);
          } else {
            builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, i - 1, -1);
          }
          builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
            data.properties.SetTexture("_MainTex", data.texture);
            context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 2, MeshTopology.Triangles, 3, 1, data.properties);
          });
        }
        (texture1, texture2) = (texture2, texture1);
      }
      // renderGraph.AddBlitPass(texture1, resourceData.activeColorTexture, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 0, 0, 1);
    }
  }
  private BloomPass bloomPass;
  public override void Create() {
    Shader shader = Shader.Find("Custom/BloomShader");
    Material materialX = new(shader);
    materialX.EnableKeyword("BLUR_X");
    Material materialY = new(shader);
    materialY.EnableKeyword("BLUR_Y");
    bloomPass = new BloomPass() {
      renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing - 10,
      material = materialX,
      materialBlurX = materialX,
      materialBlurY = materialY,
      bloomThreshold = bloomThreshold,
      bloomIntensity = bloomIntensity,
      bloomTimes = Math.Min(bloomTimes, 7)
    };
  }
  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
    renderer.EnqueuePass(bloomPass);
  }
}
