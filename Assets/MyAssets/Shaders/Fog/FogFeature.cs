using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
[Serializable]
public class FogFeature : ScriptableRendererFeature {
  public float densityFar = 0.001f;
  public float densityHeight = 0.03f;
  public Color color = Color.white;

  [Serializable]
  public class FogPass : ScriptableRenderPass {
    public Material material;
    [Serializable]
    class PassData {
      public Material material;
    }
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameContext) {
      string fogPassName = "FogPass";
      var resourceData = frameContext.Get<UniversalResourceData>();
      using (var builder = renderGraph.AddRasterRenderPass(fogPassName,
          out PassData passData)) {
        passData.material = material;
        builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture, AccessFlags.Read);
        builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.Write);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3);
        });
      }
    }
  }
  private FogPass fogPass;
  public override void Create() {
    Material material = new(Shader.Find("Custom/FogShader"));
    material.SetFloat("_DensityFar", densityFar);
    material.SetFloat("_DensityHeight", densityHeight);
    material.SetColor("_Color", color);
    fogPass = new FogPass() {
      renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing,
      material = material
    };
  }
  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
    renderer.EnqueuePass(fogPass);
  }
}
