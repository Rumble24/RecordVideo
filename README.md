# RecordVideo

# OpenGL ES及GLKit

可以采用不同的方式使用OpenGL ES以便呈现OpenGL ES内容到不同的目标：GLKit和CAEAGLLayer。


# GPUImage 基于 OpenGL开发
[iOS GPUImage研究总结](https://blog.csdn.net/Xoxo_x/article/details/52695032)

[iOS图形处理概论：OpenGL ES，Metal，Core Graphics，Core Image，GPUImage，OpenCV等](https://www.juejin.im/post/6844903645272604679)

[iOS 图形编程总结](http://www.cocoachina.com/articles/10124)

[教你实现GPUImage【OpenGL渲染原理】](https://www.jianshu.com/p/b3852409edbc?appinstall=1)

[使用 iOS OpenGL ES 实现长腿功能](http://www.lymanli.com/2019/03/04/ios-opengles-spring/)

[iOS开发——GPUImage源码解析](https://blog.csdn.net/majiakun1/article/details/82746047)

[GPUImage](https://www.jianshu.com/nb/4268718)

[iOS OpenGL 篇](https://www.jianshu.com/u/1f233a6c382c)

[iOS音视频开发](https://www.jianshu.com/c/639cef195201)
# GPUImage 原理和流程

                                           /// GPUImageFilter  需要我们写各种shader[着色器] 处理每一个像素点
///大致流程     输出源<GPUImageOutput>   -->   处理<GPUImageOutput 和 GPUImageInput>   -->   处理后的视频/图片<GPUImageInput>


              输出GPUImageFramebuffer   -->   GPUImageFramebuffer   -->   显示GPUImageView CAEAGLLayer


GPUImage提供了多种不同的输入组件，但是无论是哪种输入源，获取数据的本质都是把图像数据转换成OpenGL纹理

## 问：如何将   CMSampleBufferRef   转化为     GPUImageFramebuffer 

GPUImage提供了多种不同的输入组件，但是无论是哪种输入源，获取数据的本质都是把图像数据转换成OpenGL纹理。这里就以视频拍摄组件（GPUImageVideoCamera）为例，来讲讲GPUImage是如何把每帧采样数据传入到GPU的。

GPUImageVideoCamera里大部分代码都是对摄像头的调用管理，不了解的同学可以去学习一下AVFoundation（传送门）。摄像头拍摄过程中每一帧都会有一个数据回调，在GPUImageVideoCamera中对应的处理回调的方法为：

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
iOS的每一帧摄像头采样数据都会封装成CMSampleBufferRef； CMSampleBufferRef除了包含图像数据、还包含一些格式信息、图像宽高、时间戳等额外属性； 摄像头默认的采样格式为YUV420，关于YUV格式大家可以自行搜索学习一下（传送门）：

YUV420按照数据的存储方式又可以细分成若干种格式，这里主要是kCVPixelFormatType_420YpCbCr8BiPlanarFullRange和kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange两种；

两种格式都是planar类型的存储方式，y数据和uv数据分开放在两个plane中； 这样的数据没法直接传给GPU去用，GPUImageVideoCamera把两个plane的数据分别取出：

///  YUV 转化为  RGB

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer


- (void)convertYUVToRGBOutput

/// 转换成OpenGL纹理
CVOpenGLESTextureCacheCreateTextureFromImage


## 问：如何将   GPUImageFramebuffer   转化为     CMSampleBufferRef  写入  AVAssetWriterInput
CVOpenGLESTextureCacheCreateTextureFromImage 这个方法

[assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:frameTime]

这里有几个地方值得注意：
1在取数据之前先调了一下glFinish，CPU和GPU之间是类似于client-server的关系，CPU侧调用OpenGL命令后并不是同步等待OpenGL完成渲染再继续执行的，而glFinish命令可以确保OpenGL把队列中的命令都渲染完再继续执行，这样可以保证后面取到的数据是正确的当次渲染结果。
2取数据时用了supportsFastTextureUpload判断，这是个从iOS5开始支持的一种CVOpenGLESTextureCacheRef和CVImageBufferRef的映射（映射的创建可以参看获取数据中的CVOpenGLESTextureCacheCreateTextureFromImage），通过这个映射可以直接拿到CVPixelBufferRef而不需要再用glReadPixel来读取数据，这样性能更好。


## 问：如何将   GPUImageFramebuffer   转化为   GPUImageView    然后播放 

[CAEAGLLayer class];

- (void)createDisplayFramebuffer

创建frameBuffer和renderBuffer时把renderBuffer和CALayer关联在一起； 这是iOS内建的一种GPU渲染输出的联动方法； 这样newFrameReadyAtTime渲染过后画面就会输出到CALayer。









一 、Texture、Map、Mesh 和 Material
Material 的外观由 Map 来展现，Map 本身就是 Texture。so，材质 Material 包含贴图 Map，贴图包含纹理 Texture。

1.1 纹理 Texture
纹理 泛指物体表面上所呈现的花纹或线条，是物体上呈现的线形纹路。大部分就是一张图

在 unity 中，Texture 表现为可视的 图片 ，用于 展示外观 。

1.2 贴图 Map
贴图的具体表现形式是纹理，或者说贴图本身就是纹理。

当纹理 附着 在具体的物体表面时，则称之为贴图。map 还有另外一层含义——映射，其功能就是把纹理 Texture 的 UV 坐标映射到3D物体表面。

1.3 材质 Material
材质可以看成是 材料和质感 的结合。在渲染程式中，它是表面各可视属性的结合，这些可视属性是指表面的色彩、纹理、光滑度、透明度、反射率、折射率、发光度等。

在 unity 中，Material 表现为纹理 Texture 和着色器 Shader 的组合。

1.4 网格 Mesh
Texture、Map 用于描述物体的外观，Material 用于描述物体的材料和质感。但是，依靠这3个属性，并不能正确的展现一个物体。

一个物体还应该有外形，也就是用于 描述物体的形状 。

在 unity 中，Mesh 的作用是用于描述物体的形状。



二、Shader
Shader 实际上就是一段程序，它负责将输入的 Mesh 和 贴图/颜色等按照一定的方式组合起来（Mix），然后输出。Shader的作用就像一个方案，可以将砖块用于围墙，也可以作为地砖铺在地面上。

绘图单元可以依据这个输出来将图像绘制到屏幕上。输入的贴图或者颜色等，加上对应的Shader，以及对Shader的特定的参数设置，将这些内容（Shader及输入参数）打包存储在一起，得到的就是一个Material（材质）。之后，我们便可以将材质赋予合适的renderer（渲染器）来进行渲染（输出）了。




# Demo

项目是仿照抖音的特效相机，基本功能是使用相机拍摄短视频，然后在视频的基础上添加一些视频特效:
https://github.com/ZZZZou/AwemeLike


本项目是基于 GPUImage 开源库构建的相机应用，主要用于学习交流目的:
https://github.com/lmf12/SimpleCam




# 使用libyuv 对 yuv 进行操作 
https://github.com/coderMyron/VideoH264Test


如果我们是直播的话我们就需要 对 yuv 进行编码 然后上传到服务器


也可以使用 VideoToolBox  编码为h264视频编码



视频编码的主要作用是将视频像素数据（RGB，YUV等）压缩成为视频码流，从而降低视频的数据量。如果视频不经过压缩编码的话，体积通常是非常大的，一部电影可能就要上百G的空间。视频编码是视音频技术中最重要的技术之一。视频码流的数据量占了视音频总数据量的绝大部分。高效率的视频编码在同等的码率下，可以获得更高的视频质量。

音频编码的主要作用是将音频采样数据（PCM等）压缩成为音频码流，从而降低音频的数据量。音频编码也是互联网视音频技术中一个重要的技术。但是一般情况下音频的数据量要远小于视频的数据量，因而即使使用稍微落后的音频编码标准，而导致音频数据量有所增加，也不会对视音频的总数据量产生太大的影响。高效率的音频编码在同等的码率下，可以获得更高的音质。


封装格式的主要作用是把视频码流和音频码流按照一定的格式存储在一个文件中


# 使用FFMPEG 对文件进行 编码
两组对比：同样分辨率的文件，通过所消耗的时长判断
