# V&V - Documentação do Sistema

## Visão Geral
Sistema de jogo de estratégia hexagonal com fog of war, turnos por times e movimento tático.

## Estrutura do Projeto

### Arquivos Principais
- `scenes/star_click_demo.tscn` - Cena principal do jogo
- `scripts/star_click_demo.gd` - Script principal e coordenador do sistema
- `scripts/hex_grid.gd` - Sistema de grid hexagonal
- `scripts/game_manager.gd` - Gerenciador de entidades e regras de jogo
- `scripts/fog_of_war.gd` - Sistema de fog of war
- `scripts/unit.gd` - Entidade unidade
- `scripts/domain.gd` - Entidade domínio
- `scripts/star_mapper.gd` - Mapeamento de estrelas

### Sistemas Implementados

#### 1. Sistema de Grid Hexagonal
- Grid dinâmico baseado na quantidade de domínios (2-6)
- Renderização otimizada com cache
- Geometria hexagonal precisa

#### 2. Sistema de Fog of War
- Visibilidade por times
- Ocultamento de unidades/domínios adversários
- Preferências simplificadas:
  - Domínios revelam 6 estrelas + 12 losangos
  - Atualização imediata ao mover unidades
  - Adversários ocultos quando fora da área revelada

#### 3. Sistema de Turnos
- Turnos por cores/times (2-6 jogadores)
- Botão NEXT TURN flutuante
- Cores dinâmicas baseadas nos domínios
- Reset automático de ações das unidades

#### 4. Sistema de Movimento Tático
- Movimento restrito por times
- Highlights visuais para movimento válido
- Verificação de terreno e ocupação
- Ações limitadas por turno

#### 5. Sistema de Spawn Equilibrado
- Regras estratégicas por quantidade de domínios:
  - 2 domínios: sem regras específicas
  - 3 domínios: nunca em pontas adjacentes
  - 4 domínios: cantos opostos vazios
  - 5-6 domínios: sem regras específicas

## Controles do Jogo

### Controles de Mouse
- **Clique esquerdo**: Selecionar unidade / Mover unidade
- **Scroll up/down**: Sistema de zoom em duas etapas (centralizar + zoom)

### Controles de Teclado
- **F**: Toggle Fog of War
- **G**: Toggle modo debug da Fog of War
- **V**: Mostrar informações de visibilidade

### Interface
- **Botão NEXT TURN**: Avançar turno (canto superior direito)

## Execução

### Comando Básico
```bash
"C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" --path SKETCH scenes\star_click_demo.tscn --domain-count=3
```

### Parâmetros
- `--domain-count=X`: Quantidade de domínios (2-6, padrão: 6)

## Arquitetura

### Fluxo Principal
1. **Inicialização**: Configuração do grid baseado na quantidade de domínios
2. **Mapeamento**: Criação do StarMapper para precisão de posicionamento
3. **Spawn**: Posicionamento estratégico de domínios e unidades
4. **Jogo**: Sistema de turnos com movimento tático e fog of war

### Padrões de Design
- **Separação de responsabilidades**: Cada script tem função específica
- **Sistema de sinais**: Comunicação entre componentes
- **Limpeza de recursos**: Sistema robusto para evitar vazamentos
- **Cache otimizado**: Performance em grids grandes

## Melhorias Implementadas

### V2.1 - Sistema Completo
- ✅ Fog of War com preferências do usuário
- ✅ Sistema de turnos por times
- ✅ Movimento tático com restrições
- ✅ Spawn equilibrado com regras estratégicas
- ✅ Limpeza robusta de recursos
- ✅ Interface responsiva

### Correções de Bugs
- ✅ Erros de parsing corrigidos
- ✅ Vazamentos de memória minimizados
- ✅ Compatibilidade com Godot 4
- ✅ Sistema de sinais otimizado

## Status Atual
**Sistema completamente funcional e pronto para uso!**

- ✅ Todos os sistemas operacionais
- ✅ Interface responsiva
- ✅ Performance otimizada
- ✅ Código limpo e organizado