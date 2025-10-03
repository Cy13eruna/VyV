#!/usr/bin/env python3
"""
Verificador de bytes nas texturas
Conta exatamente quantos bytes cada textura tem
"""

import re

def count_bytes_in_file(filepath):
    """Conta bytes no PackedByteArray de um arquivo .tres"""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Encontrar PackedByteArray
        match = re.search(r'PackedByteArray\((.*?)\)', content, re.DOTALL)
        if not match:
            return 0, "PackedByteArray não encontrado"
        
        # Contar números separados por vírgula
        numbers_str = match.group(1)
        numbers = [x.strip() for x in numbers_str.split(',') if x.strip()]
        
        return len(numbers), f"Números encontrados: {len(numbers)}"
    
    except Exception as e:
        return 0, f"Erro: {e}"

def main():
    print("🔍 Verificando bytes nas texturas...")
    
    textures = ["field", "forest", "mountain", "water"]
    
    for texture in textures:
        filepath = f"SKETCH/textures/{texture}/texture.tres"
        count, info = count_bytes_in_file(filepath)
        
        status = "✅" if count == 192 else "❌"
        print(f"{status} {texture}: {count} bytes ({info})")
    
    print("\n📊 Resumo:")
    print("- Esperado: 192 bytes (8×8×3)")
    print("- Cada pixel RGB = 3 bytes")
    print("- Total pixels = 64")

if __name__ == "__main__":
    main()