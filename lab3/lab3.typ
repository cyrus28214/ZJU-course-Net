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

#codly-title("libsponge/network_interface.hh")
```cpp
class NetworkInterface {
  private:
    //! Ethernet (known as hardware, network-access-layer, or link-layer) address of the interface
    EthernetAddress _ethernet_address;

    //! IP (known as internet-layer or network-layer) address of the interface
    Address _ip_address;

    //! outbound queue of Ethernet frames that the NetworkInterface wants sent
    std::queue<EthernetFrame> _frames_out{};

    //! ARP cache: maps IP address to Ethernet address and remaining time (in milliseconds)
    std::map<uint32_t, std::pair<EthernetAddress, size_t>> _arp_cache{};

    //! Pending datagrams waiting for ARP resolution: maps IP address to queue of datagrams
    std::map<uint32_t, std::queue<InternetDatagram>> _pending_datagrams{};

    //! ARP requests sent: maps IP address to remaining time before retransmission (in milliseconds)
    std::map<uint32_t, size_t> _arp_requests{};

    //! ARP cache timeout in milliseconds (30 seconds)
    static constexpr size_t ARP_CACHE_TIMEOUT = 30000;

    //! ARP request timeout in milliseconds (5 seconds)
    static constexpr size_t ARP_REQUEST_TIMEOUT = 5000;

  public:

    // ...
}
```

- `_frames_out`：一个队列，用于缓存所有待发送出去的以太网帧。
- `_arp_cache`：ARP缓存，一个 `std::map`，用于存储IP地址到（MAC地址，剩余超时时间）的映射。这是实现ARP高效查询的核心。
- `_pending_datagrams`：一个 `std::map`，用于暂存那些因为目标MAC地址未知（ARP未解析）而无法立即发送的IP数据包。键是目标IP地址，值是等待该IP的包队列。
- `_arp_requests`：一个 `std::map`，用于记录最近发送过的ARP请求及其剩余超时时间，以避免在短时间内（5秒内）对同一IP重复发送ARP请求。
- `ARP_CACHE_TIMEOUT` 和 `ARP_REQUEST_TIMEOUT`：两个静态常量，分别定义了ARP缓存条目的超时时间（30秒）和ARP请求的重传间隔（5秒）。

=== 在`libsponge/network_interface.cc`中实现三个方法

我们在 `.cc` 文件中实现了 `NetworkInterface` 的三个核心方法：

1. *`send_datagram(dgram, next_hop)`*：当上层（IP层）需要发送一个数据包时，会调用此方法。
  + 首先，它会查询 `_arp_cache` 寻找下一跳IP对应的MAC地址。
  + 如果找到：立即将IP数据包封装成一个以太网帧，设置正确的目的MAC、源MAC和类型（IPv4），然后推入 `_frames_out` 队列等待发送。
  + 如果未找到：说明MAC地址未知。此时，数据包不能立即发送，而是被推入 `_pending_datagrams` 队列中暂存。同时，检查 `_arp_requests` 确认5秒内是否已发送过对该IP的ARP请求。如果未发送过，就构造一个ARP请求（广播），封装成以太网帧推入 `_frames_out`，并记录请求时间。

2. *`recv_frame(frame)`*：当网络接口从物理层收到一个以太网帧时，会调用此方法。
  + 首先检查帧的目的MAC地址，如果不是本机MAC地址也不是广播地址，则直接丢弃。
  + 如果是IPv4帧：解析 `payload` 为 `InternetDatagram`，并将其返回给上层处理。
  + 如果是ARP帧：解析 `payload` 为 `ARPMessage`。
    + 首先，无条件学习并缓存发送方的IP-MAC映射到 `_arp_cache` 中（设置30秒超时）。
    + 如果是ARP请求 且目标IP是本机IP：构造一个ARP应答，填入本机MAC和IP，然后将应答帧推入 `_frames_out` 队列。
    + 如果是ARP应答：清除 `_arp_requests` 中对应的记录。然后，检查 `_pending_datagrams` 中是否有等待该IP的数据包。如果有，将所有等待的包依次封装成以太网帧（现在我们知道目的MAC了）并推入 `_frames_out` 队列。

3. *`tick(ms_since_last_tick)`*：这是一个定时器方法，由系统周期性调用。
  + 它负责管理ARP缓存和ARP请求记录的老化。它会遍历 `_arp_cache` 和 `_arp_requests`，将所有条目的剩余时间减去 `ms_since_last_tick`。如果任何条目的时间减到0或以下，就将其从 `map` 中删除。

#codly-title("libsponge/network_interface.cc")
```cpp
//! \param[in] ethernet_address Ethernet (what ARP calls "hardware") address of the interface
//! \param[in] ip_address IP (what ARP calls "protocol") address of the interface
NetworkInterface::NetworkInterface(const EthernetAddress &ethernet_address, const Address &ip_address)
    : _ethernet_address(ethernet_address), _ip_address(ip_address) {
    cerr << "DEBUG: Network interface has Ethernet address " << to_string(_ethernet_address) << " and IP address "
         << ip_address.ip() << "\n";
}

//! \param[in] dgram the IPv4 datagram to be sent
//! \param[in] next_hop the IP address of the interface to send it to (typically a router or default gateway, but may also be another host if directly connected to the same network as the destination)
//! (Note: the Address type can be converted to a uint32_t (raw 32-bit IP address) with the Address::ipv4_numeric() method.)
void NetworkInterface::send_datagram(const InternetDatagram &dgram, const Address &next_hop) {
    // convert IP address of next hop to raw 32-bit representation (used in ARP header)
    const uint32_t next_hop_ip = next_hop.ipv4_numeric();

    // Check if the Ethernet address is already in the ARP cache
    auto arp_it = _arp_cache.find(next_hop_ip);
    if (arp_it != _arp_cache.end()) {
        // Ethernet address is known, send the frame immediately
        EthernetFrame frame;
        frame.header().dst = arp_it->second.first;        // Destination MAC address
        frame.header().src = _ethernet_address;           // Source MAC address
        frame.header().type = EthernetHeader::TYPE_IPv4;  // IPv4 type
        frame.payload() = dgram.serialize();              // Serialize the datagram as payload
        _frames_out.push(frame);
    } else {
        // Ethernet address is unknown, queue the datagram
        _pending_datagrams[next_hop_ip].push(dgram);

        // Check if we've already sent an ARP request for this IP recently
        auto arp_req_it = _arp_requests.find(next_hop_ip);
        if (arp_req_it == _arp_requests.end()) {
            // No recent ARP request, send a new one
            ARPMessage arp_request;
            arp_request.opcode = ARPMessage::OPCODE_REQUEST;
            arp_request.sender_ethernet_address = _ethernet_address;
            arp_request.sender_ip_address = _ip_address.ipv4_numeric();
            arp_request.target_ethernet_address = {0, 0, 0, 0, 0, 0};  // Unknown
            arp_request.target_ip_address = next_hop_ip;

            // Encapsulate ARP request in Ethernet frame and broadcast
            EthernetFrame frame;
            frame.header().dst = ETHERNET_BROADCAST;  // Broadcast address
            frame.header().src = _ethernet_address;
            frame.header().type = EthernetHeader::TYPE_ARP;
            frame.payload() = BufferList(arp_request.serialize());
            _frames_out.push(frame);

            // Record the ARP request time
            _arp_requests[next_hop_ip] = ARP_REQUEST_TIMEOUT;
        }
    }
}

//! \param[in] frame the incoming Ethernet frame
optional<InternetDatagram> NetworkInterface::recv_frame(const EthernetFrame &frame) {
    // Check if the frame is intended for this interface (or is a broadcast)
    const EthernetAddress &dst = frame.header().dst;
    if (dst != _ethernet_address && dst != ETHERNET_BROADCAST) {
        // Frame is not for us, discard it
        return {};
    }

    // Handle IPv4 datagram
    if (frame.header().type == EthernetHeader::TYPE_IPv4) {
        InternetDatagram dgram;
        if (dgram.parse(frame.payload()) == ParseResult::NoError) {
            return dgram;
        }
    }
    // Handle ARP message
    else if (frame.header().type == EthernetHeader::TYPE_ARP) {
        ARPMessage arp_msg;
        if (arp_msg.parse(frame.payload()) == ParseResult::NoError) {
            // Learn the mapping from sender IP to sender Ethernet address
            const uint32_t sender_ip = arp_msg.sender_ip_address;
            const EthernetAddress sender_eth = arp_msg.sender_ethernet_address;

            // Add to ARP cache with 30-second timeout
            _arp_cache[sender_ip] = {sender_eth, ARP_CACHE_TIMEOUT};

            // If this is an ARP request for our IP address, send a reply
            if (arp_msg.opcode == ARPMessage::OPCODE_REQUEST &&
                arp_msg.target_ip_address == _ip_address.ipv4_numeric()) {
                // Create ARP reply
                ARPMessage arp_reply;
                arp_reply.opcode = ARPMessage::OPCODE_REPLY;
                arp_reply.sender_ethernet_address = _ethernet_address;
                arp_reply.sender_ip_address = _ip_address.ipv4_numeric();
                arp_reply.target_ethernet_address = sender_eth;
                arp_reply.target_ip_address = sender_ip;

                // Encapsulate in Ethernet frame
                EthernetFrame reply_frame;
                reply_frame.header().dst = sender_eth;
                reply_frame.header().src = _ethernet_address;
                reply_frame.header().type = EthernetHeader::TYPE_ARP;
                reply_frame.payload() = BufferList(arp_reply.serialize());
                _frames_out.push(reply_frame);
            }
            // If this is an ARP reply, send any pending datagrams
            else if (arp_msg.opcode == ARPMessage::OPCODE_REPLY) {
                // Remove the ARP request record
                _arp_requests.erase(sender_ip);

                // Send all pending datagrams for this IP
                auto pending_it = _pending_datagrams.find(sender_ip);
                if (pending_it != _pending_datagrams.end()) {
                    while (!pending_it->second.empty()) {
                        const InternetDatagram &dgram = pending_it->second.front();

                        // Create and send the frame
                        EthernetFrame eth_frame;
                        eth_frame.header().dst = sender_eth;
                        eth_frame.header().src = _ethernet_address;
                        eth_frame.header().type = EthernetHeader::TYPE_IPv4;
                        eth_frame.payload() = dgram.serialize();
                        _frames_out.push(eth_frame);

                        pending_it->second.pop();
                    }
                    // Remove the empty queue
                    _pending_datagrams.erase(pending_it);
                }
            }
        }
    }

    return {};
}

//! \param[in] ms_since_last_tick the number of milliseconds since the last call to this method
void NetworkInterface::tick(const size_t ms_since_last_tick) {
    // Update ARP cache entries and remove expired ones
    for (auto it = _arp_cache.begin(); it != _arp_cache.end();) {
        if (it->second.second <= ms_since_last_tick) {
            // Entry has expired, remove it
            it = _arp_cache.erase(it);
        } else {
            // Decrement remaining time
            it->second.second -= ms_since_last_tick;
            ++it;
        }
    }

    // Update ARP request timers and remove expired ones
    for (auto it = _arp_requests.begin(); it != _arp_requests.end();) {
        if (it->second <= ms_since_last_tick) {
            // ARP request has expired, remove it (will be resent on next send_datagram)
            it = _arp_requests.erase(it);
        } else {
            // Decrement remaining time
            it->second -= ms_since_last_tick;
            ++it;
        }
    }
}
```

== 实现路由类

路由器的核心功能是转发IP数据包。它通过查询路由表来决定数据包的下一跳地址和应该从哪个接口发送出去。

=== 在`libsponge/router.hh`中添加路由表

我们在 `Router` 类中添加了一个 `std::vector<RouteEntry>` 作为路由表。`RouteEntry` 结构体用于存储路由表的每一行，包含四个关键信息：
- `route_prefix`：路由匹配的目标网段前缀。
- `prefix_length`：前缀的长度（0-32位）。
- `next_hop`：下一跳的IP地址。如果 `next_hop` 为空（`std::optional`），表示该路由是直连网络，下一跳就是数据包的最终目的IP。
- `interface_num`：数据包应该从此索引对应的接口发送出去。

#codly-title("libsponge/router.hh")
```cpp
    //! \brief A single entry in the routing table
    struct RouteEntry {
        uint32_t route_prefix;                 //!< The route prefix to match
        uint8_t prefix_length;                 //!< Number of high-order bits to match
        std::optional<Address> next_hop;       //!< Next hop address (empty if directly attached)
        size_t interface_num;                  //!< Index of the interface to send out on
    };

    //! The routing table
    std::vector<RouteEntry> _routing_table{};
```

=== 在`libsponge/router.cc`中实现`add_route`和`route_one_datagram`

`add_route` 方法比较简单，只是将一条新的路由规则（`RouteEntry`）添加到 `_routing_table` 向量中。

`route_one_datagram` 是路由转发的核心逻辑，其步骤如下：
1. 首先检查IP数据包头的 `ttl` 字段。如果 `ttl` 小于或等于1，意味着数据包在转发后即超时，此时应直接丢弃该包，不再转发。否则，将 `ttl` 减1。
2. 遍历路由表 `_routing_table` 中的所有条目，寻找与数据包目的IP地址 `dgram.header().dst` 匹配的最长前缀。
3. 如果未找到匹配：说明路由表中没有到达该目的地的路径，丢弃该数据包。
4. 如果找到匹配：根据匹配到的最佳路由 `best_route`，确定下一跳 `next_hop_addr`（如果路由条目中指定了 `next_hop`，则用它；否则用数据包的原始目的IP）。
5. 最后，调用该路由指定的 `_interfaces[best_route.interface_num]` 上的 `send_datagram` 方法，将（已更新TTL的）数据包和下一跳地址交给网络接口层去处理（后续的ARP解析等）。

#codly-title("libsponge/router.cc")
```cpp
//! \param[in] route_prefix The "up-to-32-bit" IPv4 address prefix to match the datagram's destination address against
//! \param[in] prefix_length For this route to be applicable, how many high-order (most-significant) bits of the route_prefix will need to match the corresponding bits of the datagram's destination address?
//! \param[in] next_hop The IP address of the next hop. Will be empty if the network is directly attached to the router (in which case, the next hop address should be the datagram's final destination).
//! \param[in] interface_num The index of the interface to send the datagram out on.
void Router::add_route(const uint32_t route_prefix,
                       const uint8_t prefix_length,
                       const optional<Address> next_hop,
                       const size_t interface_num) {
    cerr << "DEBUG: adding route " << Address::from_ipv4_numeric(route_prefix).ip() << "/" << int(prefix_length)
         << " => " << (next_hop.has_value() ? next_hop->ip() : "(direct)") << " on interface " << interface_num << "\n";

    // Add the route entry to the routing table
    _routing_table.push_back({route_prefix, prefix_length, next_hop, interface_num});
}

//! \param[in] dgram The datagram to be routed
void Router::route_one_datagram(InternetDatagram &dgram) {
    // Check if TTL is valid (must be > 1 to forward after decrement)
    if (dgram.header().ttl <= 1) {
        return;  // Discard the datagram (TTL expired or will expire)
    }

    // Decrement TTL
    dgram.header().ttl--;

    // Find the longest prefix match in the routing table
    const uint32_t dst_ip = dgram.header().dst;
    int best_match_idx = -1;
    uint8_t longest_prefix = 0;

    for (size_t i = 0; i < _routing_table.size(); i++) {
        const auto &route = _routing_table[i];
        const uint8_t prefix_len = route.prefix_length;

        // Create a mask for the prefix
        uint32_t mask = 0;
        if (prefix_len > 0) {
            if (prefix_len == 32) {
                mask = 0xFFFFFFFF;
            } else {
                mask = ~((1U << (32 - prefix_len)) - 1);
            }
        }

        // Check if the destination IP matches this route's prefix
        if ((dst_ip & mask) == (route.route_prefix & mask)) {
            // This route matches; check if it's the longest prefix so far
            if (prefix_len >= longest_prefix) {
                longest_prefix = prefix_len;
                best_match_idx = i;
            }
        }
    }

    // If no matching route found, discard the datagram
    if (best_match_idx == -1) {
        return;
    }

    // Get the best matching route
    const auto &best_route = _routing_table[best_match_idx];

    // Determine the next hop address
    Address next_hop_addr = best_route.next_hop.value_or(Address::from_ipv4_numeric(dst_ip));

    // Send the datagram out on the appropriate interface
    _interfaces[best_route.interface_num].send_datagram(dgram, next_hop_addr);
}

void Router::route() {
    // Go through all the interfaces, and route every incoming datagram to its proper outgoing interface.
    for (auto &interface : _interfaces) {
        auto &queue = interface.datagrams_out();
        while (not queue.empty()) {
            route_one_datagram(queue.front());
            queue.pop();
        }
    }
}
```


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

= 讨论、心得

// 简要地叙述一下实验过程中的感受，以及其他的问题描述和自己的感想。特别是实验中遇到的困难，最后如何解决的。（实验报告中请去除本段）

// 通过这次实验，我把课堂上学到的网络理论知识和实际动手操作结合了起来。在实现webget的过程中，我第一次亲手构造了HTTP协议的GET请求报文，并通过TCPSocket发送出去。这个过程让我非常直观地理解了像HTTP这样的应用层协议是如何运行在TCP这个传输层之上的。

// 实现ByteStream则让我对TCP的“字节流”和“缓冲区”概念有了更深的体会。核心在于理解“流控制”的重要性。通过设置一个固定的capacity，我们防止了写入方无限制地发送数据。如果写入速度快于读取速度，缓冲区会填满，write操作就会受阻。这就实现了一种反压机制，避免了因数据堆积而耗尽内存。这个小小的ByteStream模拟，让我明白了流控制是保证网络通信稳定和资源可控的关键机制。
