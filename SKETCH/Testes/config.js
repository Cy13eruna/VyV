// ========================================
// CONFIGURAÇÕES DO RHOMBILLE TILING
// ========================================
// Edite este arquivo para alterar todas as constantes da visualização

const RHOMBILLE_CONFIG = {
    
    // ========================================
    // CORES DOS LOSANGOS
    // ========================================
    colors: {
        field: '#00FF00',  // 1/3 dos losangos - verde claro
        forest: '#007E00',  // 1/6 dos losangos - verde escuro  
        mountain: '#666666',  // 1/6 dos losangos - verde-amarelado
        water: '#00FFFF'   // 1/6 dos losangos - azul-esverdeado
    },
    
    // ========================================
    // PROPORÇÕES DAS CORES
    // ========================================
    proportions: {
        field_fraction: 6/12,  // Proporção da cor 1
        forest_fraction: 2/12,  // Proporção da cor 2
        mountain_fraction: 2/12,  // Proporção da cor 3
        water_fraction: 2/12   // Proporção da cor 4
    },
    
    // ========================================
    // CONFIGURAÇÕES DA GRADE HEXAGONAL
    // ========================================
    grid: {
        hexSize: 50,                    // Tamanho base dos hexágonos
        sizeMultiplier: 1.0,           // Multiplicador do tamanho
        offsetX: 0,                    // Deslocamento horizontal
        offsetY: 0,                    // Deslocamento vertical
        extraColumns: 2,               // Colunas extras para preencher tela
        extraRows: 2                   // Linhas extras para preencher tela
    },
    
    // ========================================
    // CONFIGURAÇÕES VISUAIS
    // ========================================
    visual: {
        backgroundColor: '#FFFFFF',     // Cor de fundo
        showVertexPoints: false,        // Mostrar pontos nos vértices (oculto por enquanto)
        vertexPointColor: '#FFFFFF',    // Cor dos pontos dos vértices
        vertexPointRadius: 4,           // Raio dos pontos dos vértices
        showBorders: false,             // Mostrar bordas dos losangos
        borderColor: '#000000',         // Cor das bordas
        borderWidth: 1,                 // Espessura das bordas
        enableBlur: true,               // Habilitar esfumaçamento
        blurIntensity: 1,               // Intensidade do blur (0-1)
        gradientRadius: 1.5,            // Raio do gradiente (0-1)
        edgeSoftness: 0.4,              // Suavidade das arestas (0-1)
        roundVertices: false,           // Arredondar vértices agudos
        vertexRoundness: 8,             // Raio do arredondamento dos vértices
        vertexBlendMode: 'soft',        // Modo de blend: 'soft', 'hard', 'gradient'
        showTriangleNodes: true,        // Mostrar nódulos triangulares
        triangleNodeColor: '#ffffff',   // Cor dos triângulos
        triangleNodeSize: 16,            // Tamanho dos triângulos
        triangleNodeSpacing: 5          // Espaçamento entre triângulos
    },

    // ========================================
    // CONFIGURAÇÕES DE INTERAÇÃO
    // ========================================
    interaction: {
        clickToRandomize: false,        // Clique para randomizar cores
        autoResize: true,               // Redimensionar automaticamente
        animateChanges: false,          // Animar mudanças (futuro)
        animationDuration: 500          // Duração da animação em ms
    },
    
    // ========================================
    // CONFIGURAÇÕES MATEMÁTICAS
    // ========================================
    math: {
        diamondWidthFormula: 'distance / (2.0 * Math.sqrt(3.0))', // Fórmula da largura do losango
        useCustomFormula: false,        // Usar fórmula customizada
        customWidthMultiplier: 1.0,     // Multiplicador customizado da largura
        precisionDigits: 10             // Precisão dos cálculos
    },
    
    // ========================================
    // CONFIGURAÇÕES DE RANDOMIZAÇÃO
    // ========================================
    randomization: {
        seed: null,                     // Seed para randomização (null = aleatório)
        shuffleAlgorithm: 'fisher-yates', // Algoritmo de embaralhamento
        distributionMethod: 'exact',     // 'exact' ou 'approximate'
        allowColorImbalance: false      // Permitir desbalanceamento de cores
    },
    
    // ========================================
    // CONFIGURAÇÕES DE PERFORMANCE
    // ========================================
    performance: {
        maxDiamonds: 10000,            // Máximo de losangos a desenhar
        useOffscreenCanvas: false,      // Usar canvas offscreen
        enableAntialiasing: true,       // Habilitar antialiasing
        renderQuality: 'high'          // 'low', 'medium', 'high'
    },
    
    // ========================================
    // CONFIGURAÇÕES DE DEBUG
    // ========================================
    debug: {
        showStats: false,               // Mostrar estatísticas na tela
        logColorDistribution: false,    // Log da distribuição de cores
        showGridLines: false,           // Mostrar linhas da grade
        showNodeNumbers: false,         // Mostrar números dos nós
        highlightCenter: false          // Destacar centro da tela
    },
    
    // ========================================
    // CONFIGURAÇÕES DE AUTO-SAVE
    // ========================================
    autoSave: {
        enabled: false,                 // Habilitar auto-save de imagens
        format: 'jpeg',                 // Formato: 'jpeg', 'png', 'webp'
        quality: 0.9,                   // Qualidade JPEG (0-1)
        filename: 'rhombille_auto',     // Nome base do arquivo
        includeTimestamp: true,         // Incluir timestamp no nome
        delayAfterRender: 2000          // Delay em ms antes de salvar
    },
    
    // ========================================
    // PRESETS DE CONFIGURAÇÃO
    // ========================================
    presets: {
        'default': {
            colors: { field: '#00FF00', forest: '#007E00', mountain: '#7E7E55', water: '#557E7E' },
            grid: { hexSize: 50 }
        },
        'ocean': {
            colors: { field: '#0077BE', forest: '#004D7A', mountain: '#7A7A4D', water: '#4D7A7A' },
            grid: { hexSize: 45 }
        },
        'forest': {
            colors: { field: '#228B22', forest: '#006400', mountain: '#556B2F', water: '#2F4F4F' },
            grid: { hexSize: 55 }
        },
        'sunset': {
            colors: { field: '#FF6347', forest: '#FF4500', mountain: '#DAA520', water: '#CD853F' },
            grid: { hexSize: 40 }
        },
        'monochrome': {
            colors: { field: '#CCCCCC', forest: '#999999', mountain: '#666666', water: '#333333' },
            grid: { hexSize: 50 }
        }
    }
};

// ========================================
// FUNÇÕES UTILITÁRIAS DE CONFIGURAÇÃO
// ========================================

// Aplicar preset
function applyPreset(presetName) {
    if (RHOMBILLE_CONFIG.presets[presetName]) {
        const preset = RHOMBILLE_CONFIG.presets[presetName];
        Object.assign(RHOMBILLE_CONFIG.colors, preset.colors);
        Object.assign(RHOMBILLE_CONFIG.grid, preset.grid);
        return true;
    }
    return false;
}

// Validar configuração
function validateConfig() {
    const proportions = RHOMBILLE_CONFIG.proportions;
    const total = proportions.field_fraction + proportions.forest_fraction + 
                  proportions.mountain_fraction + proportions.water_fraction;
    
    if (Math.abs(total - 1.0) > 0.001) {
        console.warn('Aviso: As proporções das cores não somam 1.0. Total:', total);
        return false;
    }
    return true;
}

// Obter array de cores
function getColorsArray() {
    return [
        RHOMBILLE_CONFIG.colors.field,
        RHOMBILLE_CONFIG.colors.forest,
        RHOMBILLE_CONFIG.colors.mountain,
        RHOMBILLE_CONFIG.colors.water
    ];
}

// Obter array de proporções
function getProportionsArray() {
    return [
        RHOMBILLE_CONFIG.proportions.field_fraction,
        RHOMBILLE_CONFIG.proportions.forest_fraction,
        RHOMBILLE_CONFIG.proportions.mountain_fraction,
        RHOMBILLE_CONFIG.proportions.water_fraction
    ];
}

// Calcular tamanho efetivo do hexágono
function getEffectiveHexSize() {
    return RHOMBILLE_CONFIG.grid.hexSize * RHOMBILLE_CONFIG.grid.sizeMultiplier;
}

// Exportar configuração para uso no HTML
if (typeof window !== 'undefined') {
    window.RHOMBILLE_CONFIG = RHOMBILLE_CONFIG;
    window.applyPreset = applyPreset;
    window.validateConfig = validateConfig;
    window.getColorsArray = getColorsArray;
    window.getProportionsArray = getProportionsArray;
    window.getEffectiveHexSize = getEffectiveHexSize;
}

// ========================================
// EXEMPLOS DE USO
// ========================================
/*

// Alterar cores:
RHOMBILLE_CONFIG.colors.field = '#FF0000';

// Alterar proporções:
RHOMBILLE_CONFIG.proportions.field_fraction = 0.5;

// Alterar tamanho:
RHOMBILLE_CONFIG.grid.hexSize = 75;

// Aplicar preset:
applyPreset('ocean');

// Desabilitar pontos nos vértices:
RHOMBILLE_CONFIG.visual.showVertexPoints = false;

// Habilitar bordas:
RHOMBILLE_CONFIG.visual.showBorders = true;

// Alterar esfumaçamento:
RHOMBILLE_CONFIG.visual.enableBlur = true;
RHOMBILLE_CONFIG.visual.blurIntensity = 0.8;

// Alterar arredondamento dos vértices:
RHOMBILLE_CONFIG.visual.roundVertices = true;
RHOMBILLE_CONFIG.visual.vertexRoundness = 12;
RHOMBILLE_CONFIG.visual.vertexBlendMode = 'gradient';

// Alterar nódulos triangulares:
RHOMBILLE_CONFIG.visual.showTriangleNodes = true;
RHOMBILLE_CONFIG.visual.triangleNodeSize = 12;
RHOMBILLE_CONFIG.visual.triangleNodeSpacing = 4;

// Alterar auto-save:
RHOMBILLE_CONFIG.autoSave.enabled = false;
RHOMBILLE_CONFIG.autoSave.format = 'png';
RHOMBILLE_CONFIG.autoSave.quality = 1.0;

*/