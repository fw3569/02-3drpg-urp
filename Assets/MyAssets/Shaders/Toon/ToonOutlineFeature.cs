using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RendererUtils;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;
[Serializable]
public class ToonOutlineFeature : ScriptableRendererFeature {
  public enum OutlineType {
    FORWARD,
    POST
  };
  public OutlineType outlineType = OutlineType.FORWARD;
  public float edgeThresholdColor = 0.5f;
  public float edgeThresholdDepth = 0.01f;
  [Serializable]
  public class ToonOutlinePass : ScriptableRenderPass {
    public OutlineType outlineType;
    public float edgeThresholdColor;
    public float edgeThresholdDepth;
    [Serializable]
    class PassData {
      public RendererListHandle rendererListHandle;
      public Material material;
      public TextureHandle colorTexture;
      public TextureHandle depthTexture;
      public float edgeThresholdColor;
      public float edgeThresholdDepth;
    }
    public void AddOutlineFowardPass(RenderGraph renderGraph, ContextContainer frameContext) {
      string passName = "ToonOutlineForwardPass";
      var renderingData = frameContext.Get<UniversalRenderingData>();
      var resourceData = frameContext.Get<UniversalResourceData>();
      var desc = new RendererListDesc(
        // use with override shader or material to work for all objects
        new[] { new ShaderTagId(passName), new ShaderTagId("UniversalForward") },
        // new ShaderTagId(passName),
        renderingData.cullResults,
        frameContext.Get<UniversalCameraData>().camera
      ) {
        sortingCriteria = SortingCriteria.CommonOpaque,
        renderQueueRange = RenderQueueRange.all,
        layerMask = ~0,
        overrideShader = Shader.Find("Custom/ToonShader"),
        overrideShaderPassIndex = 1
      };
      var rendererListHandle = renderGraph.CreateRendererList(desc);
      using (var builder = renderGraph.AddRasterRenderPass(passName,
          out PassData passData)) {
        passData.rendererListHandle = rendererListHandle;
        builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture);
        builder.UseRendererList(rendererListHandle);
        builder.SetRenderAttachment(resourceData.activeColorTexture, 0);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          // context.cmd.ClearRenderTarget(true, true, Color.white);
          context.cmd.DrawRendererList(data.rendererListHandle);
        });
      }
    }
    public void AddOutlinePostPass(RenderGraph renderGraph, ContextContainer frameContext) {
      string passName = "ToonOutlinePostPass";
      var resourceData = frameContext.Get<UniversalResourceData>();
      var textureDesc = resourceData.activeColorTexture.GetDescriptor(renderGraph);
      textureDesc.name = "OutlinePostTexture";
      var texture = renderGraph.CreateTexture(textureDesc);
      renderGraph.AddBlitPass(resourceData.activeColorTexture, texture, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f));
      using (var builder = renderGraph.AddRasterRenderPass(passName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/ToonShader"));
        passData.colorTexture = texture;
        passData.depthTexture = resourceData.activeDepthTexture;
        passData.edgeThresholdColor = edgeThresholdColor;
        passData.edgeThresholdDepth = edgeThresholdDepth;
        builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.WriteAll);
        builder.SetInputAttachment(passData.colorTexture, 0);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.colorTexture);
          data.material.SetTexture("_DepthTex", data.depthTexture);
          data.material.SetFloat("_EdgeThresholdColor", data.edgeThresholdColor);
          data.material.SetFloat("_EdgeThresholdDepth", data.edgeThresholdDepth);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 5, MeshTopology.Triangles, 3);
        });
      }
    }
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameContext) {
      if (outlineType == OutlineType.FORWARD) {
        AddOutlineFowardPass(renderGraph, frameContext);
      } else {
        AddOutlinePostPass(renderGraph, frameContext);
      }
    }
  }
  private ToonOutlinePass outlinePass;
  public override void Create() {
    outlinePass = new ToonOutlinePass() {
      renderPassEvent = RenderPassEvent.AfterRenderingTransparents,
      outlineType = outlineType,
      edgeThresholdColor = edgeThresholdColor,
      edgeThresholdDepth = edgeThresholdDepth
    };
  }
  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
    renderer.EnqueuePass(outlinePass);
  }
}
