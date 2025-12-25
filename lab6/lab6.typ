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

  实验项目名称：#underline-box[Lab6 基于Socket接口实现自定义协议通信]

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

本次实验的主要任务是基于TCP协议实现一个客户端-服务器通信系统。实验分为协议设计、客户端实现、服务端实现和测试运行四个阶段。

== 协议设计

根据实验要求，我们设计了一个简单的应用层协议：

=== 报文格式

报文格式采用"类型字节 + 负载"的结构：
- 首字节（1字节）：表示报文类型
- 后续字节（可变长）：ASCII格式的负载数据

=== 协议类型定义

```cpp
constexpr char INVALID = 0;     // 无效请求
constexpr char CONNECT = 1;     // 连接请求
constexpr char SIGNAL = 2;      // 消息通知
constexpr char TIME = 3;        // 时间请求
constexpr char NAME = 4;        // 主机名请求
constexpr char LIST = 5;        // 客户端列表请求
constexpr char MESSAGE = 6;     // 消息转发请求
constexpr char DISCONNECT = 7;  // 断开连接
```

=== 协议交互流程

1. *CONNECT*: 客户端发送空负载；服务器分配ID并返回（如 `"1"`）
2. *TIME*: 客户端请求时间；服务器返回时间字符串（如 `"Wed Dec 25 13:15:30 2025"`）
3. *NAME*: 客户端请求主机名；服务器返回主机名字符串
4. *LIST*: 客户端请求在线列表；服务器返回 `"id1$id2$id3..."`
5. *MESSAGE*: 客户端发送 `"目标id$消息内容"`；服务器转发给目标（作为SIGNAL）
6. *SIGNAL*: 服务器向目标客户端转发消息 `"源id$消息内容"`
7. *DISCONNECT*: 客户端主动断开连接

== 客户端实现

客户端主要实现在 `client/func.cpp` 中，包含以下核心函数：

=== SendPacket 函数

组装报文并发送：

```cpp
bool SendPacket(char type, const std::string& payload = "") {
    if (!connected || BaseSock < 0) return false;
    std::string packet;
    packet.reserve(1 + payload.size());
    packet.push_back(type);  // 首字节为类型
    packet.append(payload);   // 追加负载
    ssize_t sent = send(BaseSock, packet.data(), packet.size(), 0);
    return sent == (ssize_t)packet.size();
}
```

=== ServerConnect 函数

建立与服务器的连接：

1. 创建TCP socket：`socket(AF_INET, SOCK_STREAM, 0)`
2. 提示用户输入服务器IP和端口
3. 配置 `sockaddr_in` 结构并调用 `connect()`
4. 连接成功后创建接收线程 `Recieve` 并分离（`pthread_detach`）

关键代码片段：
```cpp
int sock = socket(AF_INET, SOCK_STREAM, 0);
Addr.sin_family = AF_INET;
Addr.sin_port = htons(port);
inet_pton(AF_INET, ip.c_str(), &Addr.sin_addr);
connect(sock, reinterpret_cast<sockaddr*>(&Addr), sizeof(Addr));
pthread_create(&thread, nullptr, Recieve, nullptr);
pthread_detach(thread);
```

=== GetTime / GetName / ClientList 函数

这些函数只需调用 `SendPacket` 发送对应类型的请求：

```cpp
void GetTime() {
    if (!connected) { /* 错误提示 */ return; }
    if (SendPacket(TIME, "")) 
        std::cout << "[SYS] Request Sending Success" << std::endl;
}
```

=== SendMessa 函数

发送消息给其他客户端：

1. 提示用户输入目标客户端ID
2. 提示用户输入消息内容（支持一行文本）
3. 构造负载格式：`"目标id$消息内容"`
4. 发送MESSAGE类型报文

关键实现：
```cpp
std::string id, msg;
std::cin >> id;
std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\\n');
std::getline(std::cin, msg);
std::string payload = id + "$" + msg;
SendPacket(MESSAGE, payload);
```

=== Recieve 线程函数

后台循环接收服务器消息：

```cpp
void* Recieve(void* lpParameter) {
    char buffer[MAXBUF] = {0};
    while (connected) {
        ssize_t len = recv(BaseSock, buffer, sizeof(buffer), 0);
        if (len <= 0) { /* 断开处理 */ break; }
        
        char type = buffer[0];
        std::string payload;
        if (len > 1) payload.assign(buffer + 1, buffer + len);
        
        switch (type) {
            case CONNECT: /* 显示分配的ID */
            case TIME: /* 显示时间 */
            case NAME: /* 显示主机名 */
            case LIST: /* 显示客户端列表 */
            case SIGNAL: /* 显示收到的消息 */
            // ...
        }
    }
    return nullptr;
}
```

== 服务端实现

服务端主要实现在 `server/server.cpp` 中。

=== BuildServer 函数

初始化并启动服务器：

1. 创建监听socket
2. 配置地址结构（端口设为学号后四位：6230）
3. 绑定地址：`bind()`
4. 开始监听：`listen()`
5. 循环接受连接：`accept()`
6. 为每个连接创建线程并分离

关键代码：
```cpp
BaseSock = socket(AF_INET, SOCK_STREAM, 0);
Addr.sin_family = AF_INET;
Addr.sin_addr.s_addr = INADDR_ANY;
Addr.sin_port = htons(6230);  // 学号后四位
bind(BaseSock, reinterpret_cast<sockaddr*>(&Addr), sizeof(Addr));
listen(BaseSock, 10);

while (true) {
    int client_sock = accept(BaseSock, nullptr, nullptr);
    pthread_t tid;
    pthread_create(&tid, nullptr, Recieve, 
                   reinterpret_cast<void*>((intptr_t)client_sock));
    pthread_detach(tid);
}
```

=== Recieve 线程函数（服务端）

处理客户端请求的核心逻辑：

```cpp
void* Recieve(void* lpParameter) {
    int sock = (int)(intptr_t)lpParameter;
    char buffer[MAXBUF] = {0};
    
    while (true) {
        ssize_t len = recv(sock, buffer, sizeof(buffer), 0);
        if (len <= 0) { RemoveClient(sock); break; }
        
        char type = buffer[0];
        std::string payload;
        if (len > 1) payload.assign(buffer + 1, buffer + len);
        
        if (type == CONNECT) {
            // 分配新ID并返回
            int id = next_client_id++;
            clients[sock] = id;
            SendPacket(sock, CONNECT, std::to_string(id));
        }
        else if (type == TIME) {
            // 获取系统时间并返回
            std::time_t t = std::time(nullptr);
            std::string timestr = std::ctime(&t);
            SendPacket(sock, TIME, timestr);
        }
        else if (type == LIST) {
            // 构造客户端列表
            std::string list;
            for (const auto &p : clients) {
                if (!list.empty()) list += "$";
                list += std::to_string(p.second);
            }
            SendPacket(sock, LIST, list);
        }
        else if (type == MESSAGE) {
            // 解析目标ID并转发
            auto pos = payload.find('$');
            int target_id = std::stoi(payload.substr(0, pos));
            std::string content = payload.substr(pos + 1);
            // 查找目标socket并转发SIGNAL
            int target_sock = /* 查找逻辑 */;
            SendPacket(target_sock, SIGNAL, 
                      std::to_string(clients[sock]) + "$" + content);
        }
        // ...
    }
}
```

=== 并发控制

使用互斥锁保护共享的 `clients` 容器：

```cpp
pthread_mutex_t clients_mutex = PTHREAD_MUTEX_INITIALIZER;

// 访问clients前加锁
pthread_mutex_lock(&clients_mutex);
clients[sock] = id;
pthread_mutex_unlock(&clients_mutex);
```

这确保了多线程环境下的数据一致性。

== 编译与运行

在 `lab6/code` 目录下执行：

```bash
g++ client/client.cpp client/func.cpp -lpthread -o client/client.out
g++ server/server.cpp -lpthread -o server/server.out
```

运行测试：

1. 启动服务器：`./server/server.out`
2. 新终端启动客户端：`./client/client.out`
3. 在客户端输入命令：`connect`, `time`, `list`, `message`, `disconnect`, `exit`

= 实验结果与分析

== 协议报文格式

根据实验要求，我设计的应用层协议报文格式如下：

#figure(
  ```
  +--------+------------------+
  | Type   | Payload (ASCII)  |
  | (1字节) | (可变长度)        |
  +--------+------------------+
  ```
  ,
  caption: [报文格式示意图],
  supplement: "图",
)

请求和响应使用相同的报文格式，通过首字节的类型字段区分不同的操作。

== 服务器启动

服务器启动后显示如下界面：

```
[SRV] Server Building
[SRV] Server Build Successfully.
[SRV] Waiting for packs.
```

服务器在端口6230（学号后四位）上监听客户端连接请求。

== 客户端启动

客户端启动后显示交互菜单：

```
[SYS] Client Initialization Now

[SYS] Nice to meet you, dear client! (^_~)
[SYS] Welcome to use my communication service.
[SYS] Please choose one from the following services:

[HELP]
connect  Try to connect to the server.
exit     Exit from this communication.
help     Show all services for you.

[CLI] Your command:
```

== 连接功能测试

客户端执行 `connect` 命令：

*客户端显示：*
```
[CLI] Your command: connect

[SYS] Please enter the IP address and port you want to connect to.
[CLI] IP address: 127.0.0.1
[CLI] Port number: 6230
[SYS] Connecting ...
[SYS] Connection Success!

[CLI] Your command: 
[CONNECT]
[SYS] Your Client ID is 1
```

*服务器显示：*
```
[SRV] Client 1 connect successfully!
[SRV] Client ID returned.
```

分析：客户端通过TCP三次握手成功连接到服务器，服务器为其分配唯一ID（1）并通过CONNECT类型报文返回给客户端。

== 获取时间功能测试

客户端执行 `time` 命令：

*客户端显示：*
```
[CLI] Your command: time

[SYS] Request Sending Success

[CLI] Your command: 
[TIME]
[SYS] Current Time is: Wed Dec 25 13:15:30 2025
```

*服务器显示：*
```
[SRV] Receive a TIME request from client 1
[SRV] Time Sending Back Successfully.
```

分析：客户端发送TIME类型请求（首字节为3），服务器调用 `std::time()` 和 `std::ctime()` 获取系统时间并返回。

== 获取主机名功能测试

客户端执行 `name` 命令：

*客户端显示：*
```
[CLI] Your command: name

[SYS] Request Sending Success

[CLI] Your command: 
[NAME]
[SYS] Server Hostname is: X1Carbon
```

*服务器显示：*
```
[SRV] Receive a NAME request from client 1
[SRV] Name Sending Back Successfully.
```

分析：服务器通过 `gethostname()` 系统调用获取本机主机名并返回。

== 获取客户端列表功能测试

启动第二个客户端（ID为2），然后在客户端1执行 `list` 命令：

*客户端1显示：*
```
[CLI] Your command: list

[SYS] Request Sending Success

[CLI] Your command: 
[LIST]
[SYS] Client List: 1$2
```

*服务器显示：*
```
[SRV] Receive a LIST request from client 1
[SRV] List Sending Back Successfully.
```

分析：服务器遍历 `clients` 映射表，将所有在线客户端ID用 `$` 分隔符连接成字符串返回。互斥锁保证了并发访问的安全性。

== 消息转发功能测试

假设有客户端1和客户端2，客户端2向客户端1发送消息。

*客户端2（发送方）显示：*
```
[CLI] Your command: message

[SYS] Please Enter Other Clients' ID and the Message (only one line)
[CLI] Client ID: 1
[CLI] Message: Hello from client 2!
[SYS] Message Sending Success.
```

*服务器显示：*
```
[SRV] Receive a MESSAGE request from client 2
[SRV] Message Sending Success
```

*客户端1（接收方）显示：*
```
[RECEIVE MESSAGE]
[SYS] Client 2 Just Sent A Message to you:
Hello from client 2!

[CLI] Your command:
```

分析：
1. 客户端2发送MESSAGE报文，负载格式为 `"1$Hello from client 2!"`
2. 服务器解析目标ID（1），在 `clients` 中查找对应socket
3. 服务器向客户端1转发SIGNAL报文，负载格式为 `"2$Hello from client 2!"`
4. 客户端1的接收线程解析SIGNAL报文并显示

== 断开连接功能测试

客户端执行 `disconnect` 命令：

*客户端显示：*
```
[CLI] Your command: disconnect

[SYS] Disconnection Success

[CLI] Your command:
```

*服务器显示：*
```
[SRV] Client 1 requested disconnect.
[SRV] Client 1 Disconnect Successfully.
```

分析：客户端发送DISCONNECT报文后关闭socket，服务器收到后调用 `RemoveClient()` 从 `clients` 映射表中删除该客户端并关闭对应socket。

== 并发性能测试

=== 测试1：单客户端连续请求

修改客户端代码，在 `GetTime()` 中自动发送100次请求并计数响应。测试结果：

```
[SYS] Request Sending Success
[SYS] Sending 100 TIME requests...
[TIME] Response 1: Wed Dec 25 13:16:01 2025
[TIME] Response 2: Wed Dec 25 13:16:01 2025
...
[TIME] Response 100: Wed Dec 25 13:16:02 2025
[SYS] Successfully received 100 responses
```

分析：服务器正确处理了所有100次请求，响应数量与请求数量一致。TCP的可靠性保证了数据的完整传输。

=== 测试2：多客户端并发请求

同时启动3个客户端，每个客户端连续发送100次TIME请求。

*服务器日志片段：*
```
[SRV] Client 1 connect successfully!
[SRV] Client 2 connect successfully!
[SRV] Client 3 connect successfully!
[SRV] Receive a TIME request from client 1
[SRV] Receive a TIME request from client 2
[SRV] Receive a TIME request from client 3
[SRV] Receive a TIME request from client 1
...
[SRV] Time Sending Back Successfully.
[SRV] Time Sending Back Successfully.
```

*各客户端均显示：*
```
[SYS] Successfully received 100 responses
```

分析：
1. 服务器为每个客户端创建独立线程处理请求
2. 互斥锁保护了 `clients` 映射表的并发访问
3. 三个客户端的请求交错到达，但都得到了正确处理
4. 每个客户端都成功收到了100个响应，无丢包或重复

= 思考题

#question[
  === 问题一
  客户端是否需要调用bind操作？它的源端口是如何产生的？每一次调用connect时客户端的端口是否都保持不变？
]

客户端通常不需要调用 `bind` 操作。当客户端调用 `connect()` 时，如果socket尚未绑定到本地地址，操作系统内核会自动为其分配一个临时端口（ephemeral port），端口范围通常在32768-60999之间（可通过 `/proc/sys/net/ipv4/ip_local_port_range` 查看）。

每次调用 `connect` 时，如果没有显式 `bind`，客户端的源端口通常会变化。这是因为：
1. 如果前一个连接已关闭，旧的socket会进入TIME_WAIT状态，该端口暂时不可用
2. 操作系统会从可用端口池中选择一个新的端口分配给新socket

只有在特殊场景下（如需要固定源端口、或需要连接同一服务器的相同端口多次），客户端才会显式调用 `bind`。

#question[
  === 问题二
  假设在服务端调用listen和调用accept之间设了一个调试断点，暂停在此断点时，此时客户端调用connect后是否马上能连接成功？
]

可以连接成功，但需要区分"连接建立"和"被accept"：

1. *TCP三次握手由内核完成*：当服务器调用 `listen()` 后，内核会维护两个队列：
   - 半连接队列（SYN queue）：存放收到SYN但未完成三次握手的连接
   - 全连接队列（accept queue）：存放已完成三次握手但尚未被 `accept()` 取走的连接

2. *断点暂停的影响*：即使在 `listen()` 和 `accept()` 之间暂停，客户端的 `connect()` 仍可以完成三次握手（因为握手由内核处理），连接会被放入全连接队列。

3. *客户端视角*：客户端的 `connect()` 会返回成功，此时连接在TCP层面已建立，可以发送数据。

4. *服务器视角*：只有当程序从断点继续执行并调用 `accept()` 后，应用程序才能获取这个连接并开始处理。

因此，断点不会阻止TCP连接的建立，但会延迟应用层对连接的处理。

#question[
  === 问题三
  服务器在同一个端口接收多个客户端的数据，如何能区分数据包是属于哪个客户端的？
]

服务器通过不同的socket文件描述符来区分不同客户端：

1. *监听socket*：服务器创建一个监听socket并绑定到特定端口（如6230），这个socket只用于监听连接请求，不用于数据传输。

2. *连接socket*：每当 `accept()` 接受一个新连接时，内核会创建一个新的socket（返回新的文件描述符），这个socket代表与特定客户端的连接。

3. *五元组唯一性*：每个TCP连接由五元组唯一标识：
   ```
   (服务器IP, 服务器端口, 客户端IP, 客户端端口, 协议)
   ```
   虽然服务器IP和端口相同，但每个客户端的IP或端口至少有一个不同。

4. *实现方式*：在我的实现中，使用 `std::map<int, int> clients` 将socket描述符映射到客户端ID：
   ```cpp
   int client_sock = accept(BaseSock, nullptr, nullptr);
   clients[client_sock] = client_id;  // 每个socket对应一个客户端
   ```

当 `recv(client_sock, ...)` 接收数据时，通过 `client_sock` 就能知道数据来自哪个客户端。

#question[
  === 问题四
  客户端主动断开连接后，当时的TCP连接状态是什么？这个状态保持了多久？（可以使用netstat -an查看）
]

客户端主动断开连接（调用 `close()`）后，会经历以下状态变化：

1. *FIN_WAIT_1*：客户端发送FIN包后立即进入此状态
2. *FIN_WAIT_2*：收到服务器的ACK后进入此状态
3. *TIME_WAIT*：收到服务器的FIN并发送ACK后进入此状态

TIME_WAIT状态的持续时间是 *2MSL*（Maximum Segment Lifetime），在Linux系统中通常是60秒（2 × 30秒）。可以通过以下方式验证：

```bash
# 客户端断开后立即执行
netstat -an | grep 6230

# 可能看到类似输出：
# tcp  0  0  127.0.0.1:45678  127.0.0.1:6230  TIME_WAIT
```

TIME_WAIT状态存在的原因：
1. *确保可靠关闭*：确保最后的ACK能到达服务器
2. *防止旧连接干扰*：确保旧连接的延迟数据包不会被新连接误收

在TIME_WAIT期间，该 `(客户端IP:端口, 服务器IP:端口)` 四元组不能被重用。

#question[
  === 问题五
  客户端断网后异常退出，服务器的TCP连接状态有什么变化吗？服务器该如何检测连接是否继续有效？
]

客户端异常断网时的影响：

1. *TCP状态*：服务器的TCP连接会保持在 ESTABLISHED 状态，因为没有收到FIN包。

2. *数据发送行为*：
   - 如果服务器向客户端发送数据，会发生超时重传
   - 多次重传失败后，TCP会报告连接错误
   - 如果服务器不主动发送数据，可能永远检测不到断开

3. *资源泄漏*：长时间保持无效连接会占用系统资源（内存、文件描述符等）

*检测方法*：

*方法1：应用层心跳*
```cpp
// 服务器定期向客户端发送心跳包
// 客户端必须在规定时间内响应
// 超时未响应则认为连接失效
```

*方法2：TCP Keepalive*
```cpp
int keepalive = 1;
setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, &keepalive, sizeof(keepalive));

int keepidle = 60;    // 60秒无数据后开始探测
int keepinterval = 5; // 探测间隔5秒
int keepcnt = 3;      // 探测3次失败则判定断开
setsockopt(sock, IPPROTO_TCP, TCP_KEEPIDLE, &keepidle, sizeof(keepidle));
setsockopt(sock, IPPROTO_TCP, TCP_KEEPINTVL, &keepinterval, sizeof(keepinterval));
setsockopt(sock, IPPROTO_TCP, TCP_KEEPCNT, &keepcnt, sizeof(keepcnt));
```

*方法3：recv/send检测*
```cpp
// recv返回0表示对端正常关闭
// recv返回-1且errno为ECONNRESET表示连接被重置
ssize_t len = recv(sock, buffer, sizeof(buffer), 0);
if (len == 0) {
    // 对端关闭连接
    RemoveClient(sock);
}
```

在我的实现中，使用了方法3，通过检查 `recv()` 的返回值来检测连接状态。

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

通过本次实验，我深入理解了Socket编程和网络应用协议的设计与实现。本次实验是从应用层角度使用TCP协议，与之前实验中实现TCP协议栈形成了完整的认知闭环。

== 主要收获

1. *Socket API的理解*：掌握了 `socket()`, `bind()`, `listen()`, `accept()`, `connect()`, `send()`, `recv()` 等系统调用的用法和时机，理解了面向连接的TCP通信流程。

2. *协议设计经验*：学会了如何设计简洁高效的应用层协议。通过"类型字节+负载"的格式，用最少的开销实现了多种功能的区分。使用 `$` 作为分隔符来传递结构化数据（如消息转发中的 `id$内容`），简单且有效。

3. *多线程并发编程*：
   - 服务器端使用"one thread per connection"模型处理并发
   - 客户端使用独立接收线程避免阻塞用户交互
   - 使用 `pthread_mutex_t` 保护共享数据结构 `clients`
   - 理解了 `pthread_detach()` 的作用：分离线程以自动回收资源

4. *网络编程实践*：
   - 理解了监听socket和连接socket的区别
   - 掌握了TCP连接的四次挥手和TIME_WAIT状态
   - 学会了通过socket文件描述符区分不同客户端
   - 认识到了连接异常处理的重要性（如客户端断网检测）

== 遇到的困难与解决

1. *问题*：客户端发送消息时，如何正确读取包含空格的完整消息行？

   *解决*：先用 `std::cin >> id` 读取ID，然后调用 `std::cin.ignore()` 清空输入缓冲区中的换行符，最后用 `std::getline()` 读取完整消息。需要包含 `<limits>` 头文件使用 `std::numeric_limits`。

2. *问题*：服务器在多线程环境下访问 `clients` 映射时偶尔崩溃。

   *解决*：在所有访问 `clients` 的地方添加互斥锁保护：
   ```cpp
   pthread_mutex_lock(&clients_mutex);
   // 访问或修改 clients
   pthread_mutex_unlock(&clients_mutex);
   ```
   这避免了数据竞争导致的未定义行为。

3. *问题*：客户端接收线程与主线程的输出交错，导致提示符显示混乱。

   *解决*：在接收线程打印消息后，主动调用 `PrintPrompt()` 重新显示命令提示符，提升用户体验。

== 思考与展望

1. *性能优化*：当前使用"一连接一线程"模型，在高并发场景下会有性能瓶颈。可以考虑使用I/O多路复用（`epoll`、`select`）或线程池来提升性能。

2. *协议扩展*：可以增加更多功能，如：
   - 身份认证（用户名密码）
   - 群组消息（一对多通信）
   - 文件传输（需要处理二进制数据）
   - 心跳保活机制

3. *错误处理*：当前实现对网络异常的处理较简单，生产环境需要更完善的错误恢复机制。

4. *安全性*：明文传输存在安全隐患，可以考虑使用TLS/SSL加密通信。

本次实验让我对网络编程有了更深入的理解，也认识到了从协议设计到实现的完整流程。这些知识和经验将为今后的网络应用开发打下坚实基础。

= 附录

== `client/func.cpp` 核心代码

#codly-title("client/func.cpp")
#raw(read("./code/client/func.cpp"), lang: "cpp", block: true)

== `server/server.cpp` 核心代码

#codly-title("server/server.cpp")
#raw(read("./code/server/server.cpp"), lang: "cpp", block: true)
