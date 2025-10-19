#import "@preview/showybox:2.0.4": showybox

#set text(size: 12pt, font: ("Source Han Serif SC"), lang: "cn")

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
      "指导教师：", "韩劲松"
    )
  ]

  v(1em)

  align(center)[
    #set text(size: 14pt)
    #datetime.today().display("[year]年[month]月[day]日")
  ]

}

#let description = [
  #let underline-box(content) = box(width: 1fr, stroke: (bottom: 0.5pt), outset: (bottom: 2pt))[#align(center)[#content]]
  #align(center)[
    #set text(size: 18pt)
    *浙江大学实验报告*

  ]

  实验项目名称：#underline-box[Lab1 WireShark软件初探和常见网络命令的使用]

  学生姓名：#underline-box[刘仁钦] 专业：#underline-box[计算机科学与技术] 学号：#underline-box[3230106230]
]

#let question(content, ..box_args, color: gray, width: 100%) = [
  // #block(
  //   content,
  //   stroke: (left: 5pt + color.lighten((50%))),
  //   fill: color.lighten(80%),
  //   inset: (left: 1em, top: 0.5em, bottom: 0.5em, right: 0.5em),
  //   width: width)
  #showybox(title: "问题", content)
]

#set heading(numbering: (..nums) => {
  if nums.pos().len() == 1 [
    #numbering("一、", ..nums.pos())
  ]
  else if nums.pos().len() == 2 [
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

#set page(numbering: "1 / 1")

#description

= 实验目的和要求

- 初步了解WireShark软件的界面和功能
- 熟悉各类常用网络命令的使用

= 实验内容和原理

- Wireshark是PC上使用最广泛的免费抓包工具，可以分析大多数常见的协议数据包。有Windows版本、Linux版本和Mac版本，可以免费从网上下载
- 初步掌握网络协议分析软件Wireshark的使用，学会配置过滤器
- 根据要求配置Wireshark，捕获某一类协议的数据包
- 在PC机上熟悉常用网络命令的功能和用法: Ping.exe，Netstat.exe, Telnet.exe, Tracert.exe, Arp.exe, Ipconfig.exe, Net.exe, Route.exe, Nslookup.exe
- 利用WireShark软件捕捉上述部分命令产生的数据包

= 主要仪器设备

- 联网的PC机
- WireShark协议分析软件

= 操作方法与实验步骤

1. 安装Wireshark软件
2. 配置网络包捕获软件，捕获所有类型的数据包
3. 配置网络包捕获软件，只捕获特定类型的包
4. 在Windows命令行方式下，执行适当的命令，完成以下功能（请以管理员身份打开命令行）：
  1. 测试到特定地址的联通性、数据包延迟时间
  2. 显示本机的网卡物理地址、IP地址 
  3. 显示本机的默认网关地址、DNS服务器地址 
  4. 显示本机记录的局域网内其它机器IP地址与其物理地址的对照表
  5. 显示从本机到达一个特定地址的路由 
  6. 显示某一个域名的IP地址
  7. 显示已经与本机建立TCP连接的端口、IP地址、连接状态等信息
  8. 显示本机的路由表信息，并手工添加一个路由
  9. 显示本机的NetBIOS名称表
  10. 显示局域网内某台机器的共享资源 
  11. 使用telnet连接WEB服务器的端口，输入（<cr>表示回车）获得该网站的主页内容：
    i. GET / HTTP/1.1
    ii. Host:www.baidu.com
5. 利用WireShark实时观察在执行上述命令时，哪些命令会额外产生数据包，并记录这些数据包的种类。

= 实验结果与分析

== 实验结果

// 1. 这里应给出详实的实验结果。分析应有条理，要求采用规范的书面语。
// 2. 原则上要求使用图片与文字结合的形式说明，因为word和PDF文档不支持视频，所以请不要使用视频文件。
// 3. 图片请在垂直方向，不要横向。不要用很大的图片，请先做裁剪操作。
// （实验报告中请去除以上内容）

#question[
  运行Wireshark软件，主界面是由哪几个部分构成？各有什么作用？
]

#figure(
  image("./images/wireshark-capture-all.png", width: 70%),
  caption: "Wireshark主界面",
  supplement: "图"
)

1. 菜单栏：包括文件、编辑、视图、跳转、捕获、分析等子菜单。
2. 工具栏：常用功能（如开始/停止/重新开始捕获等）的快捷按钮。
3. 过滤器输入框：用于输入显示过滤器规则，实时筛选已捕获到的数据包。
4. 数据包列表面板：显示所有捕获到的数据包的概览信息，包括编号、时间戳、源/目的地址、协议类型、长度和信息简述。
5. 数据包详细信息面板：显示在列表面板中选中的数据包的详细分层解析结果，从数据链路层到应用层。
6. 数据包字节面板：以十六进制和 ASCII 码形式显示选中数据包的原始字节数据。

#question[
  开始捕获网络数据包，你看到了什么？有哪些协议？
]

在开始捕获网络数据包后，即使在没有主动进行任何网络操作的情况下，数据包列表也会迅速增长。我看到了大量的后台流量，主要协议包括：

1. ARP：地址解析协议，用于在局域网内将 IP 地址解析为 MAC 地址。
2. TCP：传输控制协议，承载大量应用层数据。
3. HTTP：如果浏览器处于打开状态，会有未加密的网页访问流量。
4. TLSv1.3：传输层安全协议，用于加密 HTTPS 等安全通信。
5. DNS：进行域名到 IP 地址的查询。
6. ICMP：互联网控制消息协议，用于网络诊断和错误报告。
7. ICMPv6：ICMP 协议在 IPv6 环境下的对应版本。

#question[
  配置显示过滤器，让界面只显示某一协议类型的数据包。
]

在过滤器输入框中输入`http`，只显示HTTP协议的数据包：

#figure(
  image("./images/wireshark-display-filter-http.png", width: 70%),
  caption: "只显示HTTP协议的数据包",
  supplement: "图"
)

#question[
  配置捕获过滤器，只捕获某类协议的数据包。
]

#figure(
  image("./images/wireshark-capture-filter-tcp.png", width: 70%),
  caption: "只捕获TCP协议的数据包",
  supplement: "图"
)

#question[
  利用ping, ipconfig, arp, tracert, nslookup, nbstat, route, netstat, NET SHARE, telnet命令完成在实验步骤4中列举的11个功能。
]

#figure(
  image("./images/ping.png", width: 70%),
  caption: "ping命令",
  supplement: "图"
)

#figure(
  image("./images/ipconfig.png", width: 70%),
  caption: "ipconfig命令",
  supplement: "图"
)

#figure(
  image("./images/arp.png", width: 50%),
  caption: "arp命令",
  supplement: "图"
)

#figure(
  image("./images/tracert.png", width: 50%),
  caption: "tracert命令",
  supplement: "图"
)

#figure(
  image("./images/nslookup.png", width: 70%),
  caption: "nslookup命令",
  supplement: "图"
)

#figure(
  image("./images/nbstat.png", width: 50%),
  caption: "nbstat命令",
  supplement: "图"
)

#figure(
  image("./images/route-print.png", width: 50%),
  caption: "route print命令",
  supplement: "图"
)

#figure(
  image("./images/route-add.png", width: 50%),
  caption: "route add命令",
  supplement: "图"
)

#figure(
  image("./images/netstat.png", width: 50%),
  caption: "netstat命令",
  supplement: "图"
)

#figure(
  image("./images/net-share.png", width: 70%),
  caption: "net share命令",
  supplement: "图"
)

#figure(
  image("./images/telnet.png", width: 70%),
  caption: "telnet命令（输入指令无回显）",
  supplement: "图"
)

#question[
  观察使用ping命令时在WireShark中出现的数据包并捕获。这是什么协议？
]

如@wireshark-ping，这是ICMP协议的数据包。

#figure(
  image("./images/wireshark-ping.png", width: 70%),
  caption: "ping命令",
  supplement: "图"
) <wireshark-ping>


#question[
  观察使用tracert命令时在WireShark中出现的数据包并捕获。这是什么协议？
]

如@wireshark-tracert，也是ICMP协议的数据包。

#figure(
  image("./images/wireshark-tracert.png", width: 70%),
  caption: "tracert命令",
  supplement: "图"
) <wireshark-tracert>

#question[
  观察使用nslookup命令时在WireShark中出现的数据包并捕获。这是什么协议？
]

如@wireshark-nslookup，协议为DNS（over UDP）。

#figure(
  image("./images/wireshark-nslookup.png", width: 70%),
  caption: "nslookup命令",
  supplement: "图"
) <wireshark-nslookup>

#question[
  观察使用telnet命令时在WireShark中出现的数据包并捕获。这是什么协议？
]

如@wireshark-telnet，协议为TCP。

#figure(
  image("./images/wireshark-telnet.png", width: 70%),
  caption: "telnet命令",
  supplement: "图"
) <wireshark-telnet>

== 思考题

#question[
  WireShark的两种过滤器有什么不同？
]

1. 捕获过滤器：在开始抓包之前进行配置。只有符合条件的数据包才会被实际记录。可以减少捕获的数据量，减轻系统负担，使抓包文件更小、更高效。

2. 显示过滤器：在数据包已经捕获之后进行配置。它定义了在 Wireshark 主界面显示哪些已经捕获的数据包。不符合条件的数据包只是被隐藏起来，但仍在抓包文件中。可以方便用户在大量已捕获数据中查找、分析特定类型的数据包。

#question[
 哪些网络命令会产生在WireShark中产生数据包，为什么？
]

见@table-commands。

// 命令	是否产生数据包	产生的数据包类型	产生原因/说明
// ping	是	ICMP (Echo Request/Reply)	用于测试主机之间的连通性和往返时延。
// tracert	是	ICMP (Time Exceeded, Echo Request/Reply)	通过发送一系列数据包并故意超时，获取数据包到达目的地的每一跳路由信息。
// nslookup	是	DNS (Query/Response)	用于查询域名对应的 IP 地址，需要向 DNS 服务器发送请求。
// telnet	是	TCP (SYN, ACK, PSH, FIN, etc.)，以及承载的 应用层数据 (如 HTTP 请求)	尝试与远程主机的特定端口建立 TCP 连接并进行数据传输。
// arp -a	否（一般不主动）	ARP (Request/Reply)	显示本地 ARP 缓存表，一般不主动发包。但在查询一个不存在于缓存的 IP 地址时，可能会触发 ARP 请求。
// ipconfig	否	无	仅显示或配置本地网络接口信息，不涉及网络通信。
// netstat	否	无	仅显示本机已建立的连接、路由表等信息，不涉及网络通信。
// route	否	无	仅用于查看或修改本地路由表，不涉及网络通信。
// nbstat	否	无	仅显示本地 NetBIOS 名称表。
// NET SHARE	否	无	仅显示本地共享资源信息
#[

#set text(size: 10pt)
#figure(
table(
  columns: 3,
  align: (col, row) => {
    if row == 0 {
      horizon + center
    } else {
      horizon + left
    }
  },
  [*命令*], [*数据包*], [*原因*],
  [`ping`], [ICMP], [用于测试主机之间的连通性和往返时延。],
  [`tracert`], [ICMP], [通过发送一系列数据包并超时，获取到达目的地的每一跳路由信息。],
  [`nslookup`], [DNS], [用于查询域名对应的 IP 地址，需要向 DNS 服务器发送请求。],
  [`telnet`], [TCP], [尝试与远程主机的特定端口建立 TCP 连接并进行数据传输。],
  [`arp -a`], [无], [显示本地 ARP 缓存表，一般不主动发包。],
  [`ipconfig`], [无], [仅显示或配置本地网络接口信息，不涉及网络通信。],
  [`netstat`], [无], [仅显示本机已建立的连接、路由表等信息，不涉及网络通信。],
  [`route`], [无], [仅用于查看或修改本地路由表，不涉及网络通信。],
  [`nbstat`], [无], [仅显示本地 NetBIOS 名称表。],
  [`NET SHARE`], [无], [仅显示本地共享资源信息]
),
caption: "网络命令与数据包",
supplement: "表"
) <table-commands>

]

#question[
  ping发送的是什么类型的协议数据包？什么时候会出现ARP消息？ping一个域名和ping一个IP地址出现的数据包有什么不同？
]

`ping`命令发送和接收的是 ICMP数据包。ICMP 位于 IP 层之上，用于传输控制消息和错误报告。

当主机首次 `ping` 局域网内一个 IP 地址，且该 IP 的 MAC 地址不在 ARP 缓存中时，会先出现 ARP 消息。

`ping`一个域名，多了一个 DNS 查询过程，系统会向配置的DNS服务器发送一个DNS查询请求。从DNS响应拿到IP地址后，后续步骤就和 `ping` 一个IP地址完全相同了。

= 讨论、心得

// 实验过程中遇到的困难，得到的经验教训，对本实验安排的更好建议（实验报告中请去除此段）

通过本次实验，我对计算机网络的基本概念和实践操作有了更深刻的理解。之前学习的TCP/IP协议栈、各种网络协议和命令都只是停留在书本上的抽象概念，而通过Wireshark这款强大的工具，我第一次“亲眼”看到了这些协议在网络中是如何以数据包的形式具象化地进行交互和传输的。

本次实验不仅让我熟练掌握了多种常用网络命令的用法和Wireshark的基本操作，更激发了我对计算机网络的兴趣，也为后续更深入的学习打下了坚实的基础。