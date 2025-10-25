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

本次实验的核心任务分为两个阶段。首先是实现网络接口（`NetworkInterface`）类，使其能够处理IP数据包的发送和接收，并实现ARP协议来解析IP地址到MAC地址的映射。其次是实现路由器（`Router`）类，构建路由表并实现最长前缀匹配算法，以完成IP数据包的转发。

== 实现网络接口类

`NetworkInterface` 类的职责是管理一个网络接口的IP地址和MAC地址，并负责将 `InternetDatagram`（IP数据包）封装成 `EthernetFrame`（以太网帧）发送出去，以及解封装接收到的以太网帧。

=== 在`libsponge/network_interface.hh`中添加必要的成员变量和方法

为了实现ARP协议，我们需要在类中添加几个关键的成员变量：

- `_frames_out`：一个队列，用于缓存所有待发送出去的以太网帧。
- `_arp_cache`：ARP缓存，一个 `std::map`，用于存储IP地址到（MAC地址，剩余超时时间）的映射。这是实现ARP高效查询的核心。
- `_pending_datagrams`：一个 `std::map`，用于暂存那些因为目标MAC地址未知（ARP未解析）而无法立即发送的IP数据包。键是目标IP地址，值是等待该IP的包队列。
- `_arp_requests`：一个 `std::map`，用于记录最近发送过的ARP请求及其剩余超时时间，以避免在短时间内（5秒内）对同一IP重复发送ARP请求。
- `ARP_CACHE_TIMEOUT` 和 `ARP_REQUEST_TIMEOUT`：两个静态常量，分别定义了ARP缓存条目的超时时间（30秒）和ARP请求的重传间隔（5秒）。

*具体代码参见附录*

=== 在`libsponge/network_interface.cc`中实现三个方法

我们在 `.cc` 文件中实现了 `NetworkInterface` 的三个核心方法：

1. `send_datagram(dgram, next_hop)`：当上层（IP层）需要发送一个数据包时，会调用此方法。
  + 首先，它会查询 `_arp_cache` 寻找下一跳IP对应的MAC地址。
  + 如果找到：立即将IP数据包封装成一个以太网帧，设置正确的目的MAC、源MAC和类型（IPv4），然后推入 `_frames_out` 队列等待发送。
  + 如果未找到：说明MAC地址未知。此时，数据包不能立即发送，而是被推入 `_pending_datagrams` 队列中暂存。同时，检查 `_arp_requests` 确认5秒内是否已发送过对该IP的ARP请求。如果未发送过，就构造一个ARP请求（广播），封装成以太网帧推入 `_frames_out`，并记录请求时间。

2. `recv_frame(frame)`：当网络接口从物理层收到一个以太网帧时，会调用此方法。
  + 首先检查帧的目的MAC地址，如果不是本机MAC地址也不是广播地址，则直接丢弃。
  + 如果是IPv4帧：解析 `payload` 为 `InternetDatagram`，并将其返回给上层处理。
  + 如果是ARP帧：解析 `payload` 为 `ARPMessage`。
    + 首先，无条件学习并缓存发送方的IP-MAC映射到 `_arp_cache` 中（设置30秒超时）。
    + 如果是ARP请求 且目标IP是本机IP：构造一个ARP应答，填入本机MAC和IP，然后将应答帧推入 `_frames_out` 队列。
    + 如果是ARP应答：清除 `_arp_requests` 中对应的记录。然后，检查 `_pending_datagrams` 中是否有等待该IP的数据包。如果有，将所有等待的包依次封装成以太网帧（现在我们知道目的MAC了）并推入 `_frames_out` 队列。

3. `tick(ms_since_last_tick)`：这是一个定时器方法，由系统周期性调用。
  + 它负责管理ARP缓存和ARP请求记录的老化。它会遍历 `_arp_cache` 和 `_arp_requests`，将所有条目的剩余时间减去 `ms_since_last_tick`。如果任何条目的时间减到0或以下，就将其从 `map` 中删除。

*具体代码参见附录*

== 实现路由类

路由器的核心功能是转发IP数据包。它通过查询路由表来决定数据包的下一跳地址和应该从哪个接口发送出去。

=== 在`libsponge/router.hh`中添加路由表

我们在 `Router` 类中添加了一个 `std::vector<RouteEntry>` 作为路由表。`RouteEntry` 结构体用于存储路由表的每一行，包含四个关键信息：
- `route_prefix`：路由匹配的目标网段前缀。
- `prefix_length`：前缀的长度（0-32位）。
- `next_hop`：下一跳的IP地址。如果 `next_hop` 为空（`std::optional`），表示该路由是直连网络，下一跳就是数据包的最终目的IP。
- `interface_num`：数据包应该从此索引对应的接口发送出去。

*具体代码参见附录*

=== 在`libsponge/router.cc`中实现`add_route`和`route_one_datagram`

`add_route` 方法比较简单，只是将一条新的路由规则（`RouteEntry`）添加到 `_routing_table` 向量中。

`route_one_datagram` 是路由转发的核心逻辑，其步骤如下：
1. 首先检查IP数据包头的 `ttl` 字段。如果 `ttl` 小于或等于1，意味着数据包在转发后即超时，此时应直接丢弃该包，不再转发。否则，将 `ttl` 减1。
2. 遍历路由表 `_routing_table` 中的所有条目，寻找与数据包目的IP地址 `dgram.header().dst` 匹配的最长前缀。
3. 如果未找到匹配：说明路由表中没有到达该目的地的路径，丢弃该数据包。
4. 如果找到匹配：根据匹配到的最佳路由 `best_route`，确定下一跳 `next_hop_addr`（如果路由条目中指定了 `next_hop`，则用它；否则用数据包的原始目的IP）。
5. 最后，调用该路由指定的 `_interfaces[best_route.interface_num]` 上的 `send_datagram` 方法，将（已更新TTL的）数据包和下一跳地址交给网络接口层去处理（后续的ARP解析等）。

*具体代码参见附录*

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

```bash
ctest -V -R "^arp"
```

运行测试命令，测试结果如 @test-arp。

#figure(
  image("./images/test-arp.png"),
  caption: "测试ARP协议",
  supplement: "图",
) <test-arp>

测试结果显示所有与ARP相关的测试（`arp_...`）均已通过。这表明我们的 `NetworkInterface` 能够正确地：
1. 在收到 `send_datagram` 请求时，当MAC未知时发送ARP请求；
2. 在收到ARP请求时，能正确回复ARP应答；
3. 在收到ARP应答时，能正确更新缓存并发送之前暂存的数据包；
4. 通过 `tick` 方法正确管理ARP缓存条目的超时。

#question[
  === 问题二
  运行`make check_lab1`命令的测试结果展示
]


```bash
make check_lab1
```

运行测试命令，测试结果如 @make-check-lab1。

#figure(
  image("./images/make-check-lab1.png"),
  caption: "运行测试",
  supplement: "图",
) <make-check-lab1>

`make check_lab1` 运行了Lab1的全部测试用例。测试结果显示全部通过（Passed），这证明我们的路由器实现（包括路由表的最长前缀匹配、TTL处理）和网络接口实现（ARP协议、缓存管理）均按预期正常工作。

== 思考题

// 根据你编写的程序运行效果，分别解答以下问题（实验报告中请去除此段）

#question[
  === 问题一
  通过代码，请描述network interface是如何发送一个以太网帧的？
]

当上层（IP层）需要发送一个数据包时，会调用 `send_datagram(dgram, next_hop)` 方法。该方法的实现步骤如下：

+ 首先，它会查询 `_arp_cache` 寻找下一跳IP对应的MAC地址。
+ 如果找到：立即将IP数据包封装成一个以太网帧，设置正确的目的MAC、源MAC和类型（IPv4），然后推入 `_frames_out` 队列等待发送。
+ 如果未找到：说明MAC地址未知。此时，数据包不能立即发送，而是被推入 `_pending_datagrams` 队列中暂存。同时，检查 `_arp_requests` 确认5秒内是否已发送过对该IP的ARP请求。如果未发送过，就构造一个ARP请求（广播），封装成以太网帧推入 `_frames_out`，并记录请求时间。

#question[
  === 问题二
  虽然在此次实验不需要考虑这种情况，但是当network interface发送一个ARP请求后如果没收到一个应答该怎么解决？请思考。
]

如果发送ARP请求后没有收到应答，这可能意味着目标主机已关机、不在该网络上，或者ARP请求（广播）/ARP应答（单播）在传输过程中丢失了。

标准的处理机制是*重传*和*超时*：

1. 重传机制：网络接口不应只发送一次ARP请求就放弃。它应该实现一个重传机制。当发送ARP请求时，启动一个定时器,如果定时器超时后仍未收到ARP应答，接口应该重新发送一次ARP请求，并重置定时器。
2. 限制重传次数：重传不应该是无限的。系统通常会设定一个最大重传次数（例如3到5次）。
3. 处理最终失败：如果在达到最大重传次数后，仍然没有收到任何应答，网络接口必须假定该IP地址在本地链路上是不可达的。
4. 报告错误并丢弃数据包：一旦确定不可达，接口应该丢弃所有在 `_pending_datagrams` 队列中等待该IP地址解析的数据包。向上层（IP层）报告一个“主机不可达”（Host Unreachable）的错误。这通常会触发IP层向原始发送方返回一个ICMP错误消息，最终通知到传输层（如TCP），导致连接超时或失败。

#question[
  === 问题三
  请描述一下你为了记录路由表所建立的数据结构？为什么？
]

为了记录路由表，我使用了一个 `std::vector<RouteEntry>`（C++标准库中的动态数组）作为核心数据结构。

```cpp
//libsponge/router.hh
struct RouteEntry {
    uint32_t route_prefix;      // 路由前缀
    uint8_t prefix_length;     // 前缀长度
    std::optional<Address> next_hop; // 下一跳地址
    size_t interface_num;      // 对应的接口索引
};

std::vector<RouteEntry> _routing_table{};
```
`_routing_table` 存储的是 `RouteEntry` 结构体。每个 `RouteEntry` 实例就代表路由表中的“一行”，包含了路由决策所需的全部信息：要匹配的网段前缀、前缀长度、下一跳IP地址以及数据包应从哪个接口发出。

选择 `std::vector` 这种数据结构的原因如下：
+ 实现简单直观,`add_route`（添加路由）操作可以非常简单地通过 `_routing_table.push_back()`（在末尾追加）来实现。
+ 易于实现最长前缀匹配：路由转发的核心是“最长前缀匹配”算法。使用 `vector`，可以线性扫描每一个路由表项，并通过位运算让每个条目的检查非常快，虽然复杂度是$O(N)$，但是常数是很小的，在实验要求的规模下可以接受，不必使用Trie树来实现。

= 讨论、心得

// 简要地叙述一下实验过程中的感受，以及其他的问题描述和自己的感想。特别是实验中遇到的困难，最后如何解决的。（实验报告中请去除本段）

通过本次实验，我将计算机网络课程中关于数据链路层和网络层的抽象理论知识，转化为了具体的代码实践。在实现 `NetworkInterface` 的过程中，我亲手实现了ARP协议。通过管理ARP缓存、处理超时（`tick`）以及暂存等待解析的数据包，我深刻理解了IP地址是如何在数据链路层被动态解析为MAC地址的。在实现 `Router` 时，核心是实现了“最长前缀匹配”算法和TTL的递减。这让我非常直观地看到了路由器是如何根据路由表，从多条规则中找出最佳路径并转发数据包的。本次实验让我对数据链路层（L2）和网络层（L3）如何协同工作，以及数据包如何在网络中被转发有了更扎实和深刻的认识。

= 附录

== `libsponge/network_interface.hh`

#codly-title("libsponge/network_interface.hh")
#raw(read("../zju-comnet-labs/libsponge/network_interface.hh"), lang: "cpp", block: true)

== `libsponge/network_interface.cc`

#codly-title("libsponge/network_interface.cc")
#raw(read("../zju-comnet-labs/libsponge/network_interface.cc"), lang: "cpp", block: true)

== `libsponge/router.hh`

#codly-title("libsponge/router.hh")
#raw(read("../zju-comnet-labs/libsponge/router.hh"), lang: "cpp", block: true)

== `libsponge/router.cc`

#codly-title("libsponge/router.cc")
#raw(read("../zju-comnet-labs/libsponge/router.cc"), lang: "cpp", block: true)
