;; define breeds of turtles
breed [influencers influencer]
breed [traders trader]

;; variables of turtles
turtles-own[
  sentiment
  distance-from-other-turtles
  turtle-component
  node-clustering-coefficient
  rd-index
]

;; variables of traders
traders-own[
  balance
  stock
  news-sens
  infl-sens
  peer-sens
  self-sens
  net-worth
  sign

  close-to-infl?
  num-neighbors
  mean-net-worth-neighbors
  influencer?
]

links-own[
  rewired?                             ;; keeps track of whether the link has been rewired or not
  link-component
]

;; global variables
globals[
  clustering-coefficient               ;; the clustering coefficient of the network; this is the
                                       ;; average of clustering coefficients of all turtles
  average-path-length                  ;; average path length of the network
  clustering-coefficient-of-lattice    ;; the clustering coefficient of the initial lattice
  average-path-length-of-lattice       ;; average path length of the initial lattice
  infinity                             ;; a very large number.
                                       ;; used to denote distance between two turtles which
                                       ;; don't have a connected or unconnected path between them
  agent-string                         ;; message that appears on the node properties monitor
  network-string
  number-rewired                       ;; number of edges that have been rewired. used for plots.
  rewire-one?                          ;; these two variables record which button was last pushed
  rewire-all?

  available-stock
  stock-price
  price-inc
  news-sentiment

  gini-coef                           ;;  Gini index
  lorenz-points                       ;; list of Lorenz points
  price-list                          ;; list of price history

]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to startup
  set agent-string ""
  set network-string ""
end

to setup
  clear-all
  set infinity 99999                    ;; just an arbitrary choice for a large number
  set-default-shape turtles "circle"
  make-turtles
  set stock-price 100
  set price-inc 0.3
  set available-stock 500

  set number-rewired 0
  set network-string ""
  set agent-string ""
  set price-list []
  compute-networth

  reset-ticks
end

to go
  generate-news
  perceive-sentiment
  trade
  compute-networth
  update-appearance
  update-lorenz-and-gini
  update-neighbors-info
  update-price-history

  tick
  if ticks mod 200 = 0 [
    stop
  ]
end

to generate-news
  set news-sentiment random-normal 0 0.5
  if news-sentiment < -1 [ set news-sentiment -1 ]
  if news-sentiment > 1 [ set news-sentiment 1 ]
end

to perceive-news
  ask traders [
    set sentiment (news-sentiment * news-sens * (1 - self-sens) + sentiment * self-sens)
  ]
end

to perceive-peer
  ask traders [
    let peer-sentiment mean [sentiment] of link-neighbors
    set sentiment (peer-sentiment * peer-sens * (1 - self-sens) + sentiment * self-sens)
  ]
end

to perceive-sentiment
  ask traders [
    ifelse influencer?
    [
      set sentiment random-normal 0 0.5
    ]
    [
      let peer-mean 0
      if count link-neighbors with [breed = traders] > 0
      [ set peer-mean mean [sentiment] of link-neighbors with [breed = traders] ]

      let infl-mean 0
      if count link-neighbors with [breed = influencers]> 0
      [ set infl-mean mean [sentiment] of link-neighbors with [breed = influencers] ]
      set sentiment min (list 1 max (list -1 (news-sentiment * news-sens + peer-mean * peer-sens + infl-mean * infl-sens + sentiment * self-sens)))
    ]
  ]

  ask influencers [
    set sentiment random-normal 0 0.5
  ]
end

to trade
  ask traders [
    let trade-quantity 0
    let trade-sign 1

    if sentiment > 0.3 and balance > stock-price and available-stock > 0
    [
      set trade-quantity floor (sentiment / 0.3)
      if compute-cost trade-quantity > balance
      [
        set trade-quantity (trade-quantity - 1)
      ]
      set trade-quantity min (list available-stock trade-quantity)
    ]
    if sentiment < -0.3 and stock > 0 and stock-price >= 1
    [
      set trade-quantity floor (abs sentiment / 0.3)
      set trade-quantity min (list stock trade-quantity)
      set trade-sign (- 1)
    ]
    set stock (stock + trade-quantity * trade-sign)

    let cost (stock-price * trade-quantity * trade-sign + trade-sign * price-inc * (trade-quantity * (trade-quantity - 1) / 2))
    set balance (balance - cost)
    set stock-price (stock-price + trade-sign * trade-quantity * price-inc)
    set available-stock (available-stock - trade-sign * trade-quantity)
  ]
end

to update-price-history
  set price-list lput stock-price price-list
end

to update-neighbors-info
  ask traders with [breed = traders] [
      ifelse (any? link-neighbors with [breed = traders])[
      set mean-net-worth-neighbors mean [net-worth] of link-neighbors with [breed = traders]
    ][set mean-net-worth-neighbors -1000]

   ]
end

to-report compute-cost [trade-quantity]
  report (stock-price * trade-quantity + price-inc * (trade-quantity * (trade-quantity - 1) / 2))
end

to-report compute-earn [trade-quantity]
  report (stock-price * trade-quantity - price-inc * (trade-quantity * (trade-quantity - 1) / 2))
end

to compute-networth
  ask traders [
    set net-worth (balance + stock * stock-price)
  ]
end

to update-appearance
  ask traders [
    ifelse abs(sentiment) < 0.3
    [ set color gray + 3 ]
    [ ifelse sentiment > 0
      [ set color green + 3 - 2 * floor((sentiment - 0.3) / 0.3)]
      [ set color red + 3 - 2 * floor(- (sentiment + 0.3) / 0.3)]
    ]

    set size 0.3 + net-worth / 2000
  ]

  ask influencers [
    ifelse abs(sentiment) < 0.3
    [ set color gray + 3 ]
    [ ifelse sentiment > 0
      [ set color green + 3 - 2 * floor((sentiment - 0.3) / 0.3)]
      [ set color red + 3 - 2 * floor(- (sentiment + 0.3) / 0.3)]
    ]
  ]
end

to make-turtles
  if infl-sens-on? [
    create-influencers num-influencer [
      set color gray + 2
      set size 2
      set shape "star"
    ]
  ]

  create-traders num-nodes [
    set color gray + 2

    ifelse news-sens-on?
    [ set news-sens max (list -1 min (list 1 (random-normal news-sens-mean 0.2))) ]
    [ set news-sens 0 ]

    ifelse peer-sens-on?
    [ set peer-sens max (list -1 min (list 1 (random-normal peer-sens-mean 0.2))) ]
    [ set peer-sens 0]

    ifelse infl-sens-on?
    [ set infl-sens max (list -1 min (list 1 (random-normal infl-sens-mean 0.2)))]
    [ set infl-sens 0]

    ifelse (random-float 1) < contrarian-investing [
      set sign -1
      set news-sens (news-sens * sign)
      set peer-sens (peer-sens * sign)
      set infl-sens (infl-sens * sign)
    ] [ set sign 1 ]

    set self-sens random-float 1

    set balance 1000
    set sentiment 0
    set stock 10
    set turtle-component 0
    set influencer? false


  ]

  let n 0
  ask turtles [
    set rd-index n
    set n (n + 1)
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedure ;;;
;;;;;;;;;;;;;;;;;;;;;;;

;; update ;;

to update-lorenz-and-gini
  ; recompute value of gini-coefficient and the points in lorenz-points for the Lorenz and Gini-Index plots
  let sorted-wealths sort [net-worth] of traders
  let total-wealth sum sorted-wealths
  let wealth-sum-so-far 0
  let index 0
  let c-turtles count traders
  set gini-coef 0
  set lorenz-points []
  ; plot the Lorenz curve -- along the way, we also calculate the Gini index
  repeat c-turtles [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-wealths)
    set lorenz-points lput ((wealth-sum-so-far / total-wealth) * 100) lorenz-points
    set index (index + 1)
    set gini-coef gini-coef + (index / c-turtles) - (wealth-sum-so-far / total-wealth)
  ]

end

to-report weekly-price-dev
  ifelse length price-list < 7 [
    report standard-deviation price-list
  ]
  [
    let len length price-list
    let price-7-days sublist price-list (len - 7) len
    report standard-deviation price-7-days
  ]
end

to-report mean-monthly-dev
  ifelse length price-list > 90
  [
    let quarter last-n-items price-list 90
    let devs []
    set devs lput standard-deviation (sublist quarter 0 30) devs
    set devs lput standard-deviation (sublist quarter 30 60) devs
    set devs lput standard-deviation (sublist quarter 60 90) devs
    report mean devs
  ]
  [
    report standard-deviation last-n-items price-list 30
  ]
end

to-report last-n-items [input-list n]
  report sublist input-list (max list 0 (length input-list - n)) length input-list
end

;; network ;;
to rewire

  ;; make sure num-turtles is setup correctly; if not run setup first
  if count turtles != num-nodes + num-influencer [
    setup-lattice
  ]

  ;; set up a variable to see if the network is connected
  let success? false

  ;; if we end up with a disconnected network, we keep trying, because the APL distance
  ;; isn't meaningful for a disconnected network.
  while [not success?] [
    ;; kill the old lattice, reset neighbors, and create new lattice
    ask links [ die ]
    setup-lattice

    ask links [
      set rewired? false
      ;; whether to rewire it or not?
      if (random-float 1) < rewiring-probability
      [
        ;; "a" remains the same
        let node1 end1
        ;; if "a" is not connected to everybody
        if [ count link-neighbors ] of end1 < (count turtles - 1)
        [
          ;; find a node distinct from node1 and not already a neighbor of node1
          let node2 one-of turtles with [ (self != node1) and (not link-neighbor? node1) ]
          ;; wire the new edge
          ask node1 [ create-link-with node2 [ set color cyan  set rewired? true ] ]

          set number-rewired number-rewired + 1  ;; counter for number of rewirings
          set rewired? true
        ]
      ]
      ;; remove the old edge
      if (rewired?)
      [
        die
      ]
    ]
    ;; check to see if the new network is connected and calculate path length and clustering
    ;; coefficient at the same time
    set success? do-calculations
  ]
  ;; do the plotting
  update-plots
end

to add-edges
  let v1 0
  while [v1 < count turtles - 1] [
    let node1 turtle v1
    ask node1 [
      let v2 (v1 + 1)
      while [v2 < count turtles] [
        let node2 turtle v2
        if not link-neighbor? node2 and (random-float 1) < connect-probability [
          create-link-with node2
        ]
        set v2 v2 + 1
      ]
    ]
    set v1 v1 + 1
  ]

  ;; check to see if the new network is connected and calculate path length and clustering
  ;; coefficient at the same time
  let success? do-calculations

  ;; do the plotting
  update-plots
end


;; do-calculations reports true if the network is connected,
;;   and reports false if the network is disconnected.
;; (In the disconnected case, the average path length does not make sense,
;;   or perhaps may be considered infinite)
to-report do-calculations

  ;; set up a variable so we can report if the network is disconnected
  let connected? true

  ;; find the path lengths in the network
  find-path-lengths

  let num-connected-pairs sum [length remove infinity (remove 0 distance-from-other-turtles)] of turtles

  ;; In a connected network on N nodes, we should have N(N-1) measurements of distances between pairs,
  ;; and none of those distances should be infinity.
  ;; If there were any "infinity" length paths between nodes, then the network is disconnected.
  ;; In that case, calculating the average-path-length doesn't really make sense.
  ifelse ( num-connected-pairs != (count turtles * (count turtles - 1) ))
  [
      set average-path-length infinity
      ;; report that the network is not connected
      set connected? false
  ]
  [
    set average-path-length (sum [sum distance-from-other-turtles] of turtles) / (num-connected-pairs)
  ]
  ;; find the clustering coefficient and add to the aggregate for all iterations
  find-clustering-coefficient

  set network-string (word "clustering-coefficient = " precision clustering-coefficient 2
    ", average-path-length = " precision average-path-length 2
    ", edges = " count links)

  ;; report whether the network is connected or not
  report connected?
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Clustering computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report in-neighborhood? [ hood ]
  report ( member? end1 hood and member? end2 hood )
end


to find-clustering-coefficient
  ifelse all? turtles [count link-neighbors <= 1]
  [
    set clustering-coefficient 0
  ]
  [
    let total 0
    ask turtles with [ count link-neighbors <= 1]
      [ set node-clustering-coefficient "undefined" ]
    ask turtles with [ count link-neighbors > 1]
    [
      let hood link-neighbors
      set node-clustering-coefficient (2 * count links with [ in-neighborhood? hood ] /
                                         ((count hood) * (count hood - 1)) )
      ;; find the sum for the value at turtles
      set total total + node-clustering-coefficient
    ]
    ;; take the average
    set clustering-coefficient total / count turtles with [count link-neighbors > 1]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Path length computations ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Implements the Floyd Warshall algorithm for All Pairs Shortest Paths
;; It is a dynamic programming algorithm which builds bigger solutions
;; from the solutions of smaller subproblems using memoization that
;; is storing the results.
;; It keeps finding incrementally if there is shorter path through
;; the kth node.
;; Since it iterates over all turtles through k,
;; so at the end we get the shortest possible path for each i and j.

to find-path-lengths
  ;; reset the distance list
  ask turtles
  [
    set distance-from-other-turtles []
  ]

  let i 0
  let j 0
  let k 0
  let node1 one-of turtles
  let node2 one-of turtles
  let node-count count turtles
  ;; initialize the distance lists
  while [i < node-count]
  [
    set j 0
    while [j < node-count]
    [
      set node1 turtle i
      set node2 turtle j
      ;; zero from a node to itself
      ifelse i = j
      [
        ask node1 [
          set distance-from-other-turtles lput 0 distance-from-other-turtles
        ]
      ]
      [
        ;; 1 from a node to it's neighbor
        ifelse [ link-neighbor? node1 ] of node2
        [
          ask node1 [
            set distance-from-other-turtles lput 1 distance-from-other-turtles
          ]
        ]
        ;; infinite to everyone else
        [
          ask node1 [
            set distance-from-other-turtles lput infinity distance-from-other-turtles
          ]
        ]
      ]
      set j j + 1
    ]
    set i i + 1
  ]
  set i 0
  set j 0
  let dummy 0
  while [k < node-count]
  [
    set i 0
    while [i < node-count]
    [
      set j 0
      while [j < node-count]
      [
        ;; alternate path length through kth node
        set dummy ( (item k [distance-from-other-turtles] of turtle i) +
                    (item j [distance-from-other-turtles] of turtle k))
        ;; is the alternate path shorter?
        if dummy < (item j [distance-from-other-turtles] of turtle i)
        [
          ask turtle i [
            set distance-from-other-turtles replace-item j distance-from-other-turtles dummy
          ]
        ]
        set j j + 1
      ]
      set i i + 1
    ]
    set k k + 1
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Edge Operations ;;;
;;;;;;;;;;;;;;;;;;;;;;;

;; creates a new lattice
to setup-lattice
  setup
  ;; iterate over the turtles
  layout-circle (sort-on [rd-index] turtles) max-pxcor - 1
  let nodes (sort-on [rd-index] turtles)
  let n 0
  while [n < count turtles]
  [
    ;; make edges with the next two neighbors
    ;; this makes a lattice with average degree of 4
    make-edge item n nodes
              item ((n + 1) mod (count turtles)) nodes
    make-edge item n nodes
              item ((n + 2) mod (count turtles)) nodes
    set n (n + 1)
  ]
  update-edge-color
  let success? do-calculations
end

to setup-scalefree
  setup
  let n 1
  let nodes []
  ifelse boost-influence?
  [ set nodes (sort-on [who] turtles) ]
  [ set nodes (sort-on [rd-index] turtles) ]
  while [n < scalefree-edges + 1]
  [
    ;; make edges with the next two neighbors
    ;; this makes a lattice with average degree of 4
    ifelse n >= count turtles
    [
      let node1 find-partner
      let node2 one-of turtles with [ (self != node1) and (not link-neighbor? node1) ]
      ;; wire the new edge
      make-edge node1 node2

    ]
    [
      ifelse n > 1
      [
        let partner find-partner
        make-edge partner (item n nodes)
      ]
      [
        let partner item 0 nodes
        make-edge partner (item n nodes)
      ]
    ]
    set n n + 1
  ]
  update-edge-color
  ask traders with [breed = traders] [
      ifelse shape = "pentagon" [ set close-to-infl? True ] [ if shape = "circle" [ set close-to-infl? False ]]
      ifelse any? link-neighbors [
      set num-neighbors count link-neighbors
    ] [set num-neighbors 0]
   ]

  let success? do-calculations
  repeat 10 [ layout-tutte (turtles with [count link-neighbors > 4]) links 16 ]
end

to setup-disconnected-scalefree
  setup
  ask influencers [
    set turtle-component (who mod 2)
  ]
  ask traders [
    ifelse who < 4
    [
      set turtle-component (who mod 2)
    ]
    [
      ifelse (who - 4) < component-ratio * (num-nodes - 4)
      [
        set turtle-component 0
      ]
      [
        set turtle-component 1
      ]
    ]
  ]

  ask turtle 2 [
    create-link-with turtle 0 [set link-component 0]
    move-to turtle 0
    ;        fd 5
  ]

  ask turtle 3 [
    create-link-with turtle 1 [set link-component 1]
    move-to turtle 1
    ;        fd 5
  ]
  let n 4
  while [n < scalefree-edges + 2]
  [
    ;; make edges with the next two neighbors
    ;; this makes a lattice with average degree of 4
    ifelse n >= count turtles
    [
      let node1 find-partner
      let comp [turtle-component] of node1
      let node2 one-of turtles with [ (turtle-component = comp) and (self != node1) and (not link-neighbor? node1) ]
      ;; wire the new edge
      ask node1 [
        create-link-with node2 [ set link-component comp ]
      ]
    ]
    [
      ask turtle n [
        let comp turtle-component
        let partner find-component-partner comp
        create-link-with partner [set link-component comp]
        move-to partner
      ]
    ]
    set n n + 1
  ]
  update-edge-color
  let success? do-calculations
  layout-circle (sort-on [turtle-component] turtles) max-pxcor - 1
end

to-report find-partner
  report [one-of both-ends] of one-of links
end

to-report find-component-partner [component]
  report [one-of both-ends] of one-of links with [link-component = component]
end

to update-edge-color
  ask links [
    set color gray - 1
    ifelse ([breed] of end1 = traders) and ([breed] of end2 = traders)
    [
      if not peer-sens-on? [ set color gray - 3 ]
    ]
    [
      set color gray + 4
      if ([breed] of end1 = traders) and ([breed] of end2 = influencers)
      [
        ask end1 [ set shape "pentagon" ]
      ]
      if ([breed] of end2 = traders) and ([breed] of end1 = influencers)
      [
        ask end2 [ set shape "pentagon" ]
      ]
    ]
  ]
end

;; connects the two turtles
to make-edge [node1 node2]
  ask node1 [ create-link-with node2  [
    set rewired? false
  ] ]
end

;;;;;;;;;;;;;;;;
;;; Graphics ;;;
;;;;;;;;;;;;;;;;

to highlight
  ;; remove any previous highlights
  update-appearance
  ask links [ set color gray ]
  if mouse-inside? [ do-highlight ]
  display
end

to do-highlight
  ;; getting the node closest to the mouse
  let min-d min [distancexy mouse-xcor mouse-ycor] of turtles
  let node one-of turtles with [count link-neighbors > 0 and distancexy mouse-xcor mouse-ycor = min-d]
  if node != nobody
  [
    ;; highlight the chosen node
    ask node
    [
      set color pink - 1
      let pairs (length remove infinity distance-from-other-turtles)
      let local-val (sum remove infinity distance-from-other-turtles) / pairs
      ;; show node's clustering coefficient
      ifelse breed = traders
      [
        let adjusted-news-sens (news-sens + peer-sens * mean [news-sens] of link-neighbors with [breed = traders])
        set agent-string (word "sens(n, p, p'n, s) = (" precision news-sens 1
          ", " precision peer-sens 1
          ", " precision adjusted-news-sens 1
          ", " precision self-sens 1
          "), worth = " precision net-worth 1
          ", sent = " precision sentiment 1)
      ]
      [
        set agent-string (word "sentiment = " precision sentiment 1)
      ]
    ]
    let neighbor-nodes [ link-neighbors ] of node
    let direct-links [ my-links ] of node
    ;; highlight neighbors
    ask neighbor-nodes
    [
      set color blue - 1

      ;; highlight edges connecting the chosen node to its neighbors
      ask my-links [
        ifelse (end1 = node or end2 = node)
        [
          set color blue + 1 ;
        ]
        [
          if (member? end1 neighbor-nodes and member? end2 neighbor-nodes)
            [ set color yellow + 1]
        ]
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
274
20
632
379
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-17
17
-17
17
1
1
1
ticks
30.0

SLIDER
13
288
156
321
num-nodes
num-nodes
10
125
50.0
1
1
NIL
HORIZONTAL

SLIDER
15
74
171
107
rewiring-probability
rewiring-probability
0
1
1.0
0.01
1
NIL
HORIZONTAL

BUTTON
184
74
259
107
NIL
rewire
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
266
393
637
438
node properties
agent-string
3
1
11

BUTTON
176
532
258
565
NIL
highlight
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
162
289
257
322
setup-lattice
setup-lattice
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
164
210
257
243
NIL
setup-scalefree
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
16
32
171
65
connect-probability
connect-probability
0
1
0.0
0.01
1
NIL
HORIZONTAL

BUTTON
185
32
258
65
NIL
add-edges
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
13
210
155
243
scalefree-edges
scalefree-edges
20
200
100.0
1
1
NIL
HORIZONTAL

BUTTON
13
532
76
565
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
88
533
163
566
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
950
10
1150
164
Stock price over time
ticks
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"stock-price" 1.0 0 -2139308 true "" "plot stock-price"

PLOT
636
167
864
317
Net-worth histogram
Net worth
Turtles
0.0
3000.0
0.0
50.0
false
true
"set-plot-y-range 0 count traders\nset-plot-x-range 1000 3000\nset-histogram-num-bars 7" "if max [net-worth] of traders > plot-x-max\n[ set-plot-x-range plot-x-min (plot-x-max + 1000)]\n\nif max [net-worth] of traders < plot-x-max - 1000\n[ set-plot-x-range plot-x-min (plot-x-max - 1000)]\n\nif min [net-worth] of traders < plot-x-min\n[ set-plot-x-range (plot-x-min - 100) plot-x-max]\n\nset-histogram-num-bars 7"
PENS
"total" 1.0 1 -16777216 true "" "histogram [net-worth] of traders"
"anti" 1.0 1 -2139308 true "" "set-histogram-num-bars 7\nhistogram [net-worth] of traders with [news-sens < 0 or infl-sens < 0]"
"normal" 1.0 1 -11085214 true "" "set-histogram-num-bars 7\nhistogram [net-worth] of traders with [ news-sens > 0 and infl-sens > 0 ]"

PLOT
868
167
1097
317
Mean net-worth
Ticks
Mean net-worth
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Peer-copy" 1.0 0 -1604481 true "" "plot mean [net-worth] of traders with [ peer-sens > 0 and abs peer-sens > (abs news-sens + abs infl-sens)]"
"Peer-anti" 1.0 0 -5298144 true "" "plot mean [net-worth] of traders with [ peer-sens < 0 and abs peer-sens > (abs news-sens + abs infl-sens)]"
"News-copy" 1.0 0 -8330359 true "" "plot mean [net-worth] of traders with [news-sens > 0 and abs news-sens > 1.5 * abs peer-sens]"
"News-anti" 1.0 0 -14439633 true "" "plot mean [net-worth] of traders with [ news-sens < 0 and abs news-sens > 1.5 * abs peer-sens]"
"Infl-copy" 1.0 0 -8020277 true "" "plot mean [net-worth] of traders with [ infl-sens > 0 and abs infl-sens > 1.5 * abs peer-sens]"
"Infl-anti" 1.0 0 -14070903 true "" "plot mean [net-worth] of traders with [ infl-sens < 0 and abs infl-sens > 1.5 * abs peer-sens]"
"Starting" 1.0 0 -7500403 true "" "plot 2000"

MONITOR
745
326
850
371
Max net-worth
max [net-worth] of traders
1
1
11

MONITOR
642
327
741
372
Min net-worth
min [net-worth] of traders
1
1
11

MONITOR
267
441
630
486
Network properties
network-string
17
1
11

MONITOR
639
10
737
55
NIL
news-sentiment
2
1
11

TEXTBOX
79
345
229
364
Sensitivity Settings\n
13
0.0
1

TEXTBOX
91
10
241
29
Network Settings
13
0.0
1

SLIDER
11
379
133
412
news-sens-mean
news-sens-mean
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
12
490
258
523
contrarian-investing
contrarian-investing
0
0.2
0.0
0.01
1
NIL
HORIZONTAL

PLOT
1102
165
1310
316
net-worth
NIL
NIL
0.0
10.0
0.0
5000.0
true
true
"" ""
PENS
"min" 1.0 0 -2674135 true "" "plot min [net-worth] of traders\n"
"max" 1.0 0 -13840069 true "" "plot max [net-worth] of traders\n"
"mean" 1.0 0 -1184463 true "" "plot mean [net-worth] of traders\n"
"median" 1.0 0 -6459832 true "" "plot median [net-worth] of traders\n"

PLOT
861
324
1068
485
Lorenz Curve
% investors
% total net-worth
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Lorenz" 1.0 0 -16777216 true "" "plot-pen-reset\nset-plot-pen-interval 100 / count turtles\nplot 0 \nforeach lorenz-points plot"

PLOT
1073
323
1311
485
Gini-index
Ticks
Gini
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Gini" 1.0 0 -16777216 true "" "plot (gini-coef / count turtles ) / 0.5"

MONITOR
643
429
739
474
Final Gini
(gini-coef / count turtles ) / 0.5
2
1
11

PLOT
1153
10
1367
163
Weekly deviation
Ticks
Stdv
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Vix" 1.0 0 -16777216 true "" "plot standard-deviation last-n-items price-list 7"

MONITOR
643
480
740
525
Monthly dev
standard-deviation last-n-items price-list 30
1
1
11

MONITOR
643
377
740
422
Mean net-worth
mean [net-worth] of traders
0
1
11

MONITOR
745
377
851
422
Median net-worth
median [net-worth] of traders
0
1
11

MONITOR
745
428
852
473
% with net-profit
((count traders with [net-worth > 2000]) / num-nodes) * 100
0
1
11

BUTTON
68
160
227
193
NIL
setup-disconnected-scalefree
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
16
118
260
151
component-ratio
component-ratio
0
1
0.51
0.01
1
NIL
HORIZONTAL

PLOT
744
10
947
164
News sentiment
tick
sentiment
0.0
10.0
-2.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot news-sentiment"
"zero" 1.0 0 -7500403 true "" "plot 0"

SLIDER
13
249
126
282
num-influencer
num-influencer
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
12
416
134
449
peer-sens-mean
peer-sens-mean
-1
1
0.5
0.1
1
NIL
HORIZONTAL

SWITCH
144
380
263
413
news-sens-on?
news-sens-on?
1
1
-1000

SWITCH
143
416
261
449
peer-sens-on?
peer-sens-on?
0
1
-1000

SWITCH
144
454
257
487
infl-sens-on?
infl-sens-on?
0
1
-1000

SLIDER
12
454
134
487
infl-sens-mean
infl-sens-mean
-1
1
0.8
0.1
1
NIL
HORIZONTAL

SWITCH
127
249
270
282
boost-influence?
boost-influence?
0
1
-1000

MONITOR
747
480
850
525
Quarterly dev
standard-deviation sublist price-list (max list 0 (length price-list - 90)) length price-list
1
1
11

TEXTBOX
1029
501
1179
526
Monitors
20
0.0
1

TEXTBOX
485
619
635
637
NIL
11
0.0
0

@#$#@#$#@
## WHAT IS IT?

This model explores behaviours of the virtual stock market under various conditions, such as sensitivities and network structures. 

## AUTHORS

Hailey Kim 

## HOW IT WORKS

Parameter are adjustable as discribed in the report. 

## THINGS TO TRY

Try highlight function to examine each node's properties in depth. Note that it must be selected before in use.

## EXTENDING THE MODEL

Try to see if you can produce the same results if you start with a different initial network. Create new BehaviorSpace experiments to compare results.

## LAST UPDATE

31 Oct. 2020
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
setup
repeat 5 [rewire-one]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="exp2-lattice" repetitions="50" runMetricsEveryStep="false">
    <setup>setup-lattice</setup>
    <go>go</go>
    <metric>standard-deviation sublist price-list (max list 0 (length price-list - 90)) length price-list</metric>
    <metric>(gini-coef / count turtles ) / 0.5</metric>
    <metric>((count traders with [net-worth &gt; 2000]) / num-nodes) * 100</metric>
    <metric>max [net-worth] of traders</metric>
    <metric>[net-worth] of traders</metric>
    <enumeratedValueSet variable="peer-sens-mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="news-sens-on?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-mean">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-influencer">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="exp2-random" repetitions="50" runMetricsEveryStep="false">
    <setup>setup-lattice
rewire</setup>
    <go>go</go>
    <metric>standard-deviation sublist price-list (max list 0 (length price-list - 90)) length price-list</metric>
    <metric>(gini-coef / count turtles ) / 0.5</metric>
    <metric>((count traders with [net-worth &gt; 2000]) / num-nodes) * 100</metric>
    <metric>max [net-worth] of traders</metric>
    <metric>[net-worth] of traders</metric>
    <enumeratedValueSet variable="peer-sens-mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="news-sens-on?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-mean">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-influencer">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scalefree-edges">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.01"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="exp2-scalefree-bst" repetitions="50" runMetricsEveryStep="false">
    <setup>setup-scalefree</setup>
    <go>go</go>
    <metric>standard-deviation sublist price-list (max list 0 (length price-list - 90)) length price-list</metric>
    <metric>(gini-coef / count turtles ) / 0.5</metric>
    <metric>((count traders with [net-worth &gt; 2000]) / num-nodes) * 100</metric>
    <metric>max [net-worth] of traders</metric>
    <metric>[net-worth] of traders</metric>
    <enumeratedValueSet variable="peer-sens-mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="news-sens-on?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-mean">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-influencer">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scalefree-edges">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boost-influence?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="exp3-news (use this)" repetitions="50" runMetricsEveryStep="false">
    <setup>setup-scalefree</setup>
    <go>go</go>
    <metric>[mean-net-worth-neighbors] of traders with [breed = traders]</metric>
    <metric>[num-neighbors] of traders with [breed = traders]</metric>
    <metric>[news-sens] of traders with [breed = traders]</metric>
    <metric>[peer-sens] of traders with [breed = traders]</metric>
    <metric>[self-sens] of traders with [breed = traders]</metric>
    <metric>[net-worth] of traders with [breed = traders]</metric>
    <metric>[sign] of traders with [breed = traders]</metric>
    <enumeratedValueSet variable="peer-sens-mean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="news-sens-mean">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="news-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-influencer">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scalefree-edges">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boost-influence?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="exp1b-peers" repetitions="50" runMetricsEveryStep="false">
    <setup>setup-lattice</setup>
    <go>go</go>
    <metric>standard-deviation sublist price-list (max list 0 (length price-list - 90)) length price-list</metric>
    <metric>(gini-coef / count turtles ) / 0.5</metric>
    <metric>((count traders with [net-worth &gt; 2000]) / num-nodes) * 100</metric>
    <metric>[net-worth] of traders</metric>
    <enumeratedValueSet variable="contrarian-investing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="peer-sens-mean" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="news-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="news-sens-mean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-mean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-influencer">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="exp1a-news" repetitions="50" runMetricsEveryStep="false">
    <setup>setup-lattice</setup>
    <go>go</go>
    <metric>standard-deviation sublist price-list (max list 0 (length price-list - 90)) length price-list</metric>
    <metric>(gini-coef / count turtles ) / 0.5</metric>
    <metric>((count traders with [net-worth &gt; 2000]) / num-nodes) * 100</metric>
    <metric>[net-worth] of traders</metric>
    <enumeratedValueSet variable="contrarian-investing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-sens-mean">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="news-sens-mean" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="news-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-mean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-influencer">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="exp1-combi" repetitions="50" runMetricsEveryStep="false">
    <setup>setup-lattice</setup>
    <go>go</go>
    <metric>standard-deviation sublist price-list (max list 0 (length price-list - 90)) length price-list</metric>
    <metric>(gini-coef / count turtles ) / 0.5</metric>
    <metric>((count traders with [net-worth &gt; 2000]) / num-nodes) * 100</metric>
    <metric>[net-worth] of traders</metric>
    <enumeratedValueSet variable="contrarian-investing">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="peer-sens-mean">
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="news-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="news-sens-mean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infl-sens-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="infl-sens-mean" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="num-influencer">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
