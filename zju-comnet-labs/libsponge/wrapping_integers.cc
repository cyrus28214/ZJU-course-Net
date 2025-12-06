#include "wrapping_integers.hh"

using namespace std;

//! Transform an "absolute" 64-bit sequence number (zero-indexed) into a WrappingInt32
//! \param n The input absolute 64-bit sequence number
//! \param isn The initial sequence number
WrappingInt32 wrap(uint64_t n, WrappingInt32 isn) {
    // 将绝对序列号转换为32位循环序列号
    // 公式: seqno = (absolute_seqno + isn) mod 2^32
    return WrappingInt32{static_cast<uint32_t>(n) + isn.raw_value()};
}

//! Transform a WrappingInt32 into an "absolute" 64-bit sequence number (zero-indexed)
//! \param n The relative sequence number
//! \param isn The initial sequence number
//! \param checkpoint A recent absolute 64-bit sequence number
//! \returns the 64-bit sequence number that wraps to `n` and is closest to `checkpoint`
//!
//! \note Each of the two streams of the TCP connection has its own ISN. One stream
//! runs from the local TCPSender to the remote TCPReceiver and has one ISN,
//! and the other stream runs from the remote TCPSender to the local TCPReceiver and
//! has a different ISN.
uint64_t unwrap(WrappingInt32 n, WrappingInt32 isn, uint64_t checkpoint) {
    // n 在 32 位空间内相对于 isn 的偏移量
    uint32_t offset = n.raw_value() - isn.raw_value();
    
    // checkpoint 的高 32 位截取出来，和 offset 拼接
    uint64_t t = (checkpoint & 0xFFFFFFFF00000000) | offset;
    
    // 需要判断 t 是否离 checkpoint 足够近，是否需要 +/- 2^32
    uint64_t shift = 1UL << 32; // 2^32
    
    // 如果 t 比 checkpoint 大，且差距超过了半个周期
    if (t > checkpoint) {
        if (t - checkpoint > (shift >> 1)) {
            // 尝试减去 2^32，但要确保不会变成负数（uint64下溢）
            if (t >= shift) {
                return t - shift;
            }
            // 如果 t < 2^32，虽然它离 checkpoint 远，但减去后变负数了，只能返回 t
            return t;
        }
    } else {
        // 如果 t 比 checkpoint 小，且差距超过了半个周期
        if (checkpoint - t > (shift >> 1)) {
            // 加上 2^32，得到下一个周期的对应值
            return t + shift;
        }
    }
    
    return t;
}