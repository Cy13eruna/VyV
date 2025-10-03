# Texturas de Terreno - V&V

Esta pasta contém as texturas para cada tipo de terreno do jogo.

## Estrutura de Pastas:

- **field/**: Texturas para terreno de campo (🌾)
- **forest/**: Texturas para terreno de floresta (🌲)
- **mountain/**: Texturas para terreno de montanha (⛰️)
- **water/**: Texturas para terreno de água (🌊)

## Formatos Suportados:
- PNG (recomendado)
- JPG
- WEBP

## Convenções de Nomenclatura:
- `texture.png` - Textura principal
- `texture_normal.png` - Mapa normal (opcional)
- `texture_roughness.png` - Mapa de rugosidade (opcional)

## Tamanho Recomendado:
- 256x256 pixels para texturas principais
- Potências de 2 (128, 256, 512, 1024)

## Implementação:
As texturas são carregadas automaticamente pelo sistema de renderização e aplicadas aos diamantes de terreno baseado no tipo de terreno de cada aresta.