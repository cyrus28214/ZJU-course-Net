#include "func.h"
#include <limits>

namespace {

bool SendPacket(char type, const std::string& payload = "") {
    if (!connected || BaseSock < 0) return false;
    
    uint16_t payload_len = payload.size();
    std::string packet;
    packet.reserve(1 + 2 + payload_len);
    packet.push_back(type);                      // 类型(1字节)
    packet.push_back((payload_len >> 8) & 0xFF); // 长度高字节
    packet.push_back(payload_len & 0xFF);        // 长度低字节
    packet.append(payload);                       // 负载数据

    ssize_t sent = send(BaseSock, packet.data(), packet.size(), 0);
    return sent == (ssize_t)packet.size();
}

}  // namespace

void PrintPrompt() {
    std::cout << "\n[CLI] Your command: " << std::flush;
}

void ServerConnect() {
    if (connected) {
        std::cout << "[SYS] Already connected." << std::endl;
        return;
    }

    std::string ip;
    int port;
    std::cout << "[SYS] Please enter the IP address and port you want to connect to." << std::endl;
    std::cout << "[CLI] IP address: ";
    std::cin >> ip;
    std::cout << "[CLI] Port number: ";
    std::cin >> port;

    std::cout << "[SYS] Connecting ..." << std::endl;

    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        std::perror("socket");
        return;
    }

    Addr.sin_family = AF_INET;
    Addr.sin_port = htons(port);
    if (inet_pton(AF_INET, ip.c_str(), &Addr.sin_addr) <= 0) {
        std::cerr << "[SYS] Invalid IP address." << std::endl;
        close(sock);
        return;
    }

    if (connect(sock, reinterpret_cast<sockaddr*>(&Addr), sizeof(Addr)) < 0) {
        std::perror("connect");
        close(sock);
        return;
    }

    BaseSock = sock;
    connected = true;
    std::cout << "[SYS] Connection Success!" << std::endl;

    SendPacket(CONNECT, "");

    // start receive thread
    if (pthread_create(&thread, nullptr, Recieve, nullptr) != 0) {
        std::cerr << "[SYS] Failed to start receive thread." << std::endl;
        // still connected, but no receive thread
    } else {
        pthread_detach(thread);
    }
}

void ServerDisconnect() {
    if (!connected) return;
    SendPacket(DISCONNECT, "");
    connected = false;
    close(BaseSock);
    BaseSock = -1;
    std::cout << "[SYS] Disconnection Success" << std::endl;
}

void GetTime() {
    if (!connected) { std::cout << "[SYS] Not connected." << std::endl; return; }
    for (int i = 0; i < 100; ++i) {
        if (SendPacket(TIME, "")) std::cout << "[SYS] Request Sending Success" << std::endl;
    }
}

void GetName() {
    if (!connected) { std::cout << "[SYS] Not connected." << std::endl; return; }
    if (SendPacket(NAME, "")) std::cout << "[SYS] Request Sending Success" << std::endl;
}

void ClientList() {
    if (!connected) { std::cout << "[SYS] Not connected." << std::endl; return; }
    if (SendPacket(LIST, "")) std::cout << "[SYS] Request Sending Success" << std::endl;
}

void SendMessa() {
    if (!connected) { std::cout << "[SYS] Not connected." << std::endl; return; }

    std::string id;
    std::string msg;
    std::cout << "[SYS] Please Enter Other Clients' ID and the Message (only one line)" << std::endl;
    std::cout << "[CLI] Client ID: ";
    std::cin >> id;
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    std::cout << "[CLI] Message: ";
    std::getline(std::cin, msg);
    std::string payload = id + "$" + msg;
    if (SendPacket(MESSAGE, payload)) std::cout << "[SYS] Message Sending Success." << std::endl;
}

void ExitComm() {
    if (connected) {
        ServerDisconnect();
    }
    std::cout << "[SYS] Bye~" << std::endl;
}

void* Recieve(void* lpParameter) {
    (void)lpParameter;
    char buffer[MAXBUF] = {0};
    std::string recv_buffer;  // 接收缓冲区
    
    while (connected) {
        ssize_t len = recv(BaseSock, buffer, sizeof(buffer), 0);
        if (!connected) break;
        if (len <= 0) {
            std::cout << "[SYS] Server disconnected or error." << std::endl;
            connected = false;
            if (BaseSock >= 0) close(BaseSock);
            BaseSock = -1;
            break;
        }

        recv_buffer.append(buffer, len);

        // 循环处理缓冲区中的完整消息
        while (recv_buffer.size() >= 3) {  // 至少需要Type(1) + Length(2)
            char type = recv_buffer[0];
            uint16_t payload_len = ((uint8_t)recv_buffer[1] << 8) | (uint8_t)recv_buffer[2];
            
            if (recv_buffer.size() < 3 + payload_len) {
                break;  // 数据不完整，等待下次recv
            }
            
            std::string payload = recv_buffer.substr(3, payload_len);
            recv_buffer.erase(0, 3 + payload_len);  // 移除已处理的数据

        static int time_recv_cnt = 0;

        switch (type) {
            case CONNECT:
                std::cout << "\n[CONNECT]" << std::endl;
                std::cout << "[SYS] Your Client ID is " << payload << std::endl;
                break;
            case TIME:
                std::cout << "\n[TIME]" << std::endl;
                std::cout << "[SYS] Current Time is: " << payload << ", " << ++time_recv_cnt << " responses received." << std::endl;
                break;
            case NAME:
                std::cout << "\n[NAME]" << std::endl;
                std::cout << "[SYS] Server Hostname is: " << payload << std::endl;
                break;
            case LIST:
                std::cout << "\n[LIST]" << std::endl;
                std::cout << "[SYS] Client List: " << payload << std::endl;
                break;
            case MESSAGE:
                std::cout << "\n[MESSAGE]" << std::endl;
                std::cout << "[SYS] Server Reply: " << payload << std::endl;
                break;
            case SIGNAL: {
                std::cout << "\n[RECEIVE MESSAGE]" << std::endl;
                // payload expected: srcid$contents
                auto pos = payload.find('$');
                if (pos != std::string::npos) {
                    std::string src = payload.substr(0, pos);
                    std::string msg = payload.substr(pos + 1);
                    std::cout << "[SYS] Client " << src << " Just Sent A Message to you:\n";
                    std::cout << msg << std::endl;
                } else {
                    std::cout << "[SYS] Received signal: " << payload << std::endl;
                }
                break;
            }
            case INVALID:
            default:
                std::cout << "\n[INVALID] " << payload << std::endl;
                break;
        }
        PrintPrompt();
        }  // end while processing messages in recv_buffer
    }
    return nullptr;
}
