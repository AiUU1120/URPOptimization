# SuntailVillage优化工程

# 概述

## 简介

针对AssetStore的SUNTAIL - Stylized Fantasy Village项目工程在移动平台的优化

https://assetstore.unity.com/packages/3d/environments/fantasy/suntail-stylized-fantasy-village-203303

个人性能优化相关笔记

https://oqv1xm6asjg.feishu.cn/drive/folder/FvIMfXjMwl6AYzdPy3DcnMVVnkb?from=from_copylink



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

