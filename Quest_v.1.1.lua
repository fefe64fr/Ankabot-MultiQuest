AI_FILE = "ModSpellPriority.lua"

local currentDirectory = "E:\\Dofus botting\\Scripts\\Trajets\\AnkaBot\\Ankabot-MultiQuest\\"

local QUEST = dofile(currentDirectory.."QuestInfo.lua")

-- Quest var

local scriptInit, isDialog = false, false
local questSelected, stepSelected, stepInfoDisplayed = false, false, false
local roadLoaded = false

local currentQuest, currentStep

local packetDialog = {}

local QuestList = {}
QuestList.activeQuests = {}
QuestList.finishedQuestsIds = {}
QuestList.finishedQuestsCounts = {}
QuestList.reinitDoneQuestsIds = {}

local GID_STUFF = { 
    ["Coiffe"] = { gid = 2474, lvl = 12, pos = 6 },
    ["Cape"] = { gid = 2473, lvl = 9, pos = 7 },
    ["Amulette"] = { gid = 2478, lvl = 7, pos = 0 },
    ["Anneau n°1"] = { gid = 2475, lvl = 8, pos = 2 },
    ["Anneau n°2"] = { gid = 19622, lvl = 1, pos = 4 },
    ["Ceinture"] = { gid = 2477, lvl = 10, pos = 3 },
    ["Bottes"] = { gid = 2476, lvl = 11, pos = 5 }
}

-- Fight func var 

local goFight, fightConf, fighFuncInit = false, false, false

local minPercentLifeBeforeAttack = 80

local minMonster = 1
local maxMonster = 8

local MONSTERS_CONF = {}
local SORTED_MONSTERS_GROUP, GROUP_TO_ATTACK = {}, {}

local packetSended = false
local selectedGroupToAttack, fightStarted, triedAttack, inCellToLaunchFight = false, false, false, false
local mapCheck, goNextMap, needRegen = false, false, false

local mapIdChecked, timeToWait = 0, 0

-- Main

function move()
    if not scriptInit then
        Print("Initialisation du script", "script")
        Initialization()
        scriptInit = true
        Print("Script initialisé", "script")
    end

    AutoStats()
    AutoStuff()

    QuestManager() 
end

function stopped()
    Print("Arrêt du script, reset des variables", "script")
    ClearScript()
end

-- Stuff et stats

function AutoStats()
    local statsPoint = character:statsPoint()
    if statsPoint > 0 then
        if character:getCostAgility() < 2 then
            character:upgradeAgility(statsPoint)
        else
            character:upgradeVitality(statsPoint)
        end
    end
end

function AutoStuff()
    for k, v in pairs(GID_STUFF) do
        if not IsItEquipped(v.gid) and inventory:itemCount(v.gid) > 0 and character:level() >= v.lvl then
            if not inventory:equipItem(v.gid, v.pos) then
                Print("Impossible d'équiper l'item "..inventory:itemNameId(v.gid), "AutoStuff", "error")
            end
        end
    end
end

function IsItEquipped(gid)
    local inventoryContent = inventory:inventoryContent()
    
    for _, v in pairs(inventoryContent) do
        if v.objecttGID == gid and v.position ~= 63 then
            return true
        end
    end

    return false
end

function GetAllUnequippedStuffInfo()
    local inventoryContent = inventory:inventoryContent()
    local ret = {}

    for _, v in pairs(inventoryContent) do
        if v.position == 63 then
            table.insert(ret, v)
        end
    end
    return ret
end

-- Init et clear

function Initialization()
    ClearScript()
    LoadHistoricalQuestList()
end

function LoadHistoricalQuestList()
    local packet = developer:historicalMessage("QuestListMessage")
    QuestList.activeQuests = packet[1].activeQuests
    QuestList.finishedQuestsIds = packet[1].finishedQuestsIds
    QuestList.finishedQuestsCounts = packet[1].finishedQuestsCounts
    QuestList.reinitDoneQuestsIds = packet[1].reinitDoneQuestsIds
end

function ClearScript()
    scriptInit = false
    developer:unRegisterMessage("QuestListMessage")
    developer:unRegisterMessage("QuestStepInfoMessage")
    global:deleteAllMemory()
end

-- Gestion quête

function QuestManager()

    PacketRegister("quest")

    if not questSelected then -- Séléction de la quête
        currentQuest = SelectQuest()
        if currentQuest == nil then
            Print("Aucune quête séléctionner !", "QuestManager", "error")
        end
        questSelected = true
    end

    if questSelected and not stepSelected then
        PacketSender("QuestStepInfoRequestMessage", function(msg) msg.questId = currentQuest.questId return msg end)
        developer:suspendScriptUntil("QuestStepInfoMessage", 1000, true)
    end

    if not stepSelected then -- Séléction de l'étape de quête
        ClearFightFunc()
        if CheckIfQuestActive(currentQuest.questId) then
            currentStep = SelectStep(GetCurrentStep())
            stepSelected = true       
        else
            currentStep = currentQuest.stepInfo.START
            stepSelected = true
        end
    end

    if stepSelected and currentStep != nil then -- Éxécution de l'étape
        if not stepInfoDisplayed then
            Print(currentStep.displayInfo, "étape")
            stepInfoDisplayed = true
        end
        currentStep.EXECUTE()
    else 
        Print("Aucune étape séléctionner", "QuestManager", "error")
        ClearScript()
    end
end

function SelectQuest()
    for kQuestName, vQuest in pairs(QUEST) do
        if not CheckIfQuestFinish(vQuest.questId) then
            local canSelect = true

            if vQuest.requiredFinishedQuest ~= nil then -- Verifie si une quête est requis, si oui verifie si elle terminée
                for _, reqId in pairs(vQuest.requiredFinishedQuest) do
                    if not CheckIfQuestFinish(reqId) then
                        canSelect = false
                    end
                end
            end

            if vQuest.minLevel ~= nil then
                if character:level() < vQuest.minLevel then
                    canSelect = false
                end
            end

            if canSelect then
                Print("Quête "..kQuestName.." séléctionner ", "quête")
                vQuest.name = kQuestName
                return vQuest
            end
        else
            Print("La quête "..kQuestName.. " est fini", "quête")
        end
    end
end

function SelectStep(stepId)
    if stepId == nil then
        if currentQuest.stepInfo.START ~= nil then
            return currentQuest.stepInfo.START
        else
            Print("Pas de step START sur la quête "..currentQuest.name, "SelectStep", "error")
        end
    else
        for kStepId, vStep in pairs(currentQuest.stepInfo) do
            if tostring(kStepId) == tostring(stepId) then
                return vStep
            end
        end
    end
end

function GetCurrentStep()
    if QuestList.activeQuests ~= nil then
        for _, vQuest in pairs(QuestList.activeQuests) do
            if vQuest.questId == currentQuest.questId then
                if vQuest.objecttives ~= nil then
                    for _, vObjecttives in pairs(vQuest.objecttives) do
                        if vObjecttives.objecttiveStatus then
                            --Print(v2.objecttiveId)
                            return vObjecttives.objecttiveId
                        end
                    end
                end
            end
        end
    end
    return nil
end

function UpdateStepQuest(packet) -- Retour Callback QuestStepInfo
    if packet.infos.questId ~= nil then
        if not CheckIfQuestActive(packet.infos.questId) then
            AddQuestActive(tonumber(packet.infos.questId))
        end

        for _, v in pairs(QuestList.activeQuests) do
            if v.questId == packet.infos.questId then
                --Print("Objectif de quête mis a jour", "dev")
                v.objecttives = packet.infos.objecttives
                break
            end
        end
    end
end

function CheckIfQuestActive(questId)

    if QuestList.activeQuests ~= nil then
        for _, v in pairs(QuestList.activeQuests) do
            if v.questId == questId then
                return true
            end
        end
    end
    return false
end

function CheckIfQuestFinish(questId)
    if QuestList.finishedQuestsIds ~= nil then
        for _, v in pairs(QuestList.finishedQuestsIds) do
            if v == questId then
                return true
            end
        end
    end
    return false
end

function EndStep(typeMove, dir)
    Print("Terminée -- "..currentStep.displayInfo, "étape")
    ResetQuestVar()

    if typeMove == nil then
        return move()
    elseif string.lower(typeMove) == "door" then
        map:door(dir)
    elseif string.lower(typeMove) == "npcreply" then
        NpcReply(dir)
    end

    return move()
end

function EndQuest(typeMove, dir)
    Print("Terminée -- "..currentQuest.name, "Quête")
    table.insert(QuestList.finishedQuestsIds, currentQuest.questId)

    DeleteActiveQuest(currentQuest.questId)

    questSelected = false
    currentQuest = nil
    ResetQuestVar()

    if typeMove == nil then
        return move()
    elseif string.lower(typeMove) == "door" then
        map:door(dir)
    elseif string.lower(typeMove) == "npcreply" then
        NpcReply(dir)
    end

    return move()
end

function AddQuestActive(questId)
    local vQuest = {}
    vQuest.questId = questId

    table.insert(QuestList.activeQuests, vQuest)
end

function DeleteActiveQuest(questId)
    for i = #QuestList.activeQuests, 0, -1 do
        if QuestList.activeQuests[i].questId == questId then
            local name
            if QuestList.activeQuests[i].name ~= nil then
                name = QuestList.activeQuests[i].name
            end
            table.remove(QuestList.activeQuests, i)
            return name
        end
    end

end

function ResetQuestVar()
    stepInfoDisplayed = false
    stepSelected = false
    roadLoaded = false
    ClearFightFunc()
end

function MoveNext()
    --Print("Try moveNext")
    if roadLoaded and stepSelected then
        map:moveRoadNext()
    else
        return move()
    end
end

-- CallBack packet

function PacketRegister(type)
    local packetNameTbl = {
        ["Quest"] = { 
            ["QuestListMessage"] = CB_QuestListMessage,
            ["QuestStepInfoMessage"] = CB_QuestStepInfo,
            ["QuestObjectiveValidatedMessage"] = CB_ObjectiveValidated 
        },
        ["Fight"] = {
            ["GameFightStartingMessage"] = CB_GameFightStartingMessage,
            ["GameFightEndMessage"] = CB_GameFightEndMessage
        }
    }

    if string.lower(type) == "quest" then
        for message, callBack in pairs(packetNameTbl.Quest) do
            if not developer:isMessageRegistred(message) then
                Print("Packet "..message.." enregistrée", "packet")
                developer:registerMessage(message, callBack)
            end
        end
    elseif string.lower(type) == "fight" then
        for message, callBack in pairs(packetNameTbl.Fight) do
            if not developer:isMessageRegistred(message) then
                Print("Packet "..message.." enregistrée", "packet")
                developer:registerMessage(message, callBack)
            end
        end
    end
end

function CB_QuestStepInfo(packet)
    --Print("Réception du packet QuestStepInfoMessage", "packet")
    UpdateStepQuest(packet)
end

function CB_QuestListMessage(packet)
    --Print("Réception du packet QuestListMessage", "packet")
    QuestList.activeQuests = packet.activeQuests
    QuestList.finishedQuestsIds = packet.finishedQuestsIds
    QuestList.finishedQuestsCounts = packet.finishedQuestsCounts
    QuestList.reinitDoneQuestsIds = packet.reinitDoneQuestsIds
end

function CB_NpcDialogQuestionMessage(packet)
    developer:unRegisterMessage("NpcDialogQuestionMessage")
    packetDialog = packet
end

function CB_ObjectiveValidated()
    --Print("Objective validated", "objective")
    ResetQuestVar()
end

function CB_LeaveDialog()
    developer:unRegisterMessage("LeaveDialogMessage")
    isDialog = false
end

-- Utilitaire

function Print(msg, header, msgType)
    local prefabStr = ""

    if header ~= nil then
        prefabStr = "["..string.upper(header).."] "..msg
    else
        prefabStr = msg
    end

    if msgType == nil then
        global:printSuccess(prefabStr)
    elseif string.lower(msgType) == "normal" then
        global:printMessage(prefabStr)
    elseif string.lower(msgType) == "error" then
        global:printError("[ERROR]["..header.."] "..msg)
    end
end

function NpcDialogRequest(npcId)
    developer:registerMessage("LeaveDialogMessage", CB_LeaveDialog)
    developer:registerMessage("NpcDialogQuestionMessage", CB_NpcDialogQuestionMessage)
    PacketSender("NpcGenericActionRequestMessage", function(msg)
        msg.npcId = npcId
        msg.npcActionId = 3
        msg.npcMapId = map:currentMapId()
        return msg 
    end)
    isDialog = true
    developer:suspendScriptUntil("NpcDialogQuestionMessage", 1000, true)
end

function ReplyUntilLeave(tblId)
    while isDialog do
        NpcReply(nil, nil, tblId)
    end
end

function NpcReply(id, speed, tblId)
    if tblId ~= nil then

        for _, v in pairs(packetDialog.visibleReplies) do
            for _, c in pairs(tblId) do
                if v == c then
                    id = v
                    break
                end
            end
        end
    end

    developer:registerMessage("NpcDialogQuestionMessage", CB_NpcDialogQuestionMessage)

    local min, max

    if speed == nil then
        min = 492
        max = 728
    elseif string.lower(speed) == "slow" then
        min = 621
        max = 1149
    elseif string.lower(speed) == "fast" then
        min = 189
        max = 436
    end

    global:delay(GetRandomNumber(min, max))
    --Print(id)
    if id ~= nil then
        npc:reply(id)
    else       
        Print("npcReply id = nil", "npc", "error")
        for _, v in pairs(QUEST) do
            if currentQuest == v then
                v.minLevel = character:level() + 1
                global:leaveDialog()
                questSelected = false
                ResetQuestVar()
                return move()
            end
        end
    end
    developer:suspendScriptUntil("NpcDialogQuestionMessage", 500, false)
end

function GetRandomNumber(min, max)
    local rand = json.parse(developer:getRequest("http://www.randomnumberapi.com/api/v1.0/random?min="..tostring(min).."&max="..tostring(max).."&count=1"))  
    return rand[1]
end

function LoadRoadIfNotInMap(compareMap)
    if map:currentMapId() ~= compareMap and not roadLoaded then
        if not map:loadRoadToMapId(compareMap) then
            Print("Impossible de charger un chemin jusqu'a "..currentStep.displayInfo, currentQuest.name, "error")
        else
            roadLoaded = true
        end
    elseif map:currentMapId() == compareMap then
        roadLoaded = false
    end
end

function RemoveTableByValue(tbl, value)
    local i = 1

    for _, v in pairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            break
        end
        i = i + 1
    end
end

-- Fight Func

function InitFightFunc()
    ResetFightFuncVar()
end

function Get_FightConf()
    return fightConf
end

function Set_FightConf(set)
    fightConf = set
end

-- Gestion Config monsters

function AddMonsterConf(idMonster, min, max)
    local ins = { idMonster = idMonster , min = min, max = max }
    table.insert(MONSTERS_CONF, ins)
    Print(idMonster.." ajoutée a monsterConf", "Conf")
end

function DelMonsterConf(idMonster)
    for i = #MONSTERS_CONF, 1, -1 do
        if MONSTERS_CONF[i].idMonster == idMonster then
            Print(idMonster.." supprimé de monsterConf", 'Conf')
            table.remove(MONSTERS_CONF, i)
            break
        end
    end
end

function EditMonsterConf(idMonster, min, max)
    for _, v in pairs(MONSTERS_CONF) do
        if v.idMonster == idMonster then
            if min ~= nil then
                v.min = min
            end
            if max ~= nil then
                v.max = max
            end
            Print(idMonster.." modifié dans monsterConf", "Conf")
            break
        end
    end
end

function ClearMonsterConf()
    MONSTERS_CONF = {}
    Print("monsterConf réinitialiser", "Conf")
end

-- Gestion Fight

function Fight()
    PacketRegister("fight")

    if not fighFuncInit then
        developer:registerMessage("GameFightStartingMessage", CB_GameFightStartingMessage)
        developer:registerMessage("GameFightEndMessage", CB_GameFightEndMessage)
        fighFuncInit = true
    end

    if needRegen then
        global:delay(timeToWait)
        needRegen = false
        ResetFightFuncVar()
        return move()
    elseif selectedGroupToAttack then

        if map:currentCell() ~= GROUP_TO_ATTACK.cellId then
            Print("Déplacement vers la cellule du lancement de combat", "fight")
            inCellToLaunchFight = true
            map:moveToCell(GROUP_TO_ATTACK.cellId)
        end

        TryAttack(GROUP_TO_ATTACK.contextualId)
    elseif not goNextMap then
        FightManager()
    else
        ResetFightFuncVar()
    end
end

function FightManager(packet)
    Print("FightManager", "debug")

    if mapIdChecked ~= map:currentMapId() then
        ResetFightFuncVar()
    end

    if not packetSended then
        developer:registerMessage("MapComplementaryInformationsDataMessage", CB_MapDataMessage)
        packetSended = true
        mapIdChecked = map:currentMapId()
        PacketSender("MapInformationsRequestMessage", function(msg)
            msg.mapId = map:currentMapId()
            return msg 
        end)
        developer:suspendScriptUntil("MapComplementaryInformationsDataMessage", 1000, true)
    end

    if packet ~= nil and not mapCheck and packetSended then
        developer:unRegisterMessage("MapComplementaryInformationsDataMessage")
        SORTED_MONSTERS_GROUP = SortGroupMonsterToAttack(GetSortGroupMonster(packet))
        mapCheck = true
    end

    if mapCheck and not isMoving then

        if not selectedGroupToAttack then
            Print("Nombre de combat possible sur la carte = "..#SORTED_MONSTERS_GROUP, "info")
        end

        if #SORTED_MONSTERS_GROUP == 0 then
            goNextMap = true
        else
            if not selectedGroupToAttack then
                GROUP_TO_ATTACK = SelectGroupToAttack()
                selectedGroupToAttack = true
            end
    
            if selectedGroupToAttack and not fightStarted and not triedAttack then
                if character:lifePointsP() < minPercentLifeBeforeAttack then
                    local waitDelay = character:maxLifePoints() - character:lifePoints()
                    Print("Attente de "..waitDelay.." secondes pour la régéneration de point de vie", "info")
                    timeToWait = waitDelay * 1000
                    needRegen = true
                end
            elseif triedAttack then
                Print("Le bot n'a pas réussi a lancer le fight")
            elseif fightStarted then
                Print("Le fight et lancée")
            end
        end
    end

end 

function SelectGroupToAttack()
    local grp

    for _, v in pairs(SORTED_MONSTERS_GROUP) do
        grp = v
        RemoveTableByValue(SORTED_MONSTERS_GROUP, v)
        break
    end

    return grp
end

function MeetConditionsToAttack(tblIdMonsters)
    local verified = {}

    if #tblIdMonsters < minMonster or #tblIdMonsters > maxMonster then
        return false
    end

    for _, conf in pairs(MONSTERS_CONF) do
        local count = CountMonster(tblIdMonsters, conf.idMonster)
        --Print("Count = "..count.." id = "..conf.idMonster.." min = "..conf.min.." max = "..conf.max)
        if (count >= conf.min) and (count <= conf.max) then
            --Print("True")
            table.insert(verified, true)
        else
            --Print("False")
            table.insert(verified, false)
        end
    end

    for _, v in pairs(verified) do
        if v == false then
            return false
        end
    end

    return true
end

function SortGroupMonsterToAttack(groupMonsters)
    local ret = {}
    --Print("Lenght "..#groupMonsters)
    for i, v in pairs(groupMonsters) do
        --Print("Table n°"..i.. " ContextualId = "..v.contextualId.." cellId = "..v.cellId, "iTable")       
        if MeetConditionsToAttack(v.idMonster) then
            --Print("Added", i)
            table.insert(ret, v)
        end
    end
    return ret
end

function TryAttack(ctxId)
    Print("Tentative attack", 'fight')

    global:delay(250)

    inCellToLaunchFight = false
    triedAttack = true

    PacketSender("GameRolePlayAttackMonsterRequestMessage", function(msg)
        msg.monsterGroupId = ctxId
        return msg
    end)

    developer:suspendScriptUntil("GameFightStartingMessage", 5000, true)
    if not fightStarted then
        ResetFightFuncVar()
    end
end

-- RoadZone

function RoadZone(tblMapId)
    if tblMapId.mapIdToGo == nil then
        tblMapId.mapIdToGo = 0
    end

    local condition = function()
        return map:currentMapId() == tblMapId.mapIdToGo or tblMapId.mapIdToGo == 0
    end

    if condition() then
        --Print("Get next rand roadMapId")
        while condition() do
            local rand = GetRandomNumber(1, #tblMapId)
            --Print(tblMapId.mapIdToGo)
            tblMapId.mapIdToGo = tblMapId[rand]
        end
        --Print("Next roadMapId = "..tblMapId.mapIdToGo)
        if not map:loadMove(tblMapId.mapIdToGo) then
            Print("Impossible de charger le trajet jusqu'a la mapId : "..tblMapId.mapIdToGo, "RoadZone", "error")
        end
    end

    map:moveRoadNext()
end

-- Tri packet

function GetSortGroupMonster(pActors)
    local staticInfo = GetGroupMonsterStaticInformations(GetGameRolePlayGroupMonsterInformation(pActors))
    local tbl = {}

    for i, tblGroupMonster in pairs(staticInfo) do
        local groupMonster = {}
        groupMonster.idMonster = {}
        groupMonster.cellId = tblGroupMonster.cellId
        groupMonster.contextualId = tblGroupMonster.contextualId

        for _, tblMonster in pairs(tblGroupMonster.Infos) do
            --Print(tblMonster.mainCreatureLightInfos.genericId.." insert", i)
            table.insert(groupMonster.idMonster, tblMonster.mainCreatureLightInfos.genericId)

            --for ef = 1, #tblMonster.underlings do
                --Print(tblMonster.underlings[ef].genericId, i)
            --end
            --Print("Sortie boucle", i)

            for _, sTblMonster in pairs(tblMonster.underlings) do
                --Print(sTblMonster.genericId.." insert", i)
                table.insert(groupMonster.idMonster, sTblMonster.genericId)
            end

        end
        table.insert(tbl, groupMonster)
    end
    return tbl
end

function GetGameRolePlayGroupMonsterInformation(pActors)
    local tbl = {}

    for _, v in pairs(pActors) do
        if developer:typeOf(v) == "GameRolePlayGroupMonsterInformations" then
            table.insert(tbl, v)
        end
    end
    
    return tbl
end

function GetGroupMonsterStaticInformations(groupMonsterInfo)
    local tbl = {}

    for _, v in pairs(groupMonsterInfo) do
        local infos = {}
        infos.Infos = {}

        infos.contextualId = v.contextualId
        infos.cellId = v.disposition.cellId
        table.insert(infos.Infos, v.Infos)
        table.insert(tbl, infos)
    end

    return tbl
end

function CountMonster(tbl, idMonster)
    local count = 0
    for _, v in pairs(tbl) do
        if v == idMonster then
            count = count + 1
        end
    end
    return count
end

-- CallBack packet

function PacketSender(packetName, fn)
    Print("Envoie du packet "..packetName, "packet")
    local msg = developer:createMessage(packetName)

    if fn ~= nil then
        msg = fn(msg)
    end

    developer:sendMessage(msg)
end

function CB_MapDataMessage(packet)
   -- Print("MapDataMessage", "packet")
   return FightManager(packet.actors)
end

function CB_GameMapMovementMessage(packet)
    if packet.actorId < 0 then
        Print("Packet MapMovement", 'packet')
        
        for _, v in pairs(SORTED_MONSTERS_GROUP) do
            if v.contextualId == nil then
                break
            end
            if tonumber(v.contextualId) == tonumber(packet.actorId) then
                Print("Mob actualisé")
                v.cellId = packet.keyMovements[2]
                break
            end
        end
    end
end

function CB_GameFightStartingMessage()
    Print("Combat lancer", "info")
    fightStarted = true
    triedAttack = false
end

function CB_GameFightEndMessage()
    Print("Fin du combat", "info")
    ResetFightFuncVar()
end
  
-- Clear

function ClearFightFunc()
    developer:unRegisterMessage("MapComplementaryInformationsDataMessage")
    developer:unRegisterMessage("GameFightStartingMessage")
    developer:unRegisterMessage("GameFightEndMessage")
    ResetFightFuncVar()
end

function ResetFightFuncVar()
    --Print("var reset")
    SORTED_MONSTERS_GROUP = {}
    GROUP_TO_ATTACK = {}
    packetSended = false
    inCellToLaunchFight = false
    needRegen = false
    mapCheck = false
    selectedGroupToAttack = false
    fightStarted = false
    triedAttack = false
    goNextMap = false
    goFight = false
    fightConf = false
    fighFuncInit = false
end