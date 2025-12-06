#include "tcp_receiver.hh"

using namespace std;

void TCPReceiver::segment_received(const TCPSegment &seg) {
    // 判断当前是否为Listen状态（未正式建立连接，需要 syn 启动）
    if (!_isn.has_value()) {
        // 是，则判断是否为 SYN 包
        if (seg.header().syn) {
            // 是，获得初始序列号ISN，设置状态为SYN_RECV
            _isn = seg.header().seqno;
        } else {
            // 否，则数据传输未开始，丢弃数据包
            return;
        }
    }
    
    // 否，则将该数据包中payload的数据放进流重组器（调用 push_substring)，并传入FIN
    // 注意：本实验中 SYN 和 FIN 可同时置 1
    // SYN 包和 FIN 包可以同时携带有具体传递的信息
    
    // 计算流索引：将序列号转换为绝对序列号，然后转换为流索引
    // 绝对序列号从0开始（ISN对应绝对序列号0），包含SYN和FIN
    // 流索引从0开始，排除SYN和FIN
    // 对于SYN包：seqno=ISN对应absolute_seqno=0，payload从absolute_seqno=1开始（stream_index=0）
    // 对于普通包：seqno对应absolute_seqno，数据从absolute_seqno开始（stream_index=absolute_seqno-1）
    // checkpoint应该是下一个期望接收的绝对序列号
    uint64_t checkpoint = _reassembler.stream_out().bytes_written() + 1;  // 使用已写入字节数+1作为checkpoint（对应下一个期望的绝对序列号）
    uint64_t absolute_seqno = unwrap(seg.header().seqno, _isn.value(), checkpoint);
    
    // 计算流索引
    // 绝对序列号0是SYN，绝对序列号1是第一个数据字节（流索引0）
    // 对于SYN包：seqno=ISN对应absolute_seqno=0，payload从absolute_seqno=1开始（stream_index=0）
    // 对于普通包：seqno对应absolute_seqno，数据从absolute_seqno开始（stream_index=absolute_seqno-1）
    uint64_t stream_index;
    if (seg.header().syn) {
        // SYN包的seqno对应absolute_seqno=0，payload从absolute_seqno=1开始
        // 所以stream_index = absolute_seqno + 1 - 1 = absolute_seqno
        // 但实际上，如果absolute_seqno=0，payload从stream_index=0开始
        stream_index = absolute_seqno;  // 当absolute_seqno=0时，payload从stream_index=0开始
    } else {
        // 普通包的seqno对应absolute_seqno，数据从absolute_seqno开始
        // 但stream_index需要排除SYN，所以减1
        stream_index = absolute_seqno - 1;
    }
    
    // 获取payload数据
    string payload = seg.payload().copy();
    
    // 调用流重组器
    _reassembler.push_substring(payload, stream_index, seg.header().fin);
    
    // 如果收到FIN，标记
    if (seg.header().fin) {
        _fin_received = true;
    }
}

optional<WrappingInt32> TCPReceiver::ackno() const {
    // 判断当前是否为Listen状态
    if (!_isn.has_value()) {
        // 是，返回空
        return {};
    }
    
    // 否，查询尚未获取到的第一个字节的流索引，将流索引转换为序列号（32位的）返回
    // 流索引是下一个期望接收的字节的索引
    uint64_t stream_index = _reassembler.stream_out().bytes_written();
    
    // 将流索引转换为绝对序列号（需要加上SYN占用的1个序列号）
    uint64_t absolute_seqno = stream_index + 1;
    
    // !!! 注意：如果当前处于 FIN_RECV 状态，则还需要加上 FIN 标志长度
    if (_fin_received && _reassembler.stream_out().input_ended()) {
        absolute_seqno += 1;  // FIN也占用一个序列号
    }
    
    // 将绝对序列号转换为32位序列号
    return wrap(absolute_seqno, _isn.value());
}

size_t TCPReceiver::window_size() const {
    // 计算总容量_capacity与流重组器_reassembler中已存数据量(_output)的差值
    size_t bytes_in_buffer = _reassembler.stream_out().bytes_written() - 
                             _reassembler.stream_out().bytes_read();
    return _capacity - bytes_in_buffer;
}
