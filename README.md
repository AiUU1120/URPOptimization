# SuntailVillage优化工程

# 概述

## 简介

针对AssetStore的[SUNTAIL - Stylized Fantasy Village](https://assetstore.unity.com/packages/3d/environments/fantasy/suntail-stylized-fantasy-village-203303)项目工程在移动平台的优化

[个人性能优化相关笔记](https://oqv1xm6asjg.feishu.cn/drive/folder/FvIMfXjMwl6AYzdPy3DcnMVVnkb?from=from_copylink)



## 测试机器

Redmi Note11T Pro

## 性能分析工具

- Unity Profiler
- Unity UPR

## 优化前参考性能数据

- 渲染批次1500~2000
- SetPassCall 200+
- 三角形面数150~200万
- APK包体550M
- Redmi Note11T Pro 约16fps
- 内存占用约1.7G

![](https://s3.bmp.ovh/imgs/2024/08/08/f3d236a5d9f4730e.jpg)

![](https://s3.bmp.ovh/imgs/2024/08/08/e791953b9d458772.png)



# 优化步骤

## 静态资源优化

### 音频文件优化

- 左右声道相同的双声道音频文件启用Force To Mono（转换为单声道）
- 降低音频采样率至22050Hz（移动平台经验值）
- 对不同大小的文件采用不同的Load Type

### 模型资源优化

- 项目内模型不需要动画，将Animation Type设置为None
- 由于该套资源模型制作较为规范，内存优化空间较少

### 纹理资源优化

- 更改纹理大小不是2的次幂的纹理大小
- 将具有空Alpha通道的纹理的Alpha Source设为None
- 降低过大纹理大小

优化后包体降至370M

## 性能总览与瓶颈定位

### Unity Profiler

![](https://s3.bmp.ovh/imgs/2024/08/14/be47397704a59ab6.png)

在Redmi Note11T Pro上，每帧时间消耗大约65ms

渲染线程上Gfx.PresentFrame线程约40ms，可知具有一定GPU瓶颈

### Unity UPR

利用Unity UPR的云真机功能进行测试，由于UPR没有我的设备Redmi Note11T Pro，采用同样搭载天玑8100的一加Ace进行替代

![](https://s3.bmp.ovh/imgs/2024/08/14/aecd6095c63fdc52.png)

同样是天玑8100的一加Ace比我的Redmi Note11T Pro平均帧数要高上几帧，可能是散热方面的差距？总之待优化问题还是非常多的，尤其是DrawCall

### 结论

GPU与带宽可能是主要瓶颈，可以确定大致的优化方向

- 渲染流程与效果优化
- 渲染中生成资源优化
- DrawCall与SetPassCall
- 片元着色器
- 渲染三角形

## 渲染流程分析

![](https://s3.bmp.ovh/imgs/2024/08/15/3b3ab706ee3db792.png)

由FrameDebug可知，UGUI与GUI的渲染都不是优化重点

另外由Deferred Pass可知，该项目主要为延迟渲染，SSAO与后处理是耗时的大头（参考了其他人XCode下的性能分析）

## SSAO优化

![](https://s3.bmp.ovh/imgs/2024/08/15/07aa18b3abc846e2.png)

- 启用Downsample降低纹理采样，URP源码中降采样比例是1/4，可以通过修改源码改变这个值，或是通过扩展SSAO参数为每张生成的中间纹理指定降采样系数
- 降低AO信息计算的采样半径Radius，同时配合调整AO强度平衡视觉效果；
- 降低SampleCount采样次数，值越大性能开销越大，虽然表现较好但往往得不偿失，在移动平台上要尽可能小采样次数下调整AO效果

优化后参考参数

![](https://s3.bmp.ovh/imgs/2024/08/15/a8ebf3e8c5daddbb.png)

SSAO优化后真机运行帧率提升至30fps左右，效果可谓显著，泪目

但SSAO优化后打包出来包体暴涨，原因未知，先留个坑

已破案，是Unity构建缓存导致，删除Library重新打开工程可解，啥比Unity

## AA反走样优化

由于工程为延迟渲染，无法使用MSAA方案，对于较低端的设备可以考虑是否需要开启AA

在此次优化中结合移动平台的表现需求与效率，改为采用质量较差但效率较高的FXAA方案

![](https://s3.bmp.ovh/imgs/2024/08/15/4661cd03c0eaa9c5.png)

FXAA会带来一定的画面模糊问题，但在手机端是可以接受的

## PostProcess后处理优化

移除工程中一些不必要的后处理如白平衡（WhiteBalance）、渐晕（Vignette）、散色相差（ChromaticAberration），以及在移动端性能负载过大的动态模糊（MotionBlur）

由于移除渐晕导致画面整体变亮，降低ColorAdjustments中的PostExposure从1.0到0.8弥补一下视觉上的差距

![](https://s3.bmp.ovh/imgs/2024/08/17/68dabad02f041de3.png)

将URPAsset中的后处理GradingMode改为更适合游戏的LDR模式，降低LUTsize，同时勾选Fast sRGB

但要注意支持浮点精度纹理的平台或设备（如iPhone），Grading使用HDR模式效率会更高

![](https://s3.bmp.ovh/imgs/2024/08/17/f0c289cfda0527a0.png)

Bloom优化：查看Bloom的Shader可知Bloom是由四个Pass完成的，包括Bloom Prefilter做降采样，水平与垂直的两遍模糊，与Bloom Upsample图像合成，优化可以从降采样与模糊Pass入手

查看后处理中Bloom相关代码，可以修改Bloom开始的采样分辨率从1/2降至1/4，然后将迭代次数降低为4

```// Start at half-res
//---bloom opt 修改定义从多大分辨率从4分之一开始
//int tw = m_Descriptor.width >> 1;
//int th = m_Descriptor.height >> 1;
int tw = m_Descriptor.width >> 2;
int th = m_Descriptor.height >> 2;
//---Determine the iteration count
int maxSize = Mathf.Max(tw, th);
int iterations = Mathf.FloorToInt(Mathf.Log(maxSize, 2f) - 1);
iterations -= m_Bloom.skipIterations.value;
//---bloom opt 修改最大downscale迭代次数
//int mipCount = Mathf.Clamp(iterations, 1, k_MaxPyramidSize);
int mipCount = Mathf.Clamp(iterations, 1, 4);
```

## 远景简化

由于该场景中的远景是不可达区域，同时使用了模型，因此可以考虑将模型简化为天空盒

远景使用模型的效果

![](https://s3.bmp.ovh/imgs/2024/08/18/2660d065370a2a63.png)

远景使用天空盒的效果

![](https://s3.bmp.ovh/imgs/2024/08/18/08bdc2ec04a90cab.png)

可见虽然精细度上有轻微下降，但效果还行，性价比很高

## 中景简化与LOD

- 由于在场景中Batches过高，通过查看模型Prefab，发现有许多模型的LOD设置不合理，尤其是小物件的剔除，遂逐一进行了调整

- 同时由于Shadow casters亦过高，可以关闭小物件在低LOD下的阴影

调整后Batches和Shadow casters都有了明显的下降

![](https://s3.bmp.ovh/imgs/2024/08/18/3781c55dfbb26f85.png)

测试发现帧率并没有明显提升，GPU绘制时间也只有1~2ms的差距，发现是不同平台下的LOD Bias设置不一致导致的

吐槽：一个个Prefab手调LOD实在是效率低下，也许需要一些自动化处理工具

## 遮挡剔除

通过查看Occlusion Culling，原场景作者是有做一定的遮挡剔除工作的

![](https://s3.bmp.ovh/imgs/2024/08/19/4d9fedfc3d15c6f4.png)

但原作者只做了静态遮挡剔除，对于需要动态遮挡剔除的物体（如可开关的门），为其额外添加Occlusion Portal，在开关门的相关脚本中设置遮挡剔除开关

## 光影剔除

- 由于之前把远景山的模型换成了天空盒，可先把远景相关的光源删除

- 同时由于该场景内地形较为平坦，也没有需要投影阴影的表现，可将其Cast Shadows关闭

- 考虑距离剔除，发现原项目也已经做了相关内容

- 调整URPAsset中关于Lighting与Shadows的设置，降低Object接受光照最大数量，考虑光源大多室内，降低ShadowAtlasResolution，降低CascadeCount

一波下来又有了一些提升

![](https://s3.bmp.ovh/imgs/2024/08/19/98d0b81f7f74d32a.png)

## 地形优化

原工程中的地形是用Unity自带的Terrain制作的，但Terrain在移动端的效率并不好

一般来说会采用地形Mesh替代，这里借用第三方插件Terrain To Mesh自动生成地形Mesh

- 如图所示，将原本的Terrain分成8*8的地形Mesh块

![](https://s3.bmp.ovh/imgs/2024/08/20/1d258f1e594f789c.png)

[Terrain To Mesh Unity商店地址](https://assetstore.unity.com/packages/tools/terrain/terrain-to-mesh-195349)

- 另外修改地形网格的绘制顺序，让其在不透明物体的最后绘制，避免支持SRP Batcher的对象被不支持SRP Batcher的地形块绘制所打断

![](https://s3.bmp.ovh/imgs/2024/08/20/6badef81a8641d3c.png)
