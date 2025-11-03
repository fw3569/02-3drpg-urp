using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;
[Serializable]
public class BloomFeature : ScriptableRendererFeature {
  public float bloomThreshold = 1.0f;
  public float bloomIntensity = 1.5f;
  [Serializable]
  public class BloomPass : ScriptableRenderPass {
    public float bloomThreshold;
    public float bloomIntensity;
    [Serializable]
    class PassData {
      public RendererListHandle rendererListHandle;
      public Material material;
      public TextureHandle texture1;
      public TextureHandle texture2;
    }
    public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameContext) {
      string downsamplePassName = "BloomDownsamplePass";
      string upsamplePassName = "BloomUpsamplePass";
      var resourceData = frameContext.Get<UniversalResourceData>();
      var textureDesc = resourceData.activeColorTexture.GetDescriptor(renderGraph);
      textureDesc.useMipMap = true;
      textureDesc.autoGenerateMips = false;
      textureDesc.name = "BloomTexture1";
      var texture1 = renderGraph.CreateTexture(textureDesc);
      // avoid auto skip mipmap
      RTHandle rthTexture2 = RTHandles.Alloc(textureDesc.width, textureDesc.height, textureDesc.format, useMipMap: true, autoGenerateMips: false, name: "BloomTexture2");
      var texture2 = renderGraph.ImportTexture(rthTexture2);
      renderGraph.AddBlitPass(resourceData.activeColorTexture, texture1, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 0, 0, 1);
      // can not read a mip level and write another mip level in same pass
      using (var builder = renderGraph.AddRasterRenderPass(downsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomThreshold", bloomThreshold);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 1, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 0, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 0);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3);
        });
      }
      renderGraph.AddBlitPass(texture2, texture1, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 1, 1, 1);
      using (var builder = renderGraph.AddRasterRenderPass(downsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomThreshold", bloomThreshold);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 2, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 1, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 1);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3);
        });
      }
      renderGraph.AddBlitPass(texture2, texture1, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 2, 2, 1);
      using (var builder = renderGraph.AddRasterRenderPass(downsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomThreshold", bloomThreshold);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 3, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 2, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 2);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3);
        });
      }
      renderGraph.AddBlitPass(texture2, texture1, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 3, 3, 1);
      using (var builder = renderGraph.AddRasterRenderPass(downsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomThreshold", bloomThreshold);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 4, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 3, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 3);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3);
        });
      }
      renderGraph.AddBlitPass(texture2, texture1, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 4, 4, 1);
      using (var builder = renderGraph.AddRasterRenderPass(downsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomThreshold", bloomThreshold);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 5, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 4, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 4);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 0, MeshTopology.Triangles, 3);
        });
      }
      renderGraph.AddBlitPass(texture2, texture1, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 5, 5, 1);

      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 1);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 5, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 5, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 5);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 2, MeshTopology.Triangles, 3);
        });
      }
      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 2);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture1, 0, AccessFlags.Write, 4, -1);
        builder.SetInputAttachment(texture2, 0, AccessFlags.Read, 5, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture2);
          data.material.SetFloat("_MipLevel", 5);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3);
        });
      }
      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 1);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 4, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 4, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 4);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 2, MeshTopology.Triangles, 3);
        });
      }
      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 2);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture1, 0, AccessFlags.Write, 3, -1);
        builder.SetInputAttachment(texture2, 0, AccessFlags.Read, 4, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture2);
          data.material.SetFloat("_MipLevel", 4);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3);
        });
      }
      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 1);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 3, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 3, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 3);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 2, MeshTopology.Triangles, 3);
        });
      }
      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 2);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture1, 0, AccessFlags.Write, 2, -1);
        builder.SetInputAttachment(texture2, 0, AccessFlags.Read, 3, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture2);
          data.material.SetFloat("_MipLevel", 3);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3);
        });
      }
      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 1);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 2, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 2, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 2);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 2, MeshTopology.Triangles, 3);
        });
      }
      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 2);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture1, 0, AccessFlags.Write, 1, -1);
        builder.SetInputAttachment(texture2, 0, AccessFlags.Read, 2, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture2);
          data.material.SetFloat("_MipLevel", 2);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3);
        });
      }
      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 1);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture2, 0, AccessFlags.Write, 1, -1);
        builder.SetInputAttachment(texture1, 0, AccessFlags.Read, 1, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture1);
          data.material.SetFloat("_MipLevel", 1);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 2, MeshTopology.Triangles, 3);
        });
      }
      using (var builder = renderGraph.AddRasterRenderPass(upsamplePassName,
          out PassData passData)) {
        passData.material = new Material(Shader.Find("Custom/BloomShader"));
        passData.material.SetFloat("_BloomIntensity", bloomIntensity / (1.0f + bloomIntensity));
        passData.material.SetInt("_BlurType", 2);
        passData.texture1 = texture1;
        passData.texture2 = texture2;
        builder.SetRenderAttachment(texture1, 0, AccessFlags.Write, 0, -1);
        builder.SetInputAttachment(texture2, 0, AccessFlags.Read, 1, -1);
        builder.SetRenderFunc(static (PassData data, RasterGraphContext context) => {
          data.material.SetTexture("_MainTex", data.texture2);
          data.material.SetFloat("_MipLevel", 1);
          context.cmd.DrawProcedural(Matrix4x4.identity, data.material, 1, MeshTopology.Triangles, 3);
        });
      }
      renderGraph.AddBlitPass(texture1, resourceData.activeColorTexture, new Vector2(1.0f, 1.0f), new Vector2(0.0f, 0.0f), 0, 0, -1, 0, 0, 1);
    }
  }
  private BloomPass bloomPass;
  public override void Create() {
    bloomPass = new BloomPass() {
      renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing,
      bloomThreshold = bloomThreshold,
      bloomIntensity = bloomIntensity
    };
  }
  public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
    renderer.EnqueuePass(bloomPass);
  }
}
