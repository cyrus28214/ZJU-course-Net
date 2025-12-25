#import "@preview/numbly:0.1.0": numbly

#set text(size: 12pt, font: ("Noto Serif", "Noto Serif CJK SC"), lang: "en")

#let title = [HW6 Solutions]
#let stu_id = [3230106230]
#let name = [刘仁钦]

#let underline-box(content) = box(width: 1fr, stroke: (bottom: 0.5pt), outset: (bottom: 2pt))[#align(center)[#content]]

#set enum(full: true, numbering: numbly("{1:1.}"))

#align(center, [
  #text(16pt)[*#title*]

  #text(12pt)[
    #datetime.today().display() \
    #stu_id #name
  ]
])

1. The Jacobson algorithm updates the Estimated "RTT" using the formula:
  $"RTT"_"new" = alpha dot "RTT"_"old" + (1 - alpha) dot "RTT"_"sample"$
  Given $alpha = 0.9$ and initial $"RTT" = 30$ msec:
  - After 26 msec: $"RTT" = 0.9 dot 30 + 0.1 dot 26 = 27 + 2.6 = 29.6$ msec.
  - After 32 msec: $"RTT" = 0.9 dot 29.6 + 0.1 dot 32 = 26.64 + 3.2 = 29.84$ msec.
  - After 24 msec: $"RTT" = 0.9 dot 29.84 + 0.1 dot 24 = 26.856 + 2.4 = 29.256$ msec.
  
  The new RTT estimate is 29.256 msec.

2. We start with cwnd = 2 KB (1 MSS) and rwnd = 24 KB. The RTT is 10 msec.
  - $t = 0$ ms: Send 1 MSS (2 KB).
  - $t = 10$ ms: Receive ACK, cwnd becomes 2 MSS (4 KB). Send 2 MSS.
  - $t = 20$ ms: Receive ACKs, cwnd becomes 4 MSS (8 KB). Send 4 MSS.
  - $t = 30$ ms: Receive ACKs, cwnd becomes 8 MSS (16 KB). Send 8 MSS.
  - $t = 40$ ms: Receive ACKs, cwnd becomes 16 MSS (32 KB). However, the sender is limited by rwnd = 24 KB (12 MSS). 
  
  It takes 40 msec before the first full window (24 KB) can be sent.

3. In TCP Tahoe, when a timeout occurs:
  - ssthresh is set to half of the current cwnd: $128 / 2 = 64$ KB.
  - cwnd is reset to 1 MSS (1 KB).
  - Slow start occurs until cwnd reaches ssthresh, then congestion avoidance begins.
  
  - Bursts 1-6 (Slow Start): cwnd doubles each time ($1, 2, 4, 8, 16, 32 arrow.r 64$).
  - Bursts 7-10 (Congestion Avoidance): cwnd increases by 1 MSS per burst.
    - Burst 7: 65 KB
    - Burst 8: 66 KB
    - Burst 9: 67 KB
    - Burst 10: 68 KB
  
  The window will be 68 KB.

4. cwnd = 18 KB, Timeout occurs. MSS = 1 KB.
  - ssthresh = $18 / 2 = 9$ KB.
  - cwnd = 1 KB.
  - Burst 1: cwnd becomes 2 KB.
  - Burst 2: cwnd becomes 4 KB.
  - Burst 3: cwnd becomes 8 KB.
  - Burst 4: cwnd reaches ssthresh = 9 KB.
  
  The window will be 9 KB.

5. Given: Window = 65,535 bytes, Capacity = 1 Gbps, One-way delay = 10 ms (RTT = 20 ms).
  - Maximum Throughput = $"Window Size" / "RTT"$
    $"Throughput" = (65535 dot 8 "bits") / (0.020 "sec") = 26,214,000 "bps" = 26.2 "Mbps"$.
  - Line Efficiency = $"Throughput" / "Capacity"$
    $"Efficiency" = (26.214 "Mbps") / (1000 "Mbps") = 0.026214$.
  
  Maximum throughput: 26.2 Mbps

  Line efficiency: 2.6%

6. With an 8-bit sequence number, there are $2^8 = 256$ unique sequence numbers. To avoid wrap-around within the maximum TPDU lifetime ($T = 30$ sec):
  - Total data = $256 dot 128 "bytes" = 32,768 "bytes"$.
  - Max Data Rate = $(32,768 dot 8 "bits") / 30 "sec" approx 8,738.1 "bps"$.
  
  The maximum data rate is approximately 8.7 kbps.

7. The maximum length of an IP packet is 65,535 bytes (defined by a 16-bit length field). A standard IP header is 20 bytes and a standard TCP header is 20 bytes. 
  $65,535 - 20 - 20 = 65,495$ bytes.
  This number was chosen to allow a TCP segment to fit into the largest possible IP packet without fragmentation.

8. The sender's transmission is limited by the minimum of the congestion window and the receiver's advertised window:
  $"Allowed" = min("rwnd", "cwnd") = min(100 "KB", 50 "KB") = 50 "KB"$.
  The sender can transmit 50 KB.

9. D

10. D