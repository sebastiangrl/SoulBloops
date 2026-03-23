# Figuras Soul Bloops — listado para diseño

Cada pieza es un conjunto de celdas `{x, y}` en una cuadrícula local; `(0,0)` es la esquina superior izquierda del *bounding box* (tras normalizar en `Piece`).

## Constantes (código)

| Concepto | Valor | Fuente |
|----------|-------|--------|
| **Celda en tablero** | **72 × 72 px** | `Grid.CELL_SIZE` |
| **Inset por celda** | **2.5 px** por lado | `Grid.CELL_INSET` → bloque dibujado ≈ **67 × 67 px** dentro de cada celda de 72 |
| **Escala carril** | **0.52** | `Piece.TRAY_SCALE` |
| **Lado celda en carril** | **72 × 0.52 ≈ 37,44 px** | preview del carril |

**BBox tablero (px)** = `cols × 72` × `filas × 72`.  
**BBox carril (px)** ≈ mismo × **0,52**.

---

## Catálogo completo (`ShapeCatalog.POOL`)

`POOL[i]` → etiqueta **S(i+1)** (S01 = índice 0). ASCII: `#` = celda, `.` = vacío.

| ID | i | Celdas | BBox | Forma |
|----|---|--------|------|--------|
| **S01** | 0 | 1 | 1×1 | `#` |
| **S02** | 1 | 2 | 2×1 | `##` |
| **S03** | 2 | 2 | 1×2 | `#` / `#` |
| **S04** | 3 | 3 | 3×1 | `###` |
| **S05** | 4 | 3 | 1×3 | columna de 3 |
| **S06** | 5 | 4 | 1×4 | columna de 4 |
| **S07** | 6 | 5 | 1×5 | columna de 5 |
| **S08** | 7 | 6 | 1×6 | columna de 6 |
| **S09** | 8 | 3 | 2×2 | `#.` / `##` |
| **S10** | 9 | 3 | 2×2 | `.#` / `##` |
| **S11** | 10 | 4 | 3×2 | `.#.` / `###` |
| **S12** | 11 | 4 | 4×1 | `####` |
| **S13** | 12 | 4 | 2×2 | `##` / `##` |
| **S14** | 13 | 4 | 3×2 | `###` / `#..` |
| **S15** | 14 | 4 | 3×2 | `..#` / `###` |
| **S16** | 15 | 4 | 3×2 | `.##` / `##.` |
| **S17** | 16 | 4 | 3×2 | `##.` / `.##` |
| **S18** | 17 | 4 | 3×2 | `#..` / `###` |
| **S19** | 18 | 5 | 5×1 | `#####` |
| **S20** | 19 | 5 | 3×3 | `#../#../.##` (tres filas) |
| **S21** | 20 | 5 | 3×3 | `.#.` / `###` / `.#.` |
| **S22** | 21 | 6 | **2×3** | `##` / `##` / `##` |
| **S23** | 22 | 9 | **3×3** | bloque 3×3 lleno |
| **S24** | 23 | 4 | 2×3 | `.#` / `##` / `.#` |
| **S25** | 24 | 4 | 2×3 | `#.` / `##` / `#.` |
| **S26** | 25 | 4 | 2×3 | `#.` / `##` / `.#` |
| **S27** | 26 | 4 | 2×3 | `.#` / `##` / `#.` |

---

## Medidas en píxeles (tablero, 72 px/celda)

| BBox | Ancho px | Alto px |
|------|----------|---------|
| 1×1 | 72 | 72 |
| 2×1 | 144 | 72 |
| 1×2 | 72 | 144 |
| 3×1 | 216 | 72 |
| 1×3 | 72 | 216 |
| 1×4 | 72 | 288 |
| 1×5 | 72 | 360 |
| 1×6 | 72 | 432 |
| 2×2 | 144 | 144 |
| 3×2 | 216 | 144 |
| 4×1 | 288 | 72 |
| 5×1 | 360 | 72 |
| 3×3 | 216 | 216 |
| **2×3 (S22)** | **144** | **216** |
| **3×3 lleno (S23)** | **216** | **216** |
| **2×3 (S24–S27)** | **144** | **216** |

## S22 y S23 (bloques grandes)

| ID | Nombre | Celdas | BBox diseño | Tablero px | Carril ≈ px |
|----|--------|--------|-------------|------------|-------------|
| **S22** | Rectángulo 2×3 | 6 | 2 cols × 3 filas | 144 × 216 | 75 × 112 |
| **S23** | Cuadrado 3×3 | 9 | 3 × 3 | 216 × 216 | 112 × 112 |

---

## Notas de arte

- Cada **celda ocupada** puede mostrar un PNG **bloop**: `Bloop {Color} - {n}.png` (colores: Blue, Green, Orange, Pink, Purple, Red; `n` = personaje 1,2,3…). Ver `res/img/bloops/README.md`. **Toda la pieza usa un solo color**, pero **cada cuadrado un `n` distinto** (personajes distintos). En tablero inicial aplica la misma lógica por forma colocada.
- Arte recomendado **72×72 px**; el motor **escala** al hueco interior de celda.
- Si **no** hay PNG cargados, se usa el **modo clásico**: cuadrados teñidos (`fillId` 1…240).
- `fillId` empaquetado: **`10000 + n×100 + índiceColor`** (1=Blue … 6=Red), `BloopSprites.packCell`.
- El tablero es **8×8** celdas; S23 (3×3), S22 (2×3) y columnas hasta **1×6** (S08) siguen siendo colocables con margen.

*Debe mantenerse alineado con `src/game/ShapeCatalog.hx`.*

### Capas del tablero (`Grid`)

- `Grid` extiende **`h2d.Layers`**: capa **0** = relleno + líneas neón animadas; capa **1** = `TileGroup` de celdas (vacías, bloques teñidos o sprites bloop). Así las líneas no se mezclan en batch con los bloques.
- Las líneas son **neón** (mezcla blanco ↔ color en cada tramo, tono que deriva lentamente), con `Add` sobre el fondo oscuro.
