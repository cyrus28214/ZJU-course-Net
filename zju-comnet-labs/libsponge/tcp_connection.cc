#include "tcp_connection.hh"

#include <iostream>
#include <limits>

using namespace std;

size_t TCPConnection::remaining_outbound_capacity() const { 
    return _sender.stream_in().remaining_capacity(); 
}

size_t TCPConnection::bytes_in_flight() const { 
    return _sender.bytes_in_flight(); 
}

size_t TCPConnection::unassembled_bytes() const { 
    return _receiver.unassembled_bytes(); 
}

size_t TCPConnection::time_since_last_segment_received() const { 
    return _time_since_last_segment_received; 
}

void TCPConnection::segment_received(const TCPSegment &seg) {
    if (!_is_active) return;
    
    _time_since_last_segment_received = 0;

    // 1. 如果设置了RST标志，将入站流和出站流都设置为错误状态，并永久终止连接。
    if (seg.header().rst) {
        _unclean_shutdown(false);
        return;
    }

    // 2. 把这个段交给TCPReceiver，这样它就可以在传入的段上检查它关心的字段：seqno、SYN、负载以及FIN。
    _receiver.segment_received(seg);

    // 3. 如果设置了ACK标志，则告诉TCPSender它关心的传入段的字段：ackno和window_size。
    if (seg.header().ack) {
        _sender.ack_received(seg.header().ackno, seg.header().win);
    }

    // 被动关闭检查：如果在出站流发送结束前，入站流已经全部接收完毕，则需要将_linger_after_streams_finish设置为false
    if (_receiver.stream_out().input_ended() && !_sender.stream_in().eof()) {
        _linger_after_streams_finish = false;
    }

    // 4. 如果传入的段包含一个有效的序列号，TCPConnection确保至少有一个段作为应答被发送，以反应ackno和window_size的更新。
    // 5. 如果传入的段包含一个无效的序列号，这种段被称为“keep-alive”...TCPConnection应该回复这些“keep-alive”。
    bool send_ack_needed = seg.length_in_sequence_space() > 0;
    
    // 判断 keep-alive (seqno = ackno - 1, length = 0)
    if (_receiver.ackno().has_value() && 
        seg.length_in_sequence_space() == 0 && 
        seg.header().seqno == _receiver.ackno().value() - 1) {
        send_ack_needed = true;
    }

    if (send_ack_needed) {
        _sender.fill_window();
        if (_sender.segments_out().empty()) {
            _sender.send_empty_segment();
        }
    }

    _push_segments_out();
}

bool TCPConnection::active() const { return _is_active; }

size_t TCPConnection::write(const string &data) {
    if (!_is_active) return 0;
    
    size_t written = _sender.stream_in().write(data);
    _sender.fill_window();
    _push_segments_out();
    
    return written;
}

//! \param[in] ms_since_last_tick number of milliseconds since the last call to this method
void TCPConnection::tick(const size_t ms_since_last_tick) {
    if (!_is_active) return;

    _time_since_last_segment_received += ms_since_last_tick;

    // 1. 告诉TCPSender时间的流逝。
    _sender.tick(ms_since_last_tick);

    // 2. 如果连续重传的次数超过上限TCPConfig::MAX_RETX_ATTEMPTS，则终止连接，并发送一个重置段给对端。
    if (_sender.consecutive_retransmissions() > TCPConfig::MAX_RETX_ATTEMPTS) {
        _unclean_shutdown(true);
        return;
    }

    _push_segments_out();

    // 3. 如有必要，结束连接。
    // 需要满足四个条件：入站流已经全部接收完毕；出站流已经全部发送完毕；需要发送的数据对方已完全确认。
    if (_receiver.stream_out().input_ended() &&
        _sender.stream_in().eof() &&
        _sender.bytes_in_flight() == 0) {
        
        // _linger_after_streams_finish 为 false 时对应 d.ii，立即结束连接。
        if (!_linger_after_streams_finish) {
            _is_active = false;
        } 
        // _linger_after_streams_finish 为 true 时对应 d.i，需要停留 10 * _cfg.rt_timeout 时间后结束
        else if (_time_since_last_segment_received >= 10 * _cfg.rt_timeout) {
            _is_active = false;
        }
    }
}

void TCPConnection::end_input_stream() {
    _sender.stream_in().end_input();
    _sender.fill_window();
    _push_segments_out();
}

void TCPConnection::connect() {
    _sender.fill_window();
    _is_active = true;
    _push_segments_out();
}

TCPConnection::~TCPConnection() {
    try {
        if (active()) {
            cerr << "Warning: Unclean shutdown of TCPConnection\n";
            _unclean_shutdown(true);
        }
    } catch (const exception &e) {
        std::cerr << "Exception destructing TCP FSM: " << e.what() << std::endl;
    }
}

void TCPConnection::_push_segments_out() {
    while (!_sender.segments_out().empty()) {
        TCPSegment seg = _sender.segments_out().front();
        _sender.segments_out().pop();
        size_t win_size = _receiver.window_size();
        if (win_size > std::numeric_limits<uint16_t>::max()) {
            seg.header().win = std::numeric_limits<uint16_t>::max();
        } else {
            seg.header().win = static_cast<uint16_t>(win_size);
        }
        if (_receiver.ackno().has_value()) {
            seg.header().ack = true;
            seg.header().ackno = _receiver.ackno().value();
        }

        _segments_out.push(seg);
    }
}

void TCPConnection::_unclean_shutdown(bool send_rst) {
    _sender.stream_in().set_error();
    _receiver.stream_out().set_error();
    _is_active = false;

    if (send_rst) {
        _sender.send_empty_segment();
        if (!_sender.segments_out().empty()) {
            TCPSegment rst_seg = _sender.segments_out().front();
            _sender.segments_out().pop();
            rst_seg.header().ack = false;
            rst_seg.header().rst = true;
            _segments_out.push(rst_seg);
        }
    }
}