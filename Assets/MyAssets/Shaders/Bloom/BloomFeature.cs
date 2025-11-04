using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;
[Serializable]
public class BloomFeature : ScriptableRendererFeature {
  public float bloomThreshold = 1.0f;
  public float bloomIntensity = 1.5f;
  public int bloomTimes = 5;
  [Serializable]
  public class BloomPass : ScriptableRenderPass {
    public float bloomThreshold;
    public float bloomIntensity;
    public int bloomTimes;
    [Serializable]
    class PassData {
      public Material material;
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
      renderGraph.AddBlitPass(resourceData.activeColorTexture, texture1, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 0, 0, 1);
      // can not read a mip level and write another mip level in same pass
      for (int i = 0; i < bloomTimes; ++i) {
        int layer = i;
        using (var builder = renderGraph.AddRasterRenderPass("BloomDownsamplePass",
            out PassData passData)) {
          passData.material = new Material(Shader.Find("Custom/BloomShader"));
          passData.material.SetFloat("_BloomThreshold", bloomThreshold);
          passData.texture = texture1;
          builder.SetRenderAttachment(texture2, 0, AccessFlags.WriteAll, layer + 1, -1);
          builder.SetInputAttachment(texture1, 0, AccessFlags.Read, layer, -1);
          builder.SetRenderFunc((PassData data, RasterGraphContext context) => {
            data.material.SetTexture("_MainTex", data.texture);
            data.material.SetInt("_MipLevel", layer);
            context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3);
          });
        }
        // renderGraph.AddBlitPass(texture2, texture1, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, layer + 1, layer + 1, 1);
        (texture1, texture2) = (texture2, texture1);
      }
      for (int i = bloomTimes; i > 0; --i) {
        int layer = i;
        using (var builder = renderGraph.AddRasterRenderPass("BloomBlurPass1",
            out PassData passData)) {
          passData.material = new Material(Shader.Find("Custom/BloomShader"));
          passData.material.SetInt("_BlurType", 1);
          passData.texture = texture1;
          builder.SetRenderAttachment(texture2, 0, AccessFlags.WriteAll, layer, -1);
          builder.SetInputAttachment(texture1, 0, AccessFlags.Read, layer, -1);
          builder.SetRenderFunc((PassData data, RasterGraphContext context) => {
            data.material.SetTexture("_MainTex", data.texture);
            data.material.SetInt("_MipLevel", layer);
            context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3);
          });
        }
        using (var builder = renderGraph.AddRasterRenderPass("BloomBlurPass2",
            out PassData passData)) {
          passData.material = new Material(Shader.Find("Custom/BloomShader"));
          passData.material.SetInt("_BlurType", 2);
          passData.texture = texture2;
          builder.SetRenderAttachment(texture1, 0, AccessFlags.WriteAll, layer, -1);
          builder.SetInputAttachment(texture2, 0, AccessFlags.Read, layer, -1);
          builder.SetRenderFunc((PassData data, RasterGraphContext context) => {
            data.material.SetTexture("_MainTex", data.texture);
            data.material.SetInt("_MipLevel", layer);
            context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3);
          });
        }
        // renderGraph.AddBlitPass(texture1, texture2, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, layer, layer, 1);
        using (var builder = renderGraph.AddRasterRenderPass("BloomUpsamplePass",
            out PassData passData)) {
          passData.material = new Material(Shader.Find("Custom/BloomShader"));
          passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
          passData.texture = texture1;
          builder.SetRenderAttachment(texture2, 0, AccessFlags.WriteAll, layer - 1, -1);
          builder.SetInputAttachment(texture1, 0, AccessFlags.Read, layer, -1);
          builder.SetRenderFunc((PassData data, RasterGraphContext context) => {
            // context.cmd.ClearRenderTarget(false, true, Color.clear);
            data.material.SetTexture("_MainTex", data.texture);
            data.material.SetInt("_MipLevel", layer);
            context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 2, MeshTopology.Triangles, 3);
          });
        }
        (texture1, texture2) = (texture2, texture1);
      }
      renderGraph.AddBlitPass(texture1, resourceData.activeColorTexture, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 0, 0, 1);
    }
  }
  private BloomPass bloomPass;
  public override void Create() {
    bloomPass = new BloomPass() {
      renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing - 10,
      bloomThreshold = bloomThreshold,
      bloomIntensity = bloomIntensity,
      bloomTimes = Math.Min(Math.Max(bloomTimes, 3), 7)
    };
  }
  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
    renderer.EnqueuePass(bloomPass);
  }
}
