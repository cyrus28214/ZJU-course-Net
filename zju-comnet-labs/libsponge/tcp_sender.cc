#include "tcp_sender.hh"

#include "tcp_config.hh"

#include <random>

using namespace std;

//! \param[in] capacity the capacity of the outgoing byte stream
//! \param[in] retx_timeout the initial amount of time to wait before retransmitting the oldest outstanding segment
//! \param[in] fixed_isn the Initial Sequence Number to use, if set (otherwise uses a random ISN)
TCPSender::TCPSender(const size_t capacity, const uint16_t retx_timeout, const std::optional<WrappingInt32> fixed_isn)
    : _isn(fixed_isn.value_or(WrappingInt32{random_device()()}))
    , _initial_retransmission_timeout{retx_timeout}
    , _stream(capacity)
    , _ackno(0)
    , _window_size(1)
    , _rto(retx_timeout)
    , _timer(0)
    , _timer_running(false)
    , _consecutive_retransmissions(0)
    , _syn_sent(false)
    , _fin_sent(false) {}

uint64_t TCPSender::bytes_in_flight() const {
    size_t total = 0;
    for (const auto &pair : _outstanding_segments) {
        total += pair.second.length_in_sequence_space();
    }
    return total;
}

void TCPSender::fill_window() {
    // 如果远程窗口大小为 0, 则把其视为 1 进行操作
    uint16_t effective_window = _window_size == 0 ? 1 : _window_size;
    
    // 计算可用窗口大小：窗口右边界 - 下一个要发送的序列号
    // 窗口右边界 = _ackno + effective_window
    uint64_t window_right = _ackno + effective_window;
    
    while (_next_seqno < window_right) {
        // 1. 如果尚未发送SYN数据包，则设置header的syn位
        if (!_syn_sent) {
            TCPSegment seg;
            seg.header().syn = true;
            seg.header().seqno = wrap(_next_seqno, _isn);
            _syn_sent = true;
            
            // 如果没有正在等待的数据包，则重设更新时间
            if (_outstanding_segments.empty()) {
                _timer = 0;
                _timer_running = true;
            }
            
            // 发送数据包并追踪
            uint64_t seg_start = _next_seqno;
            _next_seqno += 1;
            _outstanding_segments[seg_start] = seg;
            _segments_out.push(seg);
            continue;
        }
        
        // 2. 设置seqno和payload
        // 计算可以发送的payload大小
        // 可用空间 = window_right - _next_seqno
        size_t available = window_right - _next_seqno;
        size_t payload_size = min(available, static_cast<size_t>(TCPConfig::MAX_PAYLOAD_SIZE));
        payload_size = min(payload_size, _stream.buffer_size());
        
        // 如果没有任何数据（没有设置syn，没有fin，没有payload），则停止数据包的发送（break）
        if (payload_size == 0 && _stream.eof() && !_fin_sent) {
            // 3. 若满足条件则增加FIN
            // 从来没发送过 FIN 且 输入字节流处于 EOF 且 window减去payload大小后，仍可存放下 FIN
            if (_next_seqno < window_right) {
                TCPSegment seg;
                seg.header().seqno = wrap(_next_seqno, _isn);
                seg.header().fin = true;
                _fin_sent = true;
                
                // 如果没有正在等待的数据包，则重设更新时间
                if (_outstanding_segments.empty()) {
                    _timer = 0;
                    _timer_running = true;
                }
                
                // 发送数据包并追踪
                uint64_t seg_start = _next_seqno;
                _next_seqno += 1;
                _outstanding_segments[seg_start] = seg;
                _segments_out.push(seg);
                
                // 如果设置了 fin，则break
                break;
            } else {
                break;
            }
        }
        
        if (payload_size == 0) {
            break;
        }
        
        TCPSegment seg;
        seg.header().seqno = wrap(_next_seqno, _isn);
        string payload = _stream.read(payload_size);
        seg.payload() = Buffer(move(payload));
        
        // 3. 若满足条件则增加FIN
        // 从来没发送过 FIN 且 输入字节流处于 EOF 且 window减去payload大小后，仍可存放下 FIN
        // 如果该包设置了syn的话，还得算上syn的大小
        if (!_fin_sent && _stream.eof()) {
            // 检查是否有空间放置FIN
            size_t current_seg_size = seg.length_in_sequence_space();
            if (_next_seqno + current_seg_size < window_right) {
                seg.header().fin = true;
                _fin_sent = true;
            }
        }
        
        size_t seg_size = seg.length_in_sequence_space();
        
        // 如果没有正在等待的数据包，则重设更新时间
        if (_outstanding_segments.empty()) {
            _timer = 0;
            _timer_running = true;
        }
        
        // 发送数据包并追踪
        uint64_t seg_start = _next_seqno;
        _next_seqno += seg_size;
        _outstanding_segments[seg_start] = seg;
        _segments_out.push(seg);
        
        // 如果设置了 fin，则break
        if (seg.header().fin) {
            break;
        }
    }
}

//! \param ackno The remote receiver's ackno (acknowledgment number)
//! \param window_size The remote receiver's advertised window size
void TCPSender::ack_received(const WrappingInt32 ackno, const uint16_t window_size) {
    // 将ackno转换为绝对序列号
    uint64_t absolute_ackno = unwrap(ackno, _isn, _ackno);
    
    // 如果传入的 ack 是不可靠的（ack_seqno大于next_seqno），则直接丢弃
    if (absolute_ackno > _next_seqno) {
        return;
    }
    
    // 更新窗口大小
    _window_size = window_size;
    
    // 遍历数据结构（用来存储发送的segment），如果一个发送的segment已经被成功接收，则
    bool acked_something = false;
    for (auto it = _outstanding_segments.begin(); it != _outstanding_segments.end();) {
        uint64_t seg_start = it->first;
        uint64_t seg_end = seg_start + it->second.length_in_sequence_space();
        
        if (seg_end <= absolute_ackno) {
            // 1. 从数据结构中将该segment丢弃
            it = _outstanding_segments.erase(it);
            acked_something = true;
        } else {
            ++it;
        }
    }
    
    if (acked_something) {
        // 2. 重置重传计时器
        _timer = 0;
        // 3. 将RTO重置为初始值
        _rto = _initial_retransmission_timeout;
        // 重置连续重传计数器
        _consecutive_retransmissions = 0;
    }
    
    // 更新_ackno
    if (absolute_ackno > _ackno) {
        _ackno = absolute_ackno;
    }
    
    // 调用fill_window继续发送数据（更新窗口大小后，接收方可能有了新的接收空间，所以应该再次发送数据）
    fill_window();
    
    // 如果所有数据都被确认了，停止重传计时器
    if (_outstanding_segments.empty()) {
        _timer_running = false;
    }
}

//! \param[in] ms_since_last_tick the number of milliseconds since the last call to this method
void TCPSender::tick(const size_t ms_since_last_tick) {
    // 如果计时器正在运行，更新计时器
    if (_timer_running) {
        _timer += ms_since_last_tick;
        
        // 如果重传计时器超时
        if (_timer >= _rto) {
            // 遍历追踪列表，如果存在发送中的数据包，并且重传计时器超时
            if (!_outstanding_segments.empty()) {
                // 重置重传定时器
                _timer = 0;
                
                // 重传尚未被 TCP 接收方完全确认的序列号最小的段
                auto it = _outstanding_segments.begin();
                _segments_out.push(it->second);
                
                // 如果对方接收窗口大小不为0（说明网络拥堵）
                if (_window_size > 0) {
                    // 超时重传时间 RTO 的值加倍，即*2
                    _rto *= 2;
                    // 连续重传计时器增加
                    _consecutive_retransmissions++;
                } else {
                    // 如果窗口大小为0，不增加RTO，但增加连续重传计数
                    _consecutive_retransmissions++;
                }
            }
        }
    }
}

unsigned int TCPSender::consecutive_retransmissions() const {
    return _consecutive_retransmissions;
}

void TCPSender::send_empty_segment() {
    // 生成并发送一个payload长度为零的TCPSegment，并且序列号设置正确
    TCPSegment seg;
    seg.header().seqno = wrap(_next_seqno, _isn);
    _segments_out.push(seg);
}
