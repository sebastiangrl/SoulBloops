# Sprites Bloop

Los archivos deben llamarse **exactamente** así (mismo texto, espacios y guiones):

```text
Bloop Blue - 1.png
Bloop Green - 2.png
Bloop Orange - 3.png
…
```

## Formato del nombre

`Bloop` + espacio + **color** + espacio + `-` + espacio + **número** + `.png`

## Colores (solo estos seis)

En este orden fijo (así los mapea el juego al índice 1…6):

1. Blue  
2. Green  
3. Orange  
4. Pink  
5. Purple  
6. Red  

Ejemplos válidos: `Bloop Blue - 1.png`, `Bloop Red - 1.png`, `Bloop Purple - 3.png`.

## Número (variante de personaje)

Es el **diseño** del bloop: `1`, `2`, `3`, … Cuando añadas `4`, `5`, `6`, solo crea los PNG con ese número.  
El código intenta cargar variantes **1 … MAX_BLOOP** (ver `BloopSprites.MAX_BLOOP` en `src/game/BloopSprites.hx`); súbelo si necesitas más.

## Cómo se usan en cada figura

Cada **pieza del carril** elige **un solo color** y, para cada cuadrado de la forma, un **personaje distinto** (números distintos, todos con ese color).  
Ejemplo: un tetramino en Blue puede usar `Bloop Blue - 1`, `- 2`, `- 3` y `- 4` a la vez.  
Hace falta tener **al menos tantas variantes cargadas en ese color como celdas tenga la figura** (p. ej. la pieza de 9 celdas necesita 9 PNG distintos en el mismo color, tipo `Bloop Pink - 1` … `- 9`). Si no hay suficientes variantes para ningún color, esa pieza vuelve al modo de cuadrados de color sólido.

Por **cada color**, el juego reparte los números `1…N` en **rondas** (baraja, va sacando sin repetir hasta agotar y vuelve a barajar), para que con pocas variantes no se vea siempre el mismo personaje en piezas seguidas.

## Tamaño

Recomendado **72×72 px**; el juego escala al hueco interior de cada celda del tablero.
