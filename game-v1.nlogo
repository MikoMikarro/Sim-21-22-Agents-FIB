globals [
  fog-of-war?

  p-valids   ; Valid Patches for moving not wall)
  Start      ; Starting patch
  Final-Cost ; The final cost of the path given by A*

  any-cured? ; Checks if any human is cured

  total_distance ; Distance of all the humans to cure
]

breed [humans human]
breed [zombies zombie]
breed [cures cure]

humans-own[
  cured?     ; If a human is cured, it is invisible to zombies and can cure other humans
  changing? ; if changing > 0, human will become a zombie, when changing? == 3, human becomes a zombie
  distance_to_cure ; Self explained
]

patches-own [
  real-color
  visible?
  visited_once?

  father     ; Previous patch in this partial path
  Cost-path  ; Stores the cost of the path to the current patch
  visited?   ; has the path been visited previously? That is,
             ; at least one path has been calculated going through this patch
  active?    ; is the patch active? That is, we have reached it, but
             ; we must consider it because its children have not been explored
  block?     ; If true, it's a wall
  safe?      ; If true, no zombies are close
  border_wall?; Self explained
]

to setup
  clear-all
  reset-ticks

  ; UI interface
  set-patch-size 12

  ask patches
  [
    ; Initial values of patches for A*
    set father nobody
    set Cost-path 0
    set visited? false
    set active? false
    set block? false
    set border_wall? false

    ; Initial values of fogwar
    set visited_once? false
  ]
  ; Globals
  set fog-of-war? true
  set any-cured? false

  ; Random colored map
  create-map
  setup-random-walls
  if limits? [

    ask patches with [pxcor = min-pxcor or pxcor = max-pxcor or pycor = min-pycor or pycor = max-pycor or
    pxcor = (min-pxcor + 1) or pxcor = (max-pxcor - 1) or pycor = (min-pycor + 1) or pycor = ( max-pycor - 1 )] [
      set block? True
      set pcolor brown
      set real-color brown
      set border_wall? True
    ]
  ]

  create-cures 1[
    set size 1
    set shape "circle"
    let ppp  one-of patches with [not block? and (distance (one-of patches with[pxcor = 0 and pycor = 0]) > safeRadius)]
    setxy [pxcor] of ppp [pycor] of ppp
    set color blue
  ]
  ; Init turtles
  create-humans humans-initial-number[
    set cured? false
    set size 2
    set shape "person"
    ;let ppp  one-of patches with [not block?]
    let ppp  one-of patches with [not block? and (distance (one-of patches with[pxcor = 0 and pycor = 0]) <= (0.75 * safeRadius))]
    setxy [pxcor] of ppp [pycor] of ppp
    set color blue
  ]
  create-zombies zombies-initial-number [
    set size 2
    set shape "person"
    set color red - 1.8
    ;setxy random-xcor random-ycor
    let ppp  one-of patches with [not block? and (distance (one-of patches with[pxcor = 0 and pycor = 0]) > safeRadius)]
    setxy [pxcor] of ppp [pycor] of ppp
  ]

  ; Init map



end

to go
  ; Draw map for humans

  ; stop the model if there are no wolves and no sheep
  if not any? humans [ user-message "Zombies have conquered the world" stop ]
  if all? humans [cured?] [user-message "Humanity has survived the apocalypse" stop]
  ; stop the model if there are no wolves and the number of sheep gets very large
  ;if not any? wolves and count sheep > max-sheep [ user-message "The sheep have inherited the earth" stop ]

  ask patches [
    set safe? true
    set visible? false
    if fog-of-war? [
      ifelse visited_once?
        [set pcolor real-color - ((real-color mod 10) / 2)]
        [set pcolor black]
    ]
  ]

  ; Human movement
  ask humans  [
    view human-sight true
  ]

  ask humans [
    human-behaviour
  ]

  ; Zombie movement
  ask zombies [
    zombie-behaviour
  ]

  if any? humans[
    set total_distance mean [distance_to_cure] of humans
  ]

  tick

end



; view algorithm. Inputs:
;   - view-range : patches it sees
;   - do-view    : marks patches as seen -> only used by humans
to view [view-range do-view]
  let temp_heading heading
  let angulos n-values 180 [ i -> i ]
  let radios n-values view-range [ i -> i ]

  foreach angulos[
    [a]->
    set heading (a * 2)
    let exists? true
    let index 1
    while [index < (length radios) and exists?]
    [
      let r item index radios
      set index (index + 1)
      let p patch-ahead r
      ask p [
        ifelse block?
        [
          set visible? do-view
          set visited_once? do-view
          set exists? false
        ]
        [
          set visible? do-view
          set visited_once? do-view
          set pcolor real-color
        ]
      ]
    ]
  ]
  set heading temp_heading
end

to zombie-behaviour

  let on-visible-patch = patch xcor ycor visible?
  set Start patch xcor ycor
  let targets humans with [distance myself < zombie-sight and cured? = false]
  let path false

  ask targets [
    let Goal patch xcor ycor
    set p-valids patches with [distance myself < zombie-sight and block? = false]
    ifelse Start != Goal [
      set path A* Start Goal p-valids

      if path != false [

        ; comienza zombificacion de la victima
;        if changing? = 0 [
;          set changing? 1
;          set color violet
;        ]


        stop

      ]
    ]
    [;else ; Start = Goal
        ; comienza zombificacion de la victima
        if changing? = 0 [
          set changing? 1
          set color violet
        ]
    ]
  ]

  ifelse path != false[
    if length path > 1 [
      ;set heading towards item 1 path
      set heading towards item 1 path
      forward 1
    ]

  ]
  [wander]


  ; VISUALs
  if fog-of-war? [
    ifelse on-visible-patch
    [ show-turtle ]
    [ hide-turtle ]
  ]
end

to human-behaviour

  ;zombification process
  ifelse changing? > 0 [
    ifelse changing? > 3 [  ; human becomes a zombie

      let xpos xcor
      let ypos ycor

      hatch-zombies 1 [
        set size 2
        set shape "person"
        set color red - 1.8
        setxy xpos ypos
      ]
      die

    ]
    [ ;else   ;human is turning into a zombie
      set changing? (changing? + 1)
    ]
  ]
  [;else Normal behaviour

    let moved false
    ifelse not any-cured?[
      let cure-patch 0
      ask cures[
        set cure-patch patch xcor ycor
      ]

      if distance cure-patch < 2 [
        get-cure
      ]

      ; Avoid zombies
      ask zombies[
        let my-patch patch xcor ycor
        if [visible?] of my-patch[
          ask patches in-radius 2 [
            set safe? false
          ]
        ]
      ]
      set distance_to_cure distance cure-patch
      if [visible?] of cure-patch [

        set Start patch xcor ycor
        let Goal cure-patch
        let p-valid human-p-valids

        let path A* Start Goal p-valid

        if (path != false) and (length path > 1)[
          move-to (item 1 path)
          forward 1
          set moved true
        ]
      ]
    ]
    [ ; else
      let targets "foo"
      ifelse cured?
      [
        set targets humans with [not cured?]
      ]
      [; else
        set targets humans with [cured?]
      ]
      let path false
      set Start patch xcor ycor
      ask targets [
        let Goal patch xcor ycor
        if [cured?] of myself [
          if distance myself < 2 [
            get-cure
          ]
        ]
        set p-valids human-p-valids

        if Start != Goal [
          set path A* Start Goal p-valids
          if path != false [
            stop
          ]
        ]
      ]
      if path != false [
        if length path > 1 [
          ;set heading towards item 1 path
          if (item 1 path) != (patch xcor ycor) [

            set heading towards item 1 path

            forward 1
            set moved true
          ]
        ]
      ]
    ]
    if not moved [ wander ]
  ]
end

to get-cure
  set color white
  set cured? true
  set any-cured? true
  set changing? 0
  set distance_to_cure 0
  ask cures [ die ]

end
to wander
  move-to one-of neighbors with [block? = false]
end

to-report human-p-valids
  report patches with [
    (
      safe? = true
      and
      (
        visible? = true and block? = false)
      and
      (visited_once? = true and block? = false)
    )
    or
    (visible? = false)
    and
    border_wall? = false
  ]
end

to create-map
  ask patches [
    set real-color green + ((random 6) - 2)
    set pcolor black
    set visible? false
  ]
end

to toggle-fow
  ifelse fog-of-war? = true [
    set fog-of-war? false
    ask patches
    [ set pcolor real-color ]
    ask zombies
    [ show-turtle ]
  ] [
    set fog-of-war? true
    ask humans  [
      view human-sight true
    ]
    ask zombies
    [
      let on-visible-patch = patch xcor ycor visible?
      ifelse on-visible-patch
      [ show-turtle ]
      [ hide-turtle ]
    ]
  ]
end

to setup-random-walls
    ask patches [
        if random-float 1.0 < initial-wall-density [
            wall-birth
        ]
    ]
end

to wall-birth  ;; patch procedure
    set block? true
    set pcolor grey
    set real-color grey
end

; Patch report to estimate the total expected cost of the path starting from
; in Start, passing through it, and reaching the #Goal
to-report Total-expected-cost [#Goal]
  report Cost-path + Heuristic #Goal
end

; Patch report to reurtn the heuristic (expected length) from the current patch
; to the #Goal
to-report Heuristic [#Goal]
  report distance #Goal
end

; A* algorithm. Inputs:
;   - #Start     : starting point of the search.
;   - #Goal      : the goal to reach.
;   - #valid-map : set of agents (patches) valid to visit.
; Returns:
;   - If there is a path : list of the agents of the path.
;   - Otherwise          : false


to-report A* [#Start #Goal #valid-map]
  ; clear all the information in the agents
  ask #valid-map
  [
    set father nobody
    set Cost-path 0
    set visited? false
    set active? false
  ]
  ; Active the staring point to begin the searching loop
  ask #Start
  [
    set father self
    set visited? true
    set active? true
  ]
  ; exists? indicates if in some instant of the search there are no options to
  ; continue. In this case, there is no path connecting #Start and #Goal
  let exists? true
  ; The searching loop is executed while we don't reach the #Goal and we think
  ; a path exists
  while [not [visited?] of #Goal and exists?]
  [
    ; We only work on the valid pacthes that are active
    let options #valid-map with [active?]
    ; If any
    ifelse any? options
    [
      ; Take one of the active patches with minimal expected cost
      ask min-one-of options [Total-expected-cost #Goal]
      [
        ; Store its real cost (to reach it) to compute the real cost
        ; of its children
        let Cost-path-father Cost-path
        ; and deactivate it, because its children will be computed right now
        set active? false
        ; Compute its valid neighbors
        let valid-neighbors neighbors4 with [member? self #valid-map]
        ask valid-neighbors
        [
          ; There are 2 types of valid neighbors:
          ;   - Those that have never been visited (therefore, the
          ;       path we are building is the best for them right now)
          ;   - Those that have been visited previously (therefore we
          ;       must check if the path we are building is better or not,
          ;       by comparing its expected length with the one stored in
          ;       the patch)
          ; One trick to work with both type uniformly is to give for the
          ; first case an upper bound big enough to be sure that the new path
          ; will always be smaller.
          let t ifelse-value visited? [ Total-expected-cost #Goal] [2 ^ 20]
          ; If this temporal cost is worse than the new one, we substitute the
          ; information in the patch to store the new one (with the neighbors
          ; of the first case, it will be always the case)
          if t > (Cost-path-father + distance myself + Heuristic #Goal)
          [
            ; The current patch becomes the father of its neighbor in the new path
            set father myself
            set visited? true
            set active? true
            ; and store the real cost in the neighbor from the real cost of its father
            set Cost-path Cost-path-father + distance father
            set Final-Cost precision Cost-path 3
          ]
        ]
      ]
    ]
    ; If there are no more options, there is no path between #Start and #Goal
    [
      set exists? false
    ]
  ]
  ; After the searching loop, if there exists a path
  ifelse exists?
  [
    ; We extract the list of patches in the path, form #Start to #Goal
    ; by jumping back from #Goal to #Start by using the fathers of every patch
    let current #Goal
    set Final-Cost (precision [Cost-path] of #Goal 3)
    let rep (list current)
    While [current != #Start and current != nobody]
    [
      set current [father] of current
      set rep fput current rep
    ]
    report rep
  ]
  [
    ; Otherwise, there is no path, and we return False
    report false
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
302
10
898
607
-1
-1
12.0
1
10
1
1
1
0
1
1
1
-24
24
-24
24
1
1
1
ticks
30.0

BUTTON
49
15
113
48
Setup
setup
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
49
51
112
84
go
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
49
89
183
122
Toggle Fog of War
toggle-fow
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
10
134
182
167
initial-wall-density
initial-wall-density
0
1
0.04
0.01
1
NIL
HORIZONTAL

BUTTON
123
51
202
84
go_once
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

SLIDER
9
173
181
206
human-sight
human-sight
1
10
9.0
1
1
NIL
HORIZONTAL

MONITOR
243
433
297
478
Zombies
count zombies
17
1
11

MONITOR
242
369
294
414
Humans
count humans
17
1
11

SLIDER
9
250
199
283
humans-initial-number
humans-initial-number
0
30
15.0
1
1
NIL
HORIZONTAL

SLIDER
10
288
211
321
zombies-initial-number
zombies-initial-number
0
30
0.0
1
1
NIL
HORIZONTAL

SLIDER
11
328
183
361
safeRadius
safeRadius
5
20
11.0
1
1
NIL
HORIZONTAL

SLIDER
9
212
181
245
zombie-sight
zombie-sight
1
10
2.0
1
1
NIL
HORIZONTAL

PLOT
11
368
234
488
plot 1
time
Mean Distance to Cure
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total_distance"

SWITCH
186
134
276
167
limits?
limits?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

El modelo simula las probabilidades que tienen los humanos de sobrevivir frente a un ataque de zombies y encontrar la cura antes de que todos los humanos sean convertidos en zombies.


## HOW IT WORKS

- Los zombies se mueven de aleatorio hasta que ven a un humano y lo persiguen  para luego convertirlo en zombies.
- Los humanos escapan de los zombies mientras buscan la cura que los hace inmunes a convertirse en zombies y les permite curar a otros humanos.
- Se puede evaluar claramente el progreso de la obtenci??n de la cura en el gr??fico

## HOW TO USE IT

1- Ajustar los par??metros de cantidad de humanos, cantidad de zombies, densidad de muros ,campo de visi??n de los humanos, zombies, existencia de muralla exterior y radio de aparici??n de los humanos.
2- Pulsar el bot??n "Setup" para que se recarguen los par??metros de la simulaci??n y se apliquen las modificaciones de los par??metros realizadas previamente.
3- Pulsar el bot??n "go" para que la simulaci??n se ejecute hasta que todos los humanos se conviertan en zombies o se vuelvan inmunes con la cura.
(NOTA: pulsando el bot??n "go_once" se puede hacer que la simulaci??n avance haciendo un solo tick cada vez que se pulse.


- initial-wall-density: Deslizador que puede tener valores entre 0 y 1, con un aumento de 0.01. Establece la cantidad de paredes que habr?? en el mapa que entorpecer??n los movimientos de los humanos y zombies.
- Human-sight: Deslizazor que puede tener valores entre 1 y 10, con un aumento de 1. Establece el radio del campo de visi??n de los humanos.
- zombie-sight: Deslizazor que puede tener valores entre 1 y 10, con un aumento de 1. Establece el radio del campo de visi??n de los humanos.
- humans-initial-number: Deslizador que puede tener valores entre 0 y 30, con un aumento de 1. Indica el n??mero de humanos que habr?? al inicio de la simulaci??n.
- zombies-initial-number: Deslizador que puede tener valores entre 0 y 30, con un aumento de 1. Indica el n??mero de zombies que habr?? al inicio de la simulaci??n.
- limits? : Interruptor que indica si hay o no borde exterior
- safeRadius : N??mero entre 5 y 10 que indica a qu?? distancia del centro est??n los humanos

## THINGS TO NOTICE

Cuanto mayor sea el n??mero de humanos y zombies m??s lenta ir?? la simulaci??n.
Si la densidad de paredes es demasiado alta, se corre el riesgo de que la alguno de los agentes quede aislado del resto y no pueda completarse la simulaci??n correctamente.

El mapa tiene que estar configurado para tener el origen en el centro, as?? los humanos aparecen en el centro.

Los humanos no escapan directamente de los zombies, cuando hacen path planning consideran peligrosos las casillas en las que hay zombies cerca

## THINGS TO TRY

- Variar la visibilidad de los humanos y zombies, para ver la probabilidad que tienen de sobrevivir en distintos escenarios.

- Variar la densidad de paredes que haya en el mapa afecta a lo r??pido que los humanos encuentran la cura.

- Activar o desactivar el borde

## EXTENDING THE MODEL

- Un posible caso donde los humanos puedan defenderse de los zombies con cierta probabilidad de cuando un zombie ataque a un humano, el zombie muera en lugar de que el el humano se convierta en zombie.

- Ser??a interesante que los humanos y los zombies dejaran rastro para hacer la b??squeda m??s interesane

- Ser??a interesante que los humanos utilizaran algoritmos exploratorios en vez moverse de manera aleatoria

- Mejorar la generaci??n de terreno para crear edificios y casas

## NETLOGO FEATURES

- Usamos patches-ahead para simular raytracing para un modelo m??s realusta de visualizaci??n

- Para evitar que los personajes se muevan en diagonal, usamos neighbors4 en vez de neighbors en el algoritmo A*


## CREDITS AND REFERENCES

- A* Solver: http://www.cs.us.es/~fsancho/?e=131
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
