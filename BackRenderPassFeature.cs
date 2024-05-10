using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BackRenderPassFeature : ScriptableRendererFeature
{
    public CustomSetting settings = new CustomSetting();

    BackRenderPass m_ScriptablePass;
    public class BackRenderPass : ScriptableRenderPass
    {
        CustomSetting setting;


        private RenderTargetIdentifier _Source; //源RT
        private RenderTargetHandle _Destination; //目标RT

        List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();


        RenderStateBlock m_RenderStateBlock;
        FilteringSettings m_FilteringSettings;

        ProfilingSampler m_ProfilingSampler;
        public BackRenderPass(CustomSetting setting)
        {
            this.setting = setting;

            m_ProfilingSampler = new ProfilingSampler("Back Render");
            m_RenderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);
            m_RenderStateBlock.mask |= RenderStateMask.Depth;
            m_RenderStateBlock.depthState = new DepthState(true, setting.depthCompareFunction);

            m_ShaderTagIdList.Add(new ShaderTagId("SRPDefaultUnlit"));
            m_ShaderTagIdList.Add(new ShaderTagId("UniversalForward"));
            m_ShaderTagIdList.Add(new ShaderTagId("UniversalForwardOnly"));

            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque, setting.LayerMask);
        }

        public void Setup(RenderTargetIdentifier _source, RenderTargetHandle target)
        {
            _Source = _source;
            _Destination = target;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            SortingCriteria sortingCriteria = SortingCriteria.CommonOpaque;

            DrawingSettings drawingSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, sortingCriteria);
            drawingSettings.overrideMaterial = setting.overrideMaterial;
            drawingSettings.overrideMaterialPassIndex = setting.overrideMaterialPassIndex;

            CommandBuffer cmd = CommandBufferPool.Get();

            using(new ProfilingScope(cmd,m_ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings, ref m_RenderStateBlock);
            }


            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //throw new System.NotImplementedException();

        m_ScriptablePass.Setup(renderer.cameraColorTarget, RenderTargetHandle.CameraTarget);
        renderer.EnqueuePass(m_ScriptablePass);
    }

    public override void Create()
    {
        //throw new System.NotImplementedException();
        m_ScriptablePass = new BackRenderPass(settings);
        m_ScriptablePass.renderPassEvent = settings.PassEvent;
    }


    [System.Serializable]
    public class CustomSetting
    {
        public RenderPassEvent PassEvent;

        public Material overrideMaterial = null;
        public int overrideMaterialPassIndex = 0;


        public CompareFunction depthCompareFunction = CompareFunction.LessEqual;
        public LayerMask LayerMask;
    }
}
