# Unity 3D - Raymarching
Raymarching based 3d renderer in unity using image effect shader
# How does it work?
it works by casting rays from every pixel in the screen
  - get the distance between the closest object and the current point
  - go forward in the direction by the distance
  - repeat until you hit something
