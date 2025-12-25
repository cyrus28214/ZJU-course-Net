









<center>
  <font face="黑体" size = 100>
    《计算机网络》实验报告
  </font>
</center> 
<center><font face="黑体" size = 4>
    姓名：
  </font>
</center> 
<center><font face="黑体" size = 4>
    学院：
  </font> 
</center> 
<center><font face="黑体" size = 4>
    系：
  </font> 
</center> 
<center><font face="黑体" size = 4>
    专业：
  </font>
</center> 
<center><font face="黑体" size = 4>
    学号：
  </font>
</center> 
<center><font face="黑体" size = 4>
    指导教师：
  </font>
</center> 







<center><font face="黑体" size = 5>
    报告日期:  年 月 日
  </font>
</center> 


# Lab5 <此处替换为实验名称>

> <此处替换为姓名> <此处替换为专业> <此处替换为学号>

## 实验目的

- 学习掌握TCP的工作原理
- 学习掌握TCP connection的相关知识
- 学习掌握协议栈结构

## 实验内容

- 将TCPSender和TCPReceiver结合，实现一个TCP终端，同时收发数据。
- 实现TCP connection的状态管理，如连接和断开连接等。
- 整合网络接口、IP路由以及TCP并实现端到端的通信。


## 主要仪器设备

- 联网的PC机
- Linux虚拟机

## 操作方法与实验步骤

**对于实验指导中的所有章节，请在这里介绍实验的具体过程，包括关键代码的解释，关键步骤的截图及说明等，这部分的内容应当与实际操作过程和结果相符。本节也可以再细分小节。（实验报告中请去除本段）**



## <span id='result'> 实验结果与分析 </span>

1. **这里应给出详实的实验结果。分析应有条理，要求采用规范的书面语。**

2. **原则上要求使用图片与文字结合的形式说明，因为word和PDF文档不支持视频，所以请不要使用视频文件。**
3. **图片请在垂直方向，不要横向。不要用很大的图片，请先做裁剪操作。**

**（实验报告中请去除本段）**

- 实现TCPConnection的关键代码截图
- 运行make check命令的运行结果截图
- 重新编写webget.cc的代码截图
-	重新测试webget的测试结果展示
-	最终测试中服务器和客户端的运行（连接、数据传输和结束）截图

### 思考题

**根据你编写的程序运行效果，分别解答以下问题（实验报告中请去除此段）**

-	ACK标志的目的是什么？ackno是经常存在的吗？

-	请描述TCPConnection的代码中是如何整合TCPReceiver和TCPSender的。

-	在最终测试中服务器和客户端能互连吗？如果不能，你分析是什么原因？

-	在关闭连接的时候是否两端都能正常关闭？如果不能，你分析是原因？


## 讨论、心得

**简要地叙述一下实验过程中的感受，以及其他的问题描述和自己的感想。特别是实验中遇到的困难，最后如何解决的。（实验报告中请去除本段）**