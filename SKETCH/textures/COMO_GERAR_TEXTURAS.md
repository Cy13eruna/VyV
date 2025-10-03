# Como Gerar as Texturas V&V

## 📋 Especificações das Texturas

### 🌾 Campo
- **Símbolo**: Ponto-e-vírgulas (;) de cabeça para baixo bem juntinhos
- **Caractere alternativo**: ؛ (ponto-e-vírgula árabe)
- **Cor de fundo**: Verde claro (#C8E6C8)
- **Cor do símbolo**: Verde escuro (#507050)

### ⛰️ Montanha  
- **Símbolo**: ⛰ bem juntinhos um dos outros
- **Caractere alternativo**: ▲ (triângulo)
- **Cor de fundo**: Cinza azulado (#B4B4C8)
- **Cor do símbolo**: Cinza escuro (#646478)

### 🌳 Floresta
- **Símbolo**: 🌳 bem juntinhos um dos outros
- **Caractere alternativo**: ♠ (espada/árvore)
- **Cor de fundo**: Verde escuro (#326432)
- **Cor do símbolo**: Verde brilhante (#1EB41E)

### 🌊 Água
- **Símbolo**: 〰 bem juntinhos um dos outros
- **Caractere alternativo**: ~~~ (tildes)
- **Cor de fundo**: Azul água (#5096C8)
- **Cor do símbolo**: Azul escuro (#1E64B4)

## 🛠️ Métodos de Geração

### Método 1: Script Godot (Recomendado)
1. Abra o projeto SKETCH no Godot
2. Execute o script `simple_texture_creator.gd`
3. As texturas serão geradas automaticamente em formato .tres

### Método 2: Script Python
1. Instale PIL: `pip install Pillow`
2. Execute: `python create_textures.py`
3. As texturas serão geradas em formato .png

### Método 3: Manual
1. Use os padrões em `texture_pattern.txt` de cada pasta
2. Crie imagens 256x256 pixels
3. Salve como `texture.png` em cada pasta

## 📁 Estrutura Final
```
textures/
├── field/texture.png (ou .tres)
├── forest/texture.png (ou .tres)  
├── mountain/texture.png (ou .tres)
└── water/texture.png (ou .tres)
```

## ✅ Verificação
Após gerar as texturas, o jogo deve mostrar nos logs:
```
🎨 Loading terrain textures...
✅ Loaded texture: res://textures/field/texture.png
✅ Loaded texture: res://textures/forest/texture.png
✅ Loaded texture: res://textures/mountain/texture.png
✅ Loaded texture: res://textures/water/texture.png
🎨 Texture loading completed. Loaded 4 textures.
```