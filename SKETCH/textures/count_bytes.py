#!/usr/bin/env python3
"""
Contador de bytes nas texturas
"""

import re

def count_bytes_in_file(filepath):
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Encontrar PackedByteArray
        match = re.search(r'PackedByteArray\((.*?)\)', content, re.DOTALL)
        if not match:
            return 0
        
        # Contar números
        numbers_str = match.group(1)
        numbers = [x.strip() for x in numbers_str.split(',') if x.strip()]
        
        return len(numbers)
    
    except Exception as e:
        return 0

def main():
    print("Verificando bytes nas texturas...")
    
    textures = ["field", "forest", "mountain", "water"]
    
    for texture in textures:
        filepath = f"SKETCH/textures/{texture}/texture.tres"
        count = count_bytes_in_file(filepath)
        
        status = "OK" if count == 192 else "ERRO"
        print(f"{texture}: {count} bytes - {status}")
    
    print(f"\nEsperado: 192 bytes (8x8x3)")

if __name__ == "__main__":
    main()