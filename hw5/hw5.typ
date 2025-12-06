#import "@preview/cetz:0.4.2"
  #import "@preview/numbly:0.1.0": numbly

#set text(size: 12pt, font: ("Noto Serif", "Noto Serif CJK SC"), lang: "cn")
#show raw: set text(font: ("JetBrainsMono NF", "Noto Sans CJK SC"))

#let title = [HW5]
#let stu_id = [3230106230]
#let name = [刘仁钦]

#let underline-box(content) = box(width: 1fr, stroke: (bottom: 0.5pt), outset: (bottom: 2pt))[#align(center)[#content]]

#set enum(full: true, numbering: numbly("{1:1.}", "{2:(a).}"))

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

1. Yes. Noise in physical lines may cause errors in the transmitted data. There is a very small change that the error happens in both the destination IP and the checksum, and coincidentally the checksum can pass the verification. In this case, the packet will be delivered to the wrong destination.

2. 
  ```
  0xC2 = 194
  0x2F = 47
  0x15 = 21
  0x82 = 130
  ```

  The IP address in dotted decimal notation is `192.47.21.130`.

3.
  1. `135.46.63.10`
  
    Matches `135.46.60.0/22` (`60 = 00111100`, `63 = 00111111`, the first 22 bits match).
    
    Next hop: `159.48.0.1`

  2. `135.46.57.14`

    Matches `135.46.56.0/22` (`56 = 00111000`, `57 = 00111001`, the first 22 bits match).

    Next hop: `211.90.0.1`

  3. `135.46.52.2`

    Does not match `56.0/22` or `60.0/22`.

    Next hop: `220.20.0.1` (Default)

  4. `192.53.40.7`

    Matches `192.53.40.0/23`.

    Next hop: `192.188.0.1`

  5. `192.53.56.7`

    Does not match `192.53.40.0/23` (40=00101000, 56=00111000, the 21st bit differs).

    Next hop: `220.20.0.1` (Default)

4. 
  Subnet mask `255.255.240.0` corresponds to `/20`. 
  
  Host bits = $32 - 20 = 12$
  
  Maximum addresses = $2^(12) = 4096$.
  
  Usable hosts = $4096 - 2 = 4094$

5. 
  Original Packet: Data 900B + TCP Header 20B = 920B.
  
  Total IP Length = 940B.
  
  Link A-R1 (MTU 1010): No fragmentation needed.
  
  Link R1-R2 (MTU 504): Fragmentation required.
  
  - Max IP Payload = $504 - 20 = 484$. 
    
    Must be a multiple of 8 $arrow.r$ 480B.
  
    Fragment 1: Payload 480B. Total = 500B. Offset = 0. MF = 1
    
    Fragment 2: Remaining Payload $920 - 480 = 440$B.
    
    Total = $440 + 20 = 460$B. Offset = $480/8 = 60$. MF = 0.
  
  Link R2-B (MTU 500): Both fragments fit directly; no further fragmentation needed.

  #table(
    columns: 5,
    [*Link*], [*Packet No.*], [*Total length*], [*MF*], [*Fragment offset*],
    [$A arrow.r "R1"$], [1], [940], [0], [0],
    [$"R1" arrow.r "R2"$], [1], [500], [1], [0],
    [$"R1" arrow.r "R2"$], [2], [460], [0], [60],
    [$"R2" arrow.r "B"$], [1], [500], [1], [0],
    [$"R2" arrow.r "B"$], [2], [460], [0], [60],
  )

6. #table(
    columns: 4,
    [*Org No.*], [*First IP*], [*Last IP*], [*net/mask*],
    [A], [198.16.0.0], [198.16.15.255], [198.16.0.0/20],
    [B], [198.16.16.0], [198.16.23.255], [198.16.16.0/21],
    [C], [198.16.32.0], [198.16.47.255], [198.16.32.0/20],
    [D], [198.16.64.0], [198.16.95.255], [198.16.64.0/19],
  )

7. C

8. B

9. D