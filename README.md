# Introduction

Using gamma simulation platfrom, I created a model to simulate the in-house movements
and generate data collected by motion sensors (PIR sensor).

The groundfloor is created/modified by simple drawing (I use windows painter)
with the wall in black color, PIR sensor position is indicated by red corlor.
The image will be parsed by gamma to auto generate the wall and sensor
positions.

![Ground Floor](https://github.com/tamlt2704/smart_home-pir-simulation/blob/master/images/ground-floor-250-250.png)

PIR sensor has configurale attributes (range, angle, angle range)

Peole in house will move from room to room using A*Star algorithm.

# Demo

![demo](https://github.com/tamlt2704/smart_home-pir-simulation/blob/master/images/GammaDemo.gif)
