#import "@preview/showybox:2.0.4": showybox
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()

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

#set page(numbering: "1 / 1")

#description

= 实验目的

- 学习掌握Linux虚拟机的用法
- 学习掌握网页的抓取方法
- 学习掌握ByteStream的相关知识

= 实验内容

-安装配置Linux虚拟机并在其上完成本次实验。
- 使用应用层程序访问网页。
- 编写小程序webget，通过网络获取web页面。
- 实现字节流ByteStream：
  - 字节流可以从写入端写入，并以相同的顺序，从读取端读取；
  - 字节流是有限的，写者可以终止写入。而读者可以在读取到字节流末尾时，产生EOF标志，不再读取；
  - 写入的字节流可能会很长，必须考虑到字节流大于缓冲区大小的情况。

= 主要仪器设备

- 联网的PC机
- Linux虚拟机

= 操作方法与实验步骤

// 对于实验指导中的所有章节（除去第一章节的环境配置外），请在这里介绍实验的具体过程，包括关键代码的解释，关键步骤的截图及说明等，这部分的内容应当与实际操作过程和结果相符。本节也可以再细分小节。（实验报告中请去除本段）

#counter(heading).update((4, 1)) // start from 2.

== 使用网络

=== 浏览器访问一个网页

用浏览器访问 http://cs144.keithw.org/hello ，可以看到结果如@browser-hello。

#figure(
  image("./images/browser-hello.png"),
  caption: "浏览器访问一个网页",
  supplement: "图"
) <browser-hello>

=== 利用telnet抓取一个网页

使用telnet连接到 http://cs144.keithw.org ，按照实验指导中的步骤输入命令，可以看到结果如@telnet-hello。第一个telnet指令演示了如何关闭telnet连接，第二个telnet指令演示了如何发送一个HTTP请求，并抓取网页。

#figure(
  image("./images/telnet-hello.png"),
  caption: "利用telnet抓取一个网页",
  supplement: "图"
) <telnet-hello>

== Webget

=== 建立仓库

执行以下命令：

```bash
# in virtual machine
# ssh-keygen -t ed25519 -C cs144
# submit public key to github.com
git clone git@github.com:sibo715/zju-comnet-labs.git
cd zju-comnet-labs
mkdir build
cd build
cmake ..
make
```

可以看到结果如 @make-webget-1 和 @make-webget-2。

#figure(
  image("./images/make-webget-1.png"),
  caption: "构建webget（1/2）",
  supplement: "图"
) <make-webget-1>

#figure(
  image("./images/make-webget-2.png"),
  caption: "构建webget（2/2）",
  supplement: "图"
) <make-webget-2>

=== OS Stream Socket

Linux内核提供了 *stream socket* ，它像一种文件描述符。当两个 stream socket 连在一起时，写入其中一个socket的字节最终将被另一个socket以相同的顺序读出。下图描述的是基于TCP/IP协议的 Client-Server 通信流程。如 @stream-socket。

#figure(
  image("./images/stream-socket.png"),
  caption: "Client-Server 通信流程",
  supplement: "图"
) <stream-socket>

=== 实现 webget

webget是一个简单的HTTP客户端程序，用于通过网络获取网页内容。它模拟了浏览器发送HTTP请求的过程

==== 修改 `get_URL` 函数

该函数接收主机名和路径作为参数，通过TCP socket建立连接并发送HTTP请求。

```diff
 void get_URL(const string &host, const string &path) {
     // the "eof" (end of file).
 
     cerr << "Function called: get_URL(" << host << ", " << path << ").\n";
-    cerr << "Warning: get_URL() has not been implemented yet.\n";
+    TCPSocket sock;
+    sock.connect(Address{host, "http"});
+
+    string request{"GET " + path + " HTTP/1.1\r\nHost: " + host + "\r\nConnection: close\r\n\r\n"};
+    sock.write(request);
+
+    while (!sock.eof()) {
+        cout << sock.read();
+    }
+    
+    sock.close();
 }
```

1. 使用`TCPSocket`类创建socket，并通过`Address{host, "http"}`解析主机名并连接到HTTP服务。
2. 按照HTTP/1.1协议格式构造GET请求，包含请求行、Host头和Connection: close头。
3. 使用`sock.write()`将HTTP请求发送到服务器。
4. 通过`while (!sock.eof())`循环持续读取服务器响应，直到连接关闭。
5. 使用`sock.close()`关闭socket连接。

=== 手动运行 webget

编译完成后，可以手动测试webget程序的功能。使用命令行参数指定要访问的主机名和路径：

```bash
./webget cs144.keithw.org /hello
```

该命令会：
- 连接到`cs144.keithw.org`主机的HTTP服务
- 请求路径为`/hello`的资源
- 输出完整的HTTP响应，包括响应头和响应体

#figure(
  image("./images/webget-hello.png"),
  caption: "手动运行 webget",
  supplement: "图"
) <webget-hello>

=== 运行测试

为了验证webget程序的正确性，可以使用自动化测试：

```bash
make check_webget
```
#figure(
  image("./images/make-check-webget.png"),
  caption: "运行测试",
  supplement: "图"
) <make-check-webget>

== 可靠的字节流

= 实验结果与分析

== 实验结果

// 1. 这里应给出详实的实验结果。分析应有条理，要求采用规范的书面语。
// 2. 原则上要求使用图片与文字结合的形式说明，因为word和PDF文档不支持视频，所以请不要使用视频文件。
// 3. 图片请在垂直方向，不要横向。不要用很大的图片，请先做裁剪操作。
// （实验报告中请去除以上内容）

#question[
抓取网页（通过浏览器和telnet）的运行结果
]

#question[
使用webget抓取网页运行结果
]

#question[
运行`make check_webget`的测试结果
]

#question[
运行`make check_lab0`的测试结果
]

// #figure(
//   image("./images/wireshark-capture-all.png", width: 70%),
//   caption: "Wireshark主界面",
//   supplement: "图"
// )

// 1. 菜单栏：包括文件、编辑、视图、跳转、捕获、分析等子菜单。
// 2. 工具栏：常用功能（如开始/停止/重新开始捕获等）的快捷按钮。
// 3. 过滤器输入框：用于输入显示过滤器规则，实时筛选已捕获到的数据包。
// 4. 数据包列表面板：显示所有捕获到的数据包的概览信息，包括编号、时间戳、源/目的地址、协议类型、长度和信息简述。
// 5. 数据包详细信息面板：显示在列表面板中选中的数据包的详细分层解析结果，从数据链路层到应用层。
// 6. 数据包字节面板：以十六进制和 ASCII 码形式显示选中数据包的原始字节数据。

// #question[
//   开始捕获网络数据包，你看到了什么？有哪些协议？
// ]

// 在开始捕获网络数据包后，即使在没有主动进行任何网络操作的情况下，数据包列表也会迅速增长。我看到了大量的后台流量，主要协议包括：

// 1. ARP：地址解析协议，用于在局域网内将 IP 地址解析为 MAC 地址。
// 2. TCP：传输控制协议，承载大量应用层数据。
// 3. HTTP：如果浏览器处于打开状态，会有未加密的网页访问流量。
// 4. TLSv1.3：传输层安全协议，用于加密 HTTPS 等安全通信。
// 5. DNS：进行域名到 IP 地址的查询。
// 6. ICMP：互联网控制消息协议，用于网络诊断和错误报告。
// 7. ICMPv6：ICMP 协议在 IPv6 环境下的对应版本。

// #question[
//   配置显示过滤器，让界面只显示某一协议类型的数据包。
// ]

// 在过滤器输入框中输入`http`，只显示HTTP协议的数据包：

// #figure(
//   image("./images/wireshark-display-filter-http.png", width: 70%),
//   caption: "只显示HTTP协议的数据包",
//   supplement: "图"
// )

// #question[
//   配置捕获过滤器，只捕获某类协议的数据包。
// ]

// #figure(
//   image("./images/wireshark-capture-filter-tcp.png", width: 70%),
//   caption: "只捕获TCP协议的数据包",
//   supplement: "图"
// )

// #question[
//   利用ping, ipconfig, arp, tracert, nslookup, nbstat, route, netstat, NET SHARE, telnet命令完成在实验步骤4中列举的11个功能。
// ]

// #figure(
//   image("./images/ping.png", width: 70%),
//   caption: "ping命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/ipconfig.png", width: 70%),
//   caption: "ipconfig命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/arp.png", width: 50%),
//   caption: "arp命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/tracert.png", width: 50%),
//   caption: "tracert命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/nslookup.png", width: 70%),
//   caption: "nslookup命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/nbstat.png", width: 50%),
//   caption: "nbstat命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/route-print.png", width: 50%),
//   caption: "route print命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/route-add.png", width: 50%),
//   caption: "route add命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/netstat.png", width: 50%),
//   caption: "netstat命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/net-share.png", width: 70%),
//   caption: "net share命令",
//   supplement: "图"
// )

// #figure(
//   image("./images/telnet.png", width: 70%),
//   caption: "telnet命令（输入指令无回显）",
//   supplement: "图"
// )

// #question[
//   观察使用ping命令时在WireShark中出现的数据包并捕获。这是什么协议？
// ]

// 如@wireshark-ping，这是ICMP协议的数据包。

// #figure(
//   image("./images/wireshark-ping.png", width: 70%),
//   caption: "ping命令",
//   supplement: "图"
// ) <wireshark-ping>


// #question[
//   观察使用tracert命令时在WireShark中出现的数据包并捕获。这是什么协议？
// ]

// 如@wireshark-tracert，也是ICMP协议的数据包。

// #figure(
//   image("./images/wireshark-tracert.png", width: 70%),
//   caption: "tracert命令",
//   supplement: "图"
// ) <wireshark-tracert>

// #question[
//   观察使用nslookup命令时在WireShark中出现的数据包并捕获。这是什么协议？
// ]

// 如@wireshark-nslookup，协议为DNS（over UDP）。

// #figure(
//   image("./images/wireshark-nslookup.png", width: 70%),
//   caption: "nslookup命令",
//   supplement: "图"
// ) <wireshark-nslookup>

// #question[
//   观察使用telnet命令时在WireShark中出现的数据包并捕获。这是什么协议？
// ]

// 如@wireshark-telnet，协议为TCP。

// #figure(
//   image("./images/wireshark-telnet.png", width: 70%),
//   caption: "telnet命令",
//   supplement: "图"
// ) <wireshark-telnet>

== 思考题

// 根据你编写的程序运行效果，分别解答以下问题（实验报告中请去除此段）

#question[
完成webget程序编写后的测试结果和Fetch a Web page步骤的运行结果一致吗？如果不一致的话你认为问题出在哪里？请描述一下所写的webget程序抓取网页的流程。
]

#question[
请描述ByteStream是如何实现流控制的？
]

#question[
当遇到超出capacity范围的数据流的时候，该如何进行处理？如果不限制流的长度会怎么样？
]

// 1. 捕获过滤器：在开始抓包之前进行配置。只有符合条件的数据包才会被实际记录。可以减少捕获的数据量，减轻系统负担，使抓包文件更小、更高效。

// 2. 显示过滤器：在数据包已经捕获之后进行配置。它定义了在 Wireshark 主界面显示哪些已经捕获的数据包。不符合条件的数据包只是被隐藏起来，但仍在抓包文件中。可以方便用户在大量已捕获数据中查找、分析特定类型的数据包。

// #question[
//  哪些网络命令会产生在WireShark中产生数据包，为什么？
// ]

// 见@table-commands。

// // 命令	是否产生数据包	产生的数据包类型	产生原因/说明
// // ping	是	ICMP (Echo Request/Reply)	用于测试主机之间的连通性和往返时延。
// // tracert	是	ICMP (Time Exceeded, Echo Request/Reply)	通过发送一系列数据包并故意超时，获取数据包到达目的地的每一跳路由信息。
// // nslookup	是	DNS (Query/Response)	用于查询域名对应的 IP 地址，需要向 DNS 服务器发送请求。
// // telnet	是	TCP (SYN, ACK, PSH, FIN, etc.)，以及承载的 应用层数据 (如 HTTP 请求)	尝试与远程主机的特定端口建立 TCP 连接并进行数据传输。
// // arp -a	否（一般不主动）	ARP (Request/Reply)	显示本地 ARP 缓存表，一般不主动发包。但在查询一个不存在于缓存的 IP 地址时，可能会触发 ARP 请求。
// // ipconfig	否	无	仅显示或配置本地网络接口信息，不涉及网络通信。
// // netstat	否	无	仅显示本机已建立的连接、路由表等信息，不涉及网络通信。
// // route	否	无	仅用于查看或修改本地路由表，不涉及网络通信。
// // nbstat	否	无	仅显示本地 NetBIOS 名称表。
// // NET SHARE	否	无	仅显示本地共享资源信息
// #[

// #set text(size: 10pt)
// #figure(
// table(
//   columns: 3,
//   align: (col, row) => {
//     if row == 0 {
//       horizon + center
//     } else {
//       horizon + left
//     }
//   },
//   [*命令*], [*数据包*], [*原因*],
//   [`ping`], [ICMP], [用于测试主机之间的连通性和往返时延。],
//   [`tracert`], [ICMP], [通过发送一系列数据包并超时，获取到达目的地的每一跳路由信息。],
//   [`nslookup`], [DNS], [用于查询域名对应的 IP 地址，需要向 DNS 服务器发送请求。],
//   [`telnet`], [TCP], [尝试与远程主机的特定端口建立 TCP 连接并进行数据传输。],
//   [`arp -a`], [无], [显示本地 ARP 缓存表，一般不主动发包。],
//   [`ipconfig`], [无], [仅显示或配置本地网络接口信息，不涉及网络通信。],
//   [`netstat`], [无], [仅显示本机已建立的连接、路由表等信息，不涉及网络通信。],
//   [`route`], [无], [仅用于查看或修改本地路由表，不涉及网络通信。],
//   [`nbstat`], [无], [仅显示本地 NetBIOS 名称表。],
//   [`NET SHARE`], [无], [仅显示本地共享资源信息]
// ),
// caption: "网络命令与数据包",
// supplement: "表"
// ) <table-commands>

// ]

// #question[
//   ping发送的是什么类型的协议数据包？什么时候会出现ARP消息？ping一个域名和ping一个IP地址出现的数据包有什么不同？
// ]

// `ping`命令发送和接收的是 ICMP数据包。ICMP 位于 IP 层之上，用于传输控制消息和错误报告。

// 当主机首次 `ping` 局域网内一个 IP 地址，且该 IP 的 MAC 地址不在 ARP 缓存中时，会先出现 ARP 消息。

// `ping`一个域名，多了一个 DNS 查询过程，系统会向配置的DNS服务器发送一个DNS查询请求。从DNS响应拿到IP地址后，后续步骤就和 `ping` 一个IP地址完全相同了。

= 讨论、心得

// 简要地叙述一下实验过程中的感受，以及其他的问题描述和自己的感想。特别是实验中遇到的困难，最后如何解决的。（实验报告中请去除本段）		

// 通过本次实验，我对计算机网络的基本概念和实践操作有了更深刻的理解。之前学习的TCP/IP协议栈、各种网络协议和命令都只是停留在书本上的抽象概念，而通过Wireshark这款强大的工具，我第一次“亲眼”看到了这些协议在网络中是如何以数据包的形式具象化地进行交互和传输的。

// 本次实验不仅让我熟练掌握了多种常用网络命令的用法和Wireshark的基本操作，更激发了我对计算机网络的兴趣，也为后续更深入的学习打下了坚实的基础。