En la marea
===========

En la Marea es el sitio y editorial de [Camila Pérez Schunk](http://enlamarea.net).


Requisitos para trabajar en este repositorio
--------------------------------------------

* Ruby
* TeXLive
* Pandoc (>= 1.10)
* Git Flow

Instalación
-----------

Luego de clonar, correr `bundle install`.

Compilar el sitio
-----------------

  make


Tapas
-----

Se crean dos tapas, una en A5 que incluye tapa y contratapa y otra en A6
que es sólo la tapa.  Tienen que llevar el nombre del articulo.  La tapa
completa lleva el prefijo "cover\_" y la simple "single\_" para que
jekyll los tome después.  El slider es una A7 apaisada, con la barra
blanca a 20mm del margen superior.

  make tapas
