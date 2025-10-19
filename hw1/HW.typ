#set text(size: 12pt, font: ("Source Han Serif SC"), lang: "cn")

#let title = [计算机网络 HW1]
#let stu_id = [3230106230]
#let name = [刘仁钦]

#let underline-box(content) = box(width: 1fr, stroke: (bottom: 0.5pt), outset: (bottom: 2pt))[#align(center)[#content]]

// math text
#let mt(content) = text(font: "Source Han Serif SC")[#content]

#set page(
  header: context {
    if counter(page).final().at(0) == 1 {
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

1. C. packet

2. D. datagram service

3. (a) Data Link Layer\
  (b) Network Layer

4. 
  总报头大小：$7 times 20 = 140 "bytes"$

  总数据大小：$1000 + 100 = 1140 "bytes"$

  报头比例：$140 / 1140 times 100% = 12.3%$

5. Speed of light in coax: $2 / 3 c = 2 times 10^8 "m/s"$

  Time to transmit a byte: $1 / 10"Mbps" = 1 times 10^(-7)"s"$

  Length of a byte: $2 times 10^8 "m/s" times 1 times 10^(-7)"s" = 20 "m"$

6. Request distance: $2 times 40000 "km" = 8 times 10^7 "m"$

  Response distance: $2 times 40000 "km"= 8 times 10^7 "m"$

  Total delay: $(8 times 10^7 "m" + 8 times 10^7 "m") / c = 533.3 "ms"$ (or $0.5 "s"$)

7. Total pixels: $1024 times 768 = 786,432$

  Total bytes: $786,432 times 3 = 2,359,296$

  Total bits: $2,359,296 times 8 = 18,874,368$

  (a) Transmit time: $18,874,368 / (56,000 "bits/s") = 337.0 "s"$

  (b) Transmit time: $18,874,368 / (1,000,000 "bits/s") = 18.9 "s"$

  (c) Transmit time: $18,874,368 / (10,000,000 "bits/s") = 1.9 "s"$

  (d) Transmit time: $18,874,368 / (100,000,000 "bits/s") = 0.2 "s"$

8. Number of router pairs: $mat(5; 2) = 10$

  Number of topologies: $4^10 = 1,048,576$

  Total time: $0.1 "s" times 1,048,576 = 104,857.6 "s"$ (or $29.1 "h"$)