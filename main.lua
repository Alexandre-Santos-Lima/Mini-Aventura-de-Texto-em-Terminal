--[[
---
Projeto: Mini Aventura de Texto em Terminal
Descrição: Um jogo simples de aventura baseado em texto onde o jogador navega por salas,
           coleta itens e tenta encontrar a saída. Este script demonstra o uso de tabelas
           em Lua para modelar o mundo do jogo, o estado do jogador e um loop de jogo principal
           para processar os comandos do usuário.
Bibliotecas necessárias: Nenhuma. Utiliza apenas as bibliotecas padrão do Lua.
Como executar: lua main.lua
---
--]]

-- ESTADO DO JOGO --

-- O 'player' armazena a localização atual e os itens coletados.
local player = {
    location = "quarto", -- ID da sala inicial
    inventory = {}
}

-- O 'gameMap' é a estrutura central do jogo. Cada chave é o ID de uma sala.
-- Cada sala tem uma descrição, uma lista de saídas possíveis, e os itens que contém.
local gameMap = {
    quarto = {
        description = "Você está em um quarto empoeirado. Há uma cama desarrumada e uma pequena cômoda.\nUma porta ao norte leva para fora.",
        exits = { norte = "corredor" },
        items = { "chave" }
    },
    corredor = {
        description = "Você está em um corredor estreito. Há uma porta a oeste e outra ao sul.",
        exits = { sul = "quarto", oeste = "sala_de_estar" },
        items = {}
    },
    sala_de_estar = {
        description = "Esta é a sala de estar. Um sofá velho está contra a parede.\nUma grande porta de madeira ao norte parece ser a saída, mas está trancada.",
        exits = { leste = "corredor", norte = "jardim" },
        items = { "lanterna" },
        locked = { -- Define saídas trancadas e o item necessário para abri-las
            norte = "chave"
        }
    },
    jardim = {
        description = "Você conseguiu abrir a porta e chegou ao jardim. O ar fresco indica que você está livre!",
        isExit = true -- Marca esta sala como a condição de vitória
    }
}

-- FUNÇÕES AUXILIARES --

--- Verifica se um item está no inventário do jogador.
-- @param itemName (string) O nome do item a ser verificado.
-- @return (boolean) True se o item estiver no inventário, false caso contrário.
function hasItem(itemName)
    for _, item in ipairs(player.inventory) do
        if item == itemName then
            return true
        end
    end
    return false
end

--- Remove um item de uma tabela (como a lista de itens de uma sala).
-- @param tbl (table) A tabela da qual remover o item.
-- @param value (any) O valor a ser removido.
function removeItemFromTable(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            return
        end
    end
end

-- COMANDOS DO JOGADOR --

--- Descreve a sala atual, incluindo saídas e itens.
function commandLook()
    local room = gameMap[player.location]
    print(room.description)
    
    if #room.items > 0 then
        print("Você vê aqui: " .. table.concat(room.items, ", "))
    end

    local exitNames = {}
    for direction, _ in pairs(room.exits) do
        table.insert(exitNames, direction)
    end
    print("Saídas disponíveis: " .. table.concat(exitNames, ", "))
end

--- Move o jogador em uma direção específica.
-- @param direction (string) A direção para se mover (ex: "norte", "sul").
function commandGo(direction)
    local room = gameMap[player.location]
    local nextRoomId = room.exits[direction]

    if not nextRoomId then
        print("Você não pode ir por esse caminho.")
        return
    end

    -- Verifica se a saída está trancada
    if room.locked and room.locked[direction] then
        local requiredItem = room.locked[direction]
        if not hasItem(requiredItem) then
            print("A porta está trancada. Você precisa de um(a) " .. requiredItem .. ".")
            return
        end
        print("Você usou o(a) " .. requiredItem .. " e destrancou a porta.")
    end

    player.location = nextRoomId
    print("Você foi para " .. direction .. ".")
    commandLook()
end

--- Pega um item da sala atual e o adiciona ao inventário.
-- @param itemName (string) O nome do item a ser pego.
function commandTake(itemName)
    local room = gameMap[player.location]
    local itemFound = false
    
    for _, item in ipairs(room.items) do
        if item == itemName then
            itemFound = true
            break
        end
    end

    if itemFound then
        table.insert(player.inventory, itemName)
        removeItemFromTable(room.items, itemName)
        print("Você pegou o(a) " .. itemName .. ".")
    else
        print("Não há '" .. itemName .. "' aqui.")
    end
end

--- Exibe os itens no inventário do jogador.
function commandInventory()
    if #player.inventory == 0 then
        print("Seu inventário está vazio.")
    else
        print("Você está carregando: " .. table.concat(player.inventory, ", "))
    end
end

--- Exibe a lista de comandos disponíveis.
function commandHelp()
    print("Comandos disponíveis:")
    print("  olhar          - Descreve a sala atual.")
    print("  ir [direção]   - Move-se em uma direção (norte, sul, leste, oeste).")
    print("  pegar [item]   - Pega um item da sala.")
    print("  inventario     - Mostra os itens que você está carregando.")
    print("  ajuda          - Mostra esta mensagem de ajuda.")
    print("  sair           - Termina o jogo.")
end

-- Tabela de mapeamento de comandos para funções
local commands = {
    olhar = commandLook,
    ir = commandGo,
    pegar = commandTake,
    inventario = commandInventory,
    ajuda = commandHelp
}

-- LOOP PRINCIPAL DO JOGO --

--- Processa a entrada do usuário, dividindo-a em comando e argumento.
-- @param input (string) A linha de texto inserida pelo usuário.
function parseInput(input)
    -- Converte para minúsculas e divide a entrada em palavras
    local words = {}
    for word in string.gmatch(input:lower(), "[%w]+") do
        table.insert(words, word)
    end
    
    local command = words[1]
    local argument = words[2]
    
    if command == "sair" then
        return false -- Sinaliza para o loop principal terminar
    end

    local func = commands[command]
    if func then
        func(argument)
    else
        print("Não entendi esse comando. Digite 'ajuda' para ver as opções.")
    end

    return true -- Sinaliza para continuar o jogo
end

-- INÍCIO DO JOGO --
print("--- Bem-vindo à Mini Aventura de Texto! ---")
print("Seu objetivo é encontrar a saída. Use comandos como 'ir norte' ou 'pegar chave'.")
print("Digite 'ajuda' para ver todos os comandos.")
print("------------------------------------------------")

commandLook()

while true do
    -- Verifica a condição de vitória
    if gameMap[player.location].isExit then
        print("\nParabéns! Você encontrou a saída e venceu o jogo!")
        break
    end

    io.write("\n> ")
    local input = io.read()
    
    if not parseInput(input) then
        print("Obrigado por jogar!")
        break
    end
end
