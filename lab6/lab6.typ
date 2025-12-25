#import "@preview/showybox:2.0.4": showybox
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#let codly-title(title) = codly(header: align(center)[*#title*])

#set text(size: 12pt, font: "Noto Serif CJK SC", lang: "cn")
#show raw: set text(font: ("JetBrainsMono NF", "Noto Sans CJK SC"))

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

  实验项目名称：#underline-box[Lab4 TCP 接收方 (Receiver) 与发送方 (Sender)]

  学生姓名：#underline-box[刘仁钦] 专业：#underline-box[计算机科学与技术] 学号：#underline-box[3230106230]
]

#let question(content, ..box_args, color: gray, width: 100%) = [
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

- 学习如何设计网络应用协议
- 掌握Socket编程接口编写基本的网络应用软件

= 实验内容

#set enum(numbering: "1.a.")

- 根据自定义的协议规范，使用Socket编程接口编写基本的网络应用软件。
- 掌握C语言形式的Socket编程接口用法，能够正确发送和接收网络数据包
- 开发一个客户端，实现人机交互界面和与服务器的通信
- 开发一个服务端，实现并发处理多个客户端的请求
- 程序界面不做要求，使用命令行或最简单的窗体即可
- 功能要求如下：
  1. 运输层协议采用TCP
  2. 客户端采用交互菜单形式，用户可以选择以下功能
    1. 连接：请求连接到指定地址和端口的服务端
    2. 断开连接：断开与服务端的连接
    3. 获取时间: 请求服务端给出当前时间
    4. 获取名字：请求服务端给出其机器的名称
    5. 活动连接列表: 请求服务端给出当前连接的所有客户端信息（编号、IP地址、端口等）
    6. 发消息：请求服务端把消息转发给对应编号的客户端，该客户端收到后显示在屏幕上
    7. 退出：断开连接并退出客户端程序
  3. 服务端接收到客户端请求后，根据客户端传过来的指令完成特定任务：
    1. 向客户端传送服务端所在机器的当前时间
    2. 向客户端传送服务端所在机器的名称
    3. 向客户端传送当前连接的所有客户端信息
    4. 将某客户端发送过来的内容转发给指定编号的其他客户端
    5. 采用异步多线程编程模式，正确处理多个客户端同时连接，同时发送消息的情况
- 根据上述功能要求，设计一个客户端和服务端之间的应用通信协议


= 主要仪器设备

- 联网的PC机
- Linux虚拟机

= 操作方法与实验步骤

// 本次实验的核心任务分为三个阶段。首先是实现序列号包装和解包装函数，用于在32位循环序列号和64位绝对序列号之间进行转换。其次是实现TCP接收方，负责接收TCP段、重组字节流并计算确认号和窗口大小。最后是实现TCP发送方，负责将数据分段发送、处理确认和超时重传。

// == 实现序列号包装和解包装

// TCP协议使用32位循环序列号，但在内部处理时需要使用64位绝对序列号。`wrapping_integers` 模块提供了两者之间的转换功能。

// === 在`libsponge/wrapping_integers.cc`中实现`wrap`和`unwrap`函数

// `wrap` 函数将64位绝对序列号转换为32位循环序列号。实现较为简单，只需要将绝对序列号与初始序列号（ISN）相加，然后取模2^32即可。

// `unwrap` 函数将32位循环序列号转换为64位绝对序列号，这是本次实验的难点之一。由于32位序列号会循环，我们需要找到最接近checkpoint的绝对序列号。实现思路如下：

// 1. 计算偏移量：`offset = n - isn`（32位无符号减法），这是结果的低32位
// 2. 利用checkpoint确定周期：将checkpoint的高32位与offset拼接，得到候选值`t = (checkpoint & 0xFFFFFFFF00000000) | offset`，这样`t`和`checkpoint`在同一个2^32周期内
// 3. 判断是否需要调整到相邻周期：
//    - 如果`t > checkpoint`且差距超过半个周期（2^31），说明应该使用上一个周期的值，即`t - 2^32`（但要防止uint64下溢）
//    - 如果`t < checkpoint`且差距超过半个周期，说明应该使用下一个周期的值，即`t + 2^32`
// 4. 返回最接近checkpoint的值。

// 具体代码参见附录。

// == 实现TCP接收方

// TCP接收方负责接收TCP段，将数据重组为连续的字节流，并计算确认号和窗口大小反馈给发送方。

// === 在`libsponge/tcp_receiver.hh`中添加必要的成员变量

// 为了实现TCP接收方的功能，我们需要添加以下成员变量：

// - `_isn`：存储从远程发送方接收到的初始序列号（ISN），使用 `std::optional` 表示是否已收到SYN
// - `_fin_received`：标记是否已收到FIN标志

// _具体代码参见附录_

// === 在`libsponge/tcp_receiver.cc`中实现三个方法

// 1. `segment_received(seg)`：处理接收到的TCP段
//    + 首先检查是否处于Listen状态（`_isn`为空）。如果是，则检查是否为SYN包。只有收到SYN包才能建立连接，否则丢弃数据包。
//    + 对于已建立连接的情况，需要将TCP段的payload数据放入流重组器。关键步骤包括：
//      - 使用`unwrap`将32位序列号转换为64位绝对序列号
//      - 将绝对序列号转换为流索引（排除SYN和FIN）
//      - 对于SYN包，payload从绝对序列号1开始（流索引0）
//      - 对于普通包，流索引 = 绝对序列号 - 1
//      - 调用`_reassembler.push_substring`将数据放入流重组器
//    + 如果收到FIN标志，标记`_fin_received`为true

// 2. `ackno()`：计算并返回确认号
//    + 如果尚未收到SYN（处于Listen状态），返回空
//    + 否则，查询流重组器中已写入的字节数，将其转换为绝对序列号（需要加上SYN占用的1个序列号）
//    + 如果已收到FIN且流已结束，还需要加上FIN占用的1个序列号
//    + 最后使用`wrap`将绝对序列号转换为32位序列号返回

// 3. `window_size()`：计算窗口大小
//    + 窗口大小 = 总容量 - 流重组器中已存数据量
//    + 已存数据量 = 已写入字节数 - 已读取字节数

// _具体代码参见附录_

// == 实现TCP发送方

// TCP发送方负责将ByteStream中的数据分段发送，处理接收方的确认和窗口大小，并实现超时重传机制。

// === 在`libsponge/tcp_sender.hh`中添加必要的成员变量

// 为了实现TCP发送方的功能，我们需要添加以下成员变量：

// - `_ackno`：已确认的绝对序列号
// - `_window_size`：远程接收方通告的窗口大小
// - `_outstanding_segments`：一个`std::map`，用于存储已发送但尚未确认的段（键为段的起始绝对序列号）
// - `_rto`：当前的重传超时时间（RTO）
// - `_timer`：重传计时器
// - `_timer_running`：计时器是否正在运行
// - `_consecutive_retransmissions`：连续重传计数
// - `_syn_sent`和`_fin_sent`：标记是否已发送SYN和FIN

// _具体代码参见附录_

// === 在`libsponge/tcp_sender.cc`中实现核心方法

// 1. `fill_window()`：填充窗口，尽可能多地发送数据
//    + 计算窗口右边界：`window_right = _ackno + effective_window`（如果窗口大小为0，视为1）
//    + 循环发送，直到`_next_seqno >= window_right`：
//      - 如果尚未发送SYN，发送SYN段
//      - 计算可发送的payload大小（不超过窗口大小、MAX_PAYLOAD_SIZE和可用数据量）
//      - 如果满足条件，添加FIN标志
//      - 发送段并更新`_next_seqno`
//      - 如果设置了FIN，退出循环

// 2. `ack_received(ackno, window_size)`：处理接收到的确认
//    + 将ackno转换为绝对序列号
//    + 如果ackno不可靠（大于`_next_seqno`），直接丢弃
//    + 更新窗口大小
//    + 遍历`_outstanding_segments`，移除已被确认的段
//    + 如果确认了新数据，重置计时器和RTO，重置连续重传计数
//    + 更新`_ackno`
//    + 调用`fill_window()`继续发送数据

// 3. `tick(ms_since_last_tick)`：处理时间流逝
//    + 如果计时器正在运行，更新计时器
//    + 如果计时器超时，重传序列号最小的未确认段
//    + 如果窗口大小不为0，将RTO加倍（指数退避）
//    + 增加连续重传计数

// 4. `send_empty_segment()`：发送空段
//    + 创建一个payload为空的TCP段，设置正确的序列号

// 5. `bytes_in_flight()`：计算正在传输的字节数
//    + 遍历`_outstanding_segments`，累加所有段的`length_in_sequence_space()`

// _具体代码参见附录_

// = 实验数据记录和处理

// == 实验结果

// #question[
//   === 问题一
//   运行 `ctest -R wrap` 命令的测试结果展示
// ]

// ```bash
// cd zju-comnet-labs/build
// ctest -R wrap
// ```

// 运行测试命令，测试结果如 @test-wrap。

// #figure(
//   image("./images/test-wrap.png"),
//   caption: [运行 `ctest -R wrap` 命令的测试结果],
//   supplement: "图",
// ) <test-wrap>

// #question[
//   === 问题二
//   运行`make check_lab2`命令的测试结果展示
// ]

// ```bash
// cd zju-comnet-labs/build
// make check_lab2
// ```

// 运行测试命令，测试结果如 @make-check-lab2。

// #figure(
//   image("./images/make-check-lab2.png"),
//   caption: [运行 `make check_lab2` 命令的测试结果],
//   supplement: "图",
// ) <make-check-lab2>

== 思考题

// #question[
//   === 问题一
//   通过代码，请描述TCPSender是如何发送出一个segment的？
// ]

// TCPSender通过`fill_window()`方法发送segment，具体流程如下：

// 1. 首先计算窗口右边界：`window_right = _ackno + effective_window`（如果窗口大小为0，视为1）
// 2. 循环发送，直到`_next_seqno >= window_right`：
//    - 如果尚未发送SYN，创建SYN段并发送
//    - 否则，计算可发送的payload大小（不超过窗口大小、MAX_PAYLOAD_SIZE和可用数据量）
//    - 从`_stream`中读取数据，创建TCP段
//    - 如果满足条件（流已结束且窗口有空间），添加FIN标志
//    - 设置段的序列号（使用`wrap`将绝对序列号转换为32位序列号）
//    - 将段加入`_outstanding_segments`进行追踪
//    - 将段推入`_segments_out`队列等待发送
//    - 更新`_next_seqno`
//    - 如果这是第一个待发送的段，启动重传计时器
//    - 如果设置了FIN，退出循环

// 3. 发送的段会被TCPConnection层取出，添加接收方的ackno和window size后发送到网络。

// #question[
//   === 问题二
//   请用自己的理解描述一下TCPSender超时重传的整个流程。
// ]

// TCPSender的超时重传机制通过`tick()`方法实现，整个流程如下：

// 1. 计时器管理：当发送第一个段时，启动重传计时器（`_timer_running = true`，`_timer = 0`）
// 2. 时间更新：系统周期性调用`tick(ms_since_last_tick)`，更新计时器：`_timer += ms_since_last_tick`
// 3. 超时检测：如果`_timer >= _rto`，说明超时
// 4. 重传处理：
//    - 重置计时器：`_timer = 0`
//    - 重传序列号最小的未确认段（`_outstanding_segments`中的第一个）
//    - 如果窗口大小不为0，将RTO加倍（指数退避）：`_rto *= 2`
//    - 增加连续重传计数：`_consecutive_retransmissions++`
// 5. 确认处理：当收到ACK确认时（`ack_received`）：
//    - 如果确认了新数据，重置计时器：`_timer = 0`
//    - 重置RTO为初始值：`_rto = _initial_retransmission_timeout`
//    - 重置连续重传计数：`_consecutive_retransmissions = 0`
// 6. 停止计时器：如果所有数据都被确认（`_outstanding_segments`为空），停止计时器：`_timer_running = false`

// 这种机制确保了TCP的可靠传输：如果数据包丢失，发送方会在超时后重传，直到收到确认。

// #question[
//   === 问题三
//   请描述一下你为了重传未被确认的段建立的数据结构？为什么？
// ]

// 为了追踪已发送但尚未确认的段，我使用了一个`std::map<uint64_t, TCPSegment>`作为核心数据结构，键是段的起始绝对序列号，值是TCP段本身。

// ```cpp
// //libsponge/tcp_sender.hh
// std::map<uint64_t, TCPSegment> _outstanding_segments{};
// ```

// 选择`std::map`这种数据结构的原因如下：

// 1. 自动排序：`std::map`是有序容器，按照序列号自动排序。可以轻松找到序列号最小的未确认段，只需要访问`begin()`迭代器即可。

// 2. 高效查找和删除：当收到ACK确认时，需要快速找到并删除已被确认的段。`std::map`的查找和删除操作都是O(log n)复杂度，效率较高。

// 3. 键的唯一性：每个段的起始序列号是唯一的，正好适合作为map的键。

// 4. 便于遍历：当需要计算`bytes_in_flight()`时，可以方便地遍历所有未确认的段。

// #question[
//   === 问题四
//   请思考为什么TCPSender实现中有一个发送空段的方法，能描述一下你是怎么理解的吗？
// ]

// `send_empty_segment()`方法用于发送一个payload为空的TCP段。这个方法的主要用途是：

//   1. 发送纯ACK段：当接收方收到数据但不需要发送数据时，可以发送一个只包含ACK标志的段来确认收到的数据。虽然TCPSender本身不设置ACK标志（这由TCPConnection层完成），但空段为上层提供了发送ACK的载体。

// 2. 窗口更新：当接收方的窗口大小发生变化时，即使没有数据要发送，也需要发送一个段来通知发送方新的窗口大小。空段可以携带这个信息。

// 3. 保持连接活跃：在某些情况下，可能需要发送空段来保持TCP连接的活跃状态。

// 4. 测试和调试：在测试场景中，可能需要发送空段来验证TCP协议的各种行为。

// 在我的实现中，`send_empty_segment()`简单地创建一个空的TCP段，设置正确的序列号（使用`wrap(_next_seqno, _isn)`），然后直接推入`_segments_out`队列。这个段不会被加入`_outstanding_segments`，因为它不占用序列号空间（没有SYN、FIN或payload），也不需要被确认。

= 讨论、心得

// 通过本次实验，我深入理解了TCP协议的核心机制。在实现`wrapping_integers`时，我学会了如何处理32位循环序列号和64位绝对序列号之间的转换，这是TCP协议实现的基础。在实现`TCPReceiver`时，我理解了TCP接收方如何接收乱序到达的段、重组字节流，以及如何计算确认号和窗口大小来反馈给发送方。在实现`TCPSender`时，我亲手实现了TCP的可靠传输机制：窗口控制、超时重传、指数退避等。

// 本次实验中最困难的部分是`unwrap`函数的实现。由于32位序列号会循环，需要找到最接近checkpoint的绝对序列号。我发现可以利用checkpoint的高32位直接确定周期，然后根据距离判断是否需要调整到相邻周期，这样实现更简洁高效。

// 另一个难点是TCP发送方的状态管理。需要正确维护已发送但未确认的段、重传计时器、RTO等状态，确保在各种情况下（正常发送、收到ACK、超时重传等）都能正确工作。在实现 Sender 时，需要处理多种状态（如 Timer 运行时收到 ACK、窗口为 0 时的探测等），我体会到了 TCP 协议作为协议的复杂性。

= 附录

// == `libsponge/wrapping_integers.cc`

// #codly-title("libsponge/wrapping_integers.cc")
// #raw(read("../zju-comnet-labs/libsponge/wrapping_integers.cc"), lang: "cpp", block: true)

// == `libsponge/tcp_receiver.hh`

// #codly-title("libsponge/tcp_receiver.hh")
// #raw(read("../zju-comnet-labs/libsponge/tcp_receiver.hh"), lang: "cpp", block: true)

// == `libsponge/tcp_receiver.cc`

// #codly-title("libsponge/tcp_receiver.cc")
// #raw(read("../zju-comnet-labs/libsponge/tcp_receiver.cc"), lang: "cpp", block: true)

// == `libsponge/tcp_sender.hh`

// #codly-title("libsponge/tcp_sender.hh")
// #raw(read("../zju-comnet-labs/libsponge/tcp_sender.hh"), lang: "cpp", block: true)

// == `libsponge/tcp_sender.cc`

// #codly-title("libsponge/tcp_sender.cc")
// #raw(read("../zju-comnet-labs/libsponge/tcp_sender.cc"), lang: "cpp", block: true)
