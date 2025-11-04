using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
[Serializable]
public class FogFeature : ScriptableRendererFeature {
  public float densityFar = 0.001f;
  public float densityHeight = 0.03f;

  [Serializable]
  public class FogPass : ScriptableRenderPass {
    public float densityFar;
    public float densityHeight;
    [Serializable]
    class PassData {
      public Material material;
      public TextureHandle texture;
    }
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameContext) {
      string fogPassName = "FogPass";
      var resourceData = frameContext.Get<UniversalResourceData>();
      using (var builder = renderGraph.AddRasterRenderPass(fogPassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/FogShader"));
        passData.material.SetFloat("_DensityFar", densityFar);
        passData.material.SetFloat("_DensityHeight", densityHeight);
        passData.texture = resourceData.activeDepthTexture;
        builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture, AccessFlags.Read);
        builder.SetRenderAttachment(resourceData.activeColorTexture, 0);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3);
        });
      }
    }
  }
  private FogPass fogPass;
  public override void Create() {
    fogPass = new FogPass() {
      renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing,
      densityFar = densityFar,
      densityHeight = densityHeight
    };
  }
  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
    renderer.EnqueuePass(fogPass);
  }
}
