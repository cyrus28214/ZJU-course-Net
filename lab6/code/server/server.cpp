#include "server.h"

// 全局变量初始化
int BaseSock = -1;
sockaddr_in Addr {};
// 请填入你的学号后四位作为端口号
u_short Port = 6230;
std::map<int, int> clients;
pthread_mutex_t clients_mutex = PTHREAD_MUTEX_INITIALIZER;

static int next_client_id = 1;

// 发送数据包
bool SendPacket(int sock, char type, const std::string& payload) {
    if (sock < 0) return false;
    
    uint16_t payload_len = payload.size();
    std::string packet;
    packet.reserve(1 + 2 + payload_len);
    packet.push_back(type);                      // 类型(1字节)
    packet.push_back((payload_len >> 8) & 0xFF); // 长度高字节
    packet.push_back(payload_len & 0xFF);        // 长度低字节
    packet.append(payload);                       // 负载数据
    
    ssize_t s = send(sock, packet.data(), packet.size(), 0);
    return s == (ssize_t)packet.size();
}

void RemoveClient(int sock) {
    pthread_mutex_lock(&clients_mutex);
    auto it = clients.find(sock);
    if (it != clients.end()) {
        int id = it->second;
        clients.erase(it);
        std::cout << "[SRV] Client " << id << " Disconnect Successfully." << std::endl;
    } else {
        std::cout << "[SRV] Unknown client socket disconnected: " << sock << std::endl;
    }
    pthread_mutex_unlock(&clients_mutex);
    if (sock >= 0) close(sock);
}

void BuildServer() {
    std::cout << "[SRV] Server Building" << std::endl;
    BaseSock = socket(AF_INET, SOCK_STREAM, 0);
    if (BaseSock < 0) {
        std::perror("socket");
        return;
    }

    Addr.sin_family = AF_INET;
    Addr.sin_addr.s_addr = INADDR_ANY;
    Addr.sin_port = htons(Port);

    int opt = 1;
    setsockopt(BaseSock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    if (bind(BaseSock, reinterpret_cast<sockaddr*>(&Addr), sizeof(Addr)) < 0) {
        std::perror("bind");
        close(BaseSock);
        return;
    }

    if (listen(BaseSock, 10) < 0) {
        std::perror("listen");
        close(BaseSock);
        return;
    }

    std::cout << "[SRV] Server Build Successfully." << std::endl;
    std::cout << "[SRV] Waiting for packs." << std::endl;

    while (true) {
        int client_sock = accept(BaseSock, nullptr, nullptr);
        if (client_sock < 0) {
            std::perror("accept");
            continue;
        }

        pthread_mutex_lock(&clients_mutex);
        clients[client_sock] = 0; // placeholder until CONNECT
        pthread_mutex_unlock(&clients_mutex);

        pthread_t tid;
        intptr_t arg = (intptr_t)client_sock;
        if (pthread_create(&tid, nullptr, Recieve, reinterpret_cast<void*>(arg)) != 0) {
            std::cerr << "[SRV] Failed to create thread for client" << std::endl;
            RemoveClient(client_sock);
        } else {
            pthread_detach(tid);
        }
    }
}

void* Recieve(void* lpParameter) {
    int sock = (int)(intptr_t)lpParameter;
    char buffer[MAXBUF] = {0};
    std::string recv_buffer;  // 接收缓冲区，处理粘包/拆包
    
    while (true) {
        ssize_t len = recv(sock, buffer, sizeof(buffer), 0);
        if (len <= 0) {
            RemoveClient(sock);
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

        if (type == CONNECT) {
            pthread_mutex_lock(&clients_mutex);
            int id = next_client_id++;
            clients[sock] = id;
            pthread_mutex_unlock(&clients_mutex);
            std::cout << "[SRV] Client " << id << " connect successfully!" << std::endl;
            SendPacket(sock, CONNECT, std::to_string(id));
            std::cout << "[SRV] Client ID returned." << std::endl;
        } else if (type == TIME) {
            pthread_mutex_lock(&clients_mutex);
            int id = clients[sock];
            pthread_mutex_unlock(&clients_mutex);
            std::cout << "[SRV] Receive a TIME request from client " << id << std::endl;
            std::time_t t = std::time(nullptr);
            std::string timestr = std::ctime(&t);
            if (!timestr.empty() && timestr.back() == '\n') timestr.pop_back();
            SendPacket(sock, TIME, timestr);
            std::cout << "[SRV] Time Sending Back Successfully." << std::endl;
        } else if (type == NAME) {
            pthread_mutex_lock(&clients_mutex);
            int id = clients[sock];
            pthread_mutex_unlock(&clients_mutex);
            std::cout << "[SRV] Receive a NAME request from client " << id << std::endl;
            char host[256] = {0};
            gethostname(host, sizeof(host));
            SendPacket(sock, NAME, std::string(host));
            std::cout << "[SRV] Name Sending Back Successfully." << std::endl;
        } else if (type == LIST) {
            pthread_mutex_lock(&clients_mutex);
            int id = clients[sock];
            std::cout << "[SRV] Receive a LIST request from client " << id << std::endl;
            std::string list;
            bool first = true;
            for (const auto &p : clients) {
                int cid = p.second;
                if (cid <= 0) continue;
                if (!first) list.push_back('$');
                list.append(std::to_string(cid));
                first = false;
            }
            pthread_mutex_unlock(&clients_mutex);
            SendPacket(sock, LIST, list);
            std::cout << "[SRV] List Sending Back Successfully." << std::endl;
        } else if (type == MESSAGE) {
            // payload: targetid$content
            pthread_mutex_lock(&clients_mutex);
            int srcid = clients[sock];
            pthread_mutex_unlock(&clients_mutex);
            std::cout << "[SRV] Receive a MESSAGE request from client " << srcid << std::endl;
            auto pos = payload.find('$');
            if (pos == std::string::npos) {
                SendPacket(sock, INVALID, "Bad message format");
                continue;
            }
            std::string target = payload.substr(0, pos);
            std::string content = payload.substr(pos + 1);
            int target_id = std::stoi(target);

            int target_sock = -1;
            pthread_mutex_lock(&clients_mutex);
            for (const auto &p : clients) {
                if (p.second == target_id) { target_sock = p.first; break; }
            }
            pthread_mutex_unlock(&clients_mutex);

            if (target_sock < 0) {
                SendPacket(sock, INVALID, "Target not found");
            } else {
                // forward as SIGNAL with payload srcid$content
                std::string forward = std::to_string(srcid) + "$" + content;
                SendPacket(target_sock, SIGNAL, forward);
                SendPacket(sock, MESSAGE, "Message Sending Success");
                std::cout << "[SRV] Message Sending Success" << std::endl;
            }
        } else if (type == DISCONNECT) {
            pthread_mutex_lock(&clients_mutex);
            int id = clients[sock];
            pthread_mutex_unlock(&clients_mutex);
            std::cout << "[SRV] Client " << id << " requested disconnect." << std::endl;
            RemoveClient(sock);
            return nullptr;
        } else {
            SendPacket(sock, INVALID, "Unsupported type");
        }
        }  // end while processing messages in recv_buffer
    }
    return nullptr;
}

int main() {
    BuildServer();
}
