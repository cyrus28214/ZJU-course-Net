









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


# Lab4 <此处替换为实验名称>

> <此处替换为姓名> <此处替换为专业> <此处替换为学号>

## 实验目的

- 学习掌握TCP的工作原理
- 学习掌握流重组器的工作原理
- 学习掌握TCP receiver和TCP sender的相关知识


## 实验内容

- 实现流重组器，一个将字节流的字串或小段按照正确顺序来拼接回连续字节流的模块。
- 实现TCPReceiver。
  - 接收TCPsegment；
  - 重新组装字节流；
  - 确定应该发回发送者的信号，以进行数据确认和流量控制。
- 实现TCPSender：
  - 将ByteStream中的数据以TCP报文形式持续发送给接收者；
  - 处理TCPReceiver传入的ackno和window size，以追踪接收者当前的接收状态，以及检测丢包的情况；
  - 若经过一个超时时间仍然没有接收到TCPReceiver发送的ack包，则重传。
  - 发送一个空段


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

- 运行 ctest -R wrap 命令的测试结果展示
- 运行 make check_lab2 命令的测试结果展示

### 思考题

**根据你编写的程序运行效果，分别解答以下问题（实验报告中请去除此段）**

- 通过代码，请描述TCPSender是如何发送出一个segment的？

- 请用自己的理解描述一下TCPSender超时重传的整个流程。

- 请描述一下你为了重传未被确认的段建立的数据结构？为什么？

- 请思考为什么TCPSender实现中有一个发送空段的方法，能描述一下你是怎么理解的吗？


## 讨论、心得

**简要地叙述一下实验过程中的感受，以及其他的问题描述和自己的感想。特别是实验中遇到的困难，最后如何解决的。（实验报告中请去除本段）**