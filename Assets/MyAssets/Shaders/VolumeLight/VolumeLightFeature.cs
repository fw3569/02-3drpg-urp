using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
[Serializable]
public class VolumeLightFeature : ScriptableRendererFeature {
  public float intensity = 5;
  public float mieScattering = 0.5f;
  public float extingctionFactor = 0.5f;
  public int blurTimes = 4;
  [Serializable]
  public class VolumeLightPass : ScriptableRenderPass {
    public float intensity;
    public float mieScattering;
    public float extingctionFactor;
    public int blurTimes;
    [Serializable]
    class PassData {
      public Material material;
      public TextureHandle texture1;
      public TextureHandle texture2;
    }
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameContext) {
      string volumeLightMarchingPassName = "VolumeLightMarchingPass";
      string volumeLightBlurPassName = "VolumeLightBlurPass";
      string volumeLightBlendPassName = "VolumeLightBlendPass";
      var resourceData = frameContext.Get<UniversalResourceData>();
      Material material = new(Shader.Find("Custom/VolumeLightShader"));
      material.SetFloat("_Intensity", intensity);
      material.SetFloat("_MieScattering", mieScattering);
      material.SetFloat("_ExtingctionFactor", extingctionFactor);
      var activeColorTexture = resourceData.activeColorTexture;
      var textureDesc = resourceData.activeColorTexture.GetDescriptor(renderGraph);
      // if (rthTexture1 == null || !rthTexture1.rt.IsCreated()) {
      //   RTHandles.Release(rthTexture1);
      //   RTHandles.Release(rthTexture2);
      //   rthTexture1 = RTHandles.Alloc(textureDesc.width, textureDesc.height, GraphicsFormat.R16_SFloat, filterMode: FilterMode.Bilinear, wrapMode: TextureWrapMode.Clamp, useDynamicScale: true, name: "VolumeLightTexture1");
      //   rthTexture2 = RTHandles.Alloc(textureDesc.width, textureDesc.height, GraphicsFormat.R16_SFloat, useDynamicScale: true, name: "VolumeLightTexture2");
      // }
      // var texture1 = renderGraph.ImportTexture(rthTexture1);
      // var texture2 = renderGraph.ImportTexture(rthTexture2);
      textureDesc.name = "VolumeLightTexture1";
      var texture1 = renderGraph.CreateTexture(textureDesc);
      textureDesc.name = "VolumeLightTexture2";
      var texture2 = renderGraph.CreateTexture(textureDesc);
      using (var builder = renderGraph.AddRasterRenderPass(volumeLightMarchingPassName,
          out PassData passData)) {
        passData.material = material;
        builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture, AccessFlags.Read);
        builder.SetRenderAttachment(texture1, 0, AccessFlags.WriteAll);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3);
        });
      }
      for (int i = 0, blurStep = 1; i < blurTimes; ++i, blurStep <<= 1) {
        int tempBlurStep = blurStep;
        using (var builder = renderGraph.AddRasterRenderPass(volumeLightBlurPassName,
            out PassData passData)) {
          passData.material = material;
          passData.texture1 = texture1;
          builder.SetInputAttachment(texture1, 0);
          builder.SetRenderAttachment(texture2, 0, AccessFlags.WriteAll);
          builder.SetRenderFunc((PassData data, RasterGraphContext context) => {
            data.material.SetTexture("_MainTex", data.texture1);
            data.material.SetInt("_BlurStep", tempBlurStep);
            context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3);
          });
        }
        using (var builder = renderGraph.AddRasterRenderPass(volumeLightBlurPassName,
            out PassData passData)) {
          passData.material = material;
          passData.texture2 = texture2;
          builder.SetInputAttachment(texture2, 0);
          builder.SetRenderAttachment(texture1, 0, AccessFlags.WriteAll);
          builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
            Blitter.BlitTexture(context.cmd, data.texture2, new Vector4(1, 1, 0, 0), 0, true);
          });
        }
      }
      using (var builder = renderGraph.AddRasterRenderPass(volumeLightBlendPassName,
          out PassData passData)) {
        passData.material = material;
        passData.texture1 = texture1;
        builder.SetInputAttachment(texture1, 0);
        builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.WriteAll);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 2, MeshTopology.Triangles, 3);
        });
      }
    }
  }
  private VolumeLightPass volumeLightPass;
  public override void Create() {
    volumeLightPass = new VolumeLightPass() {
      renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing,
      intensity = intensity,
      mieScattering = mieScattering,
      extingctionFactor = extingctionFactor,
      blurTimes = blurTimes
    };
  }
  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
    renderer.EnqueuePass(volumeLightPass);
  }
}
