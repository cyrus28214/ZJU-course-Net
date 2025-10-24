#import "@preview/showybox:2.0.4": showybox
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#let codly-title(title) = codly(header: align(center)[*#title*])

#set text(size: 12pt, font: "Source Han Serif SC", lang: "cn")

#let cover = {
  v(6em)

  align(center, image("./images/ZJU-Banner.png", width: 50%))

  v(1em)

  align(center)[
    #set text(size: 18pt)
    *本科实验报告*
  ]

  v(4em)

  align(center)[
    #set text(size: 14pt)
    #grid(
      columns: (6em, 20em),
      rows: 2em,
      row-gutter: 1em,
      align: center + horizon,
      grid.hline(start: 1, end: 2, position: bottom),
      "课程名称：", "计算机网络",
      grid.hline(start: 1, end: 2, position: bottom),
      "姓　　名：", "刘仁钦",
      grid.hline(start: 1, end: 2, position: bottom),
      "学　　院：", "计算机科学与技术学院",
      grid.hline(start: 1, end: 2, position: bottom),
      "专　　业：", "计算机科学与技术",
      grid.hline(start: 1, end: 2, position: bottom),
      "学　　号：", "3230106230",
      grid.hline(start: 1, end: 2, position: bottom),
      "指导教师：", "韩劲松",
    )
  ]

  v(1em)

  align(center)[
    #set text(size: 14pt)
    #datetime.today().display("[year]年[month]月[day]日")
  ]
}

#let description = [
  #let underline-box(content) = box(width: 1fr, stroke: (bottom: 0.5pt), outset: (bottom: 2pt))[#align(
    center,
  )[#content]]
  #align(center)[
    #set text(size: 18pt)
    *浙江大学实验报告*

  ]

  实验项目名称：#underline-box[Lab3 网络接口与IP路由器]

  学生姓名：#underline-box[刘仁钦] 专业：#underline-box[计算机科学与技术] 学号：#underline-box[3230106230]
]

#let question(content, ..box_args, color: gray, width: 100%) = [
  // #block(
  //   content,
  //   stroke: (left: 5pt + color.lighten((50%))),
  //   fill: color.lighten(80%),
  //   inset: (left: 1em, top: 0.5em, bottom: 0.5em, right: 0.5em),
  //   width: width)
  #showybox(content)
]

#set heading(numbering: (..nums) => {
  if nums.pos().len() == 1 [
    #numbering("一、", ..nums.pos())
  ] else if nums.pos().len() >= 2 [
    #numbering("1.", ..nums.pos().slice(1))
  ]
})

#show heading.where(level: 1): it => {
  text(size: 14pt)[#it]
  v(6pt)
}
#show heading.where(level: 2): it => {
  text(size: 12pt)[#it]
  v(6pt)
}

#set par(leading: 0.9em)
#set text(size: 12pt)
#show link: set text(fill: blue)
#show raw.where(block: false): it => {
  box(fill: luma(95%), inset: 0.4em, radius: 3pt, baseline: 0.4em)[#it]
}

#cover

#pagebreak(weak: true)

#show outline.entry.where(level: 1): it => {
  v(6pt)
  [*#it*]
}
#outline(title: "目录")

#set page(numbering: "1 / 1")

#description

= 实验目的

- 学习掌握网络接口的工作原理
- 学习掌握ARP地址解析协议相关知识
- 学习掌握IP路由的工作原理

= 实验内容

- 实现network interface，为每个下一跳地址查找（和缓存）以太网地址，即实现地址解析协议ARP。
- 实现简易路由器，对于给定的数据包，确认发送接口以及下一跳的IP地址。

= 主要仪器设备

- 联网的PC机
- Linux虚拟机

= 操作方法与实验步骤

// 对于实验指导中的所有章节（除去第一章节的环境配置外），请在这里介绍实验的具体过程，包括关键代码的解释，关键步骤的截图及说明等，这部分的内容应当与实际操作过程和结果相符。本节也可以再细分小节。（实验报告中请去除本段）

= 实验数据记录和处理

== 实验结果

// // 1. 这里应给出详实的实验结果。分析应有条理，要求采用规范的书面语。
// // 2. 原则上要求使用图片与文字结合的形式说明，因为word和PDF文档不支持视频，所以请不要使用视频文件。
// // 3. 图片请在垂直方向，不要横向。不要用很大的图片，请先做裁剪操作。
// // （实验报告中请去除以上内容）

#question[
  === 问题一
  测试ARP协议的运行截图
]

// 如 @browser-hello 和 @telnet-hello，浏览器访问网页和telnet抓取网页的运行结果。

// #figure(
//   image("./images/browser-hello.png"),
//   caption: "浏览器访问一个网页",
//   supplement: "图",
// ) <browser-hello>

// #figure(
//   image("./images/telnet-hello.png"),
//   caption: "telnet抓取网页",
//   supplement: "图",
// ) <telnet-hello>

// 结果分析：无论是浏览器访问网页还是telnet抓取网页，都能成功获取相同的网页内容。

#question[
  === 问题二
  运行`make check_lab1`命令的测试结果展示
]

// 如 @webget-hello，使用webget抓取网页的运行结果。

// #figure(
//   image("./images/webget-hello.png"),
//   caption: "使用webget抓取网页",
//   supplement: "图",
// ) <webget-hello>

// 结果分析：使用webget抓取网页的运行结果与浏览器访问网页和telnet抓取网页的运行结果一致。我实现的webget程序成功建立了TCP连接，发送了HTTP请求，并接收了响应数据，证明了socket接口的正确使用。

// #question[
//   === 问题三
//   运行`make check_webget`的测试结果
// ]

// 如 @make-check-webget，运行`make check_webget`的测试结果为全部通过。

// #figure(
//   image("./images/make-check-webget.png"),
//   caption: "运行测试",
//   supplement: "图",
// ) <make-check-webget>

// 结果分析：webget程序的自动化测试全部通过，说明实现的HTTP客户端能够正确处理网络请求和响应，符合预期功能要求。

// #question[
//   === 问题四
//   运行`make check_lab0`的测试结果
// ]

// 如 @make-check-lab0，运行`make check_lab0`的测试结果为全部通过。

// #figure(
//   image("./images/make-check-lab0.png"),
//   caption: [运行`make check_lab0`的测试结果],
//   supplement: "图",
// ) <make-check-lab0>

// 结果分析：所有9个测试用例均通过，包括字节流的构造、单次/多次写入、容量限制和大量数据处理等场景，验证了ByteStream实现的正确性和稳定性。说明实现满足了各项实验要求。

== 思考题

// 根据你编写的程序运行效果，分别解答以下问题（实验报告中请去除此段）

#question[
  === 问题一
  通过代码，请描述network interface是如何发送一个以太网帧的？
]

// 一致。

// webget程序的测试结果（@webget-hello）与telnet抓取网页的运行结果（@telnet-hello）是完全一致的。两者都输出了服务器返回的完整HTTP响应，包括HTTP响应头（如HTTP/1.1 200 OK，Content-Type等）和响应体（Hello, CS144!）。

// 这与浏览器访问的结果（@browser-hello）在表现上不一致，但本质上是一致的。浏览器会自动解析HTTP响应，只将渲染后的响应体（HTML内容）显示给用户，而隐藏了响应头。webget和telnet则是原生地打印了从socket接收到的所有原始文本数据。

#question[
  === 问题二
  虽然在此次实验不需要考虑这种情况，但是当network interface发送一个ARP请求后如果没收到一个应答该怎么解决？请思考。
]

// ByteStream通过一个固定大小的容量（capacity）来实现流控制。
// 1. 在构造ByteStream时，会指定一个最大容量。
// 2. ByteStream内部使用一个`std::string _buffer`来缓存数据。
// 3. 它提供一个`remaining_capacity()`方法，用于计算当前缓冲区还能接收多少字节的数据，计算方式是 `_capacity - _buffer.size()`。
// 4. 当调用`write`函数尝试写入新数据时，函数会首先检查`remaining_capacity()`。
// 5. 实际能写入的字节数是 传入的数据长度 和 剩余可用容量 之间的较小值。
// 6. ByteStream只接收这部分数据存入`_buffer`，并返回实际写入的字节数。
// 7. 这样，写入方就不会向缓冲区写入超过其容量的数据。只有当读取方通过`pop_output`或`read`消费了数据，`_buffer`变小，`remaining_capacity()`变大后，写入方才能继续写入更多数据。这就实现了一种基于缓冲区的流控制。

#question[
  === 问题三
  请描述一下你为了记录路由表所建立的数据结构？为什么？
]

// 当遇到超出capacity范围的数据流时，ByteStream的处理方式是：*只接收当前容量允许的部分数据，并丢弃超出部分。*

// 它会计算出剩余空间`available_space`，然后只从传入的`data`字符串中截取`available_space`这么长的子串，追加到内部缓冲区`_buffer`中。write函数会返回实际写入的字节数。写入方如果发现返回值小于自己尝试写入的长度，就知道了部分数据未被接收，它需要在稍后（等待读取方消费数据）再尝试发送剩余的数据。

// 如果不限制流的长度，即没有`_capacity`限制：
// 那么当写入方的写入速度持续快于读取方的读取速度时，数据会不断在ByteStream的内部缓冲区中堆积。由于`std::string`可以动态增长，这个缓冲区会越变越大，最终会耗尽程序所有可用的系统内存，导致程序因内存溢出而崩溃。流控制就是为了防止这种情况发生。

= 讨论、心得

// 简要地叙述一下实验过程中的感受，以及其他的问题描述和自己的感想。特别是实验中遇到的困难，最后如何解决的。（实验报告中请去除本段）

// 通过这次实验，我把课堂上学到的网络理论知识和实际动手操作结合了起来。在实现webget的过程中，我第一次亲手构造了HTTP协议的GET请求报文，并通过TCPSocket发送出去。这个过程让我非常直观地理解了像HTTP这样的应用层协议是如何运行在TCP这个传输层之上的。

// 实现ByteStream则让我对TCP的“字节流”和“缓冲区”概念有了更深的体会。核心在于理解“流控制”的重要性。通过设置一个固定的capacity，我们防止了写入方无限制地发送数据。如果写入速度快于读取速度，缓冲区会填满，write操作就会受阻。这就实现了一种反压机制，避免了因数据堆积而耗尽内存。这个小小的ByteStream模拟，让我明白了流控制是保证网络通信稳定和资源可控的关键机制。
