#import "@preview/cetz:0.4.2"

#set text(size: 12pt, font: ("Times New Roman", "Source Han Serif SC"), lang: "cn")

#let title = [HW4]
#let stu_id = [3230106230]
#let name = [刘仁钦]

#let underline-box(content) = box(width: 1fr, stroke: (bottom: 0.5pt), outset: (bottom: 2pt))[#align(center)[#content]]

// math text
#let mt(content) = text(font: "Source Han Serif SC")[#content]

#set page(
  header: context {
    if counter(page).get().at(0) == 1 {
      return
    }
    underline-box[
      #set text(size: 10pt)
      #title
      #h(1fr)
      #stu_id #name
    ]
  }
)

#set page(numbering: "1 / 1")

#align(center, [
  #text(16pt)[*#title*]

  #text(12pt)[
    #datetime.today().display() \
    #stu_id #name
  ]
])\

1. 
  Bit rate per station: $R = (1000 "bit") / (100 "sec") = 10 "bps"$
  
  Maximum utilization for ALOHA: $1/(2e)$

  Maximum throughput: $56 "kbps" times 1/(2e) approx 10300.62 "bps"$

  $N times R <= 10.3 "kbps" arrow.double N <= 1030$

  Maximum value of $N$ is $1030$

2.
  The Manchester encoding is as @manchester-encoding. Using positive pulse to represent 1 and negative pulse to represent 0.

  #let bitstream = (0,0,0,1,1,1,0,1,0,1)
  #let bitstream-str = bitstream.map(bit => str(bit)).join(", ")

  #figure(caption: [Manchester encoding for #bitstream-str])[
    #cetz.canvas({
      import cetz.draw: *

      for (i, bit) in bitstream.enumerate() {
        // 在上方显示 bitstream 的值
        content((i + 0.5, 2), [#bit])
        line((i + 1, 0), (i + 1, 2), stroke: (dash: "dashed", paint: gray.lighten(50%)))
      }

      // X 轴
      line((0,0), (10.5,0), mark: (end: ">"), name: "time-axis")
      content("time-axis.end", [Time], anchor: "west", padding: 0.1)

      // Y 轴
      line((0,-0.5), (0,2.5), mark: (end: ">"), name: "volt-axis")
      content("volt-axis.end", [Voltage], anchor: "south", padding: 0.1)
      
      // Low 和 High 的标记
      content((0,0), [Low], anchor: "east", padding: 0.1)
      content((0,1.5), [High], anchor: "east", padding: 0.1)

      let points = ()
    
      for (i, bit) in bitstream.enumerate() {
        let x-start = i
        let x-mid = i + 0.5
        let x-end = i + 1
        let height = 1.2

        
        if bit == 0 {
          // 0 = High -> Low
          points.push((x-start, height))
          points.push((x-mid, height))
          points.push((x-mid, 0))
          points.push((x-end, 0))
        } else {
          // 1 = Low -> High
          points.push((x-start, 0))
          points.push((x-mid, 0))
          points.push((x-mid, height))
          points.push((x-end, height))
        }
      }

      line(..points, stroke: (paint: rgb(0, 0, 255), thickness: 1pt))

    }) 
  ] <manchester-encoding>

3.
  Round-trip propagation delay: $T_r = 2 times d / v = 2 times (1000 "m") / (2 times 10^8 "m/s") = 10^(-5) "s"$

  Mimimum frame transmission time: $T_t = L / R >= T_r$

  Therefore $L >= R times T_r = 10^9 "bps" times 10^(-5) "sec" = 10000 "bits"$

  $L / 8 = 1250 "bytes"$

  Thus, the minimum frame size is $1250 "bytes"$

4. 
  The standard 10-Mbps Ethernet uses Manchester encoding. In Manchester encoding, each bit is represented by two signal changes (one high-to-low or low-to-high transition). Therefore, the baud rate (symbol rate) is twice the data rate.

  For 10-Mbps Ethernet:

  Data rate = $10 "Mbps"$

  Baud rate = $2 times 10 "Mbps" = 20 "Mbaud"$

  Thus, the baud rate of the standard 10-Mbps Ethernet is $20 "Mbaud"$

5. C

6. B

7. B

8. C

9. B

10. C