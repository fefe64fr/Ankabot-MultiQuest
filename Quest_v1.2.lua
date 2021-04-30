AI_FILE = "ModSpellPriority.lua"
local currentDirectory = "E:\\Dofus botting\\Scripts\\Trajets\\AnkaBot\\Ankabot-MultiQuest\\"
-- Module (dofile)
    local json = dofile("E:\\Dofus botting\\Scripts\\Module\\JSON.lua")
    local QUEST, ZONE_AREA_MAPID = dofile(currentDirectory.."QuestInfo.lua")

-- Quest var

    local questInit, isDialog, objectiveValidated = false, false, false
    local questStarting, questSelected, stepSelected, stepInfoDisplayed = false, false, false,false
    local roadLoaded = false

    local nextMap = 0
    local lastMapId = 0

    local packetDialog = {}
    packetDialog.visibleReplies = {}

    local QuestList = {}
    QuestList.activeQuests = {}
    QuestList.finishedQuestsIds = {}
    QuestList.finishedQuestsCounts = {}
    QuestList.reinitDoneQuestsIds = {}

    local currentQuest, currentStep

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
    local minPercentLifeBeforeAttack = 80

    local minMonster = 1
    local maxMonster = 4

    local MONSTERS_CONF = {
        {
            idMonster = 78,
            min = 0,
            max = 8
        } 
    }

    local MAP_DATA_MONSTERS = {}
-- Gather var

    GATHER = {}

    local moveToChangeMap = false

    local nextCellDir = -1
    local userActorId = 0
    local lastPacketElementId = 0   

    local thread = {}
    local CellArray = {}

    local MAP_COMPLEMENTARY = {}
    local STATED_ELEMENTS = {}
    local HARVESTABLE_ELEMENTS = {}
--

-- Main

    function move()
        if global:isScriptPlaying() then
            AutoStats()
            AutoStuff()
            return QuestManager()
        else
            PacketSubManager()
        end
    end

    function bank()
        Print("Le retour bank n'est pas inclus", "BANK", "error")
    end

    function stopped()
        local allQuestFinished, impossibleStartQuest = CheckIfAllQuestFinish()
        if allQuestFinished then
            Print("Toutes les quête sont fini !", "quest")
        else
            Print("Toutes les quête ne sont pas fini !", "QUEST", "error")
        end
        if #impossibleStartQuest > 0 then
            Print("Impossible de commencer les quête suivantes :", "QUEST", "error")
            for _, v in pairs(impossibleStartQuest) do
                Print(v, "QUEST", "error")
            end
        end
        Print("Arret du script !", "SCRIPT")
        PacketSubManager()
        global:deleteAllMemory()
    end

    function StopScript()
        stopped()
        global:finishScript()
    end

-- Gestion des packet
    function PacketSubManager(pType, register)
        local allSub = false

        local packetToSub = {
            ["Quest"] = {
                ["QuestListMessage"] = CB_QuestListMessage,
                ["QuestStepInfoMessage"] = CB_QuestStepInfo,
                ["QuestObjectiveValidatedMessage"] = CB_QuestObjectiveValidated,
                ["QuestStartedMessage"] = CB_QuestStarted,
                ["QuestValidatedMessage"] = CB_QuestValidated,
                ["NpcDialogCreationMessage"] = CB_NpcDialogCreationMessage,
                ["NpcDialogQuestionMessage"] = CB_NpcDialogQuestionMessage,
                ["LeaveDialogMessage"] = CB_LeaveDialog     

            },
            ["Fight"] = {
                ["MapComplementaryInformationsDataMessage"] = CB_MapComplementaryInfoDataMessageFight,
                ["GameRolePlayShowActorMessage"] = CB_ShowActorMessage,    
                ["GameContextRemoveElementMessage"] = CB_ContextRemoveElementMessage,              
                ["GameMapMovementMessage"] = CB_MapMovementMessage
            },
            ["Gather"] = {
                ["MapComplementaryInformationsDataMessage"] = CB_MapComplementaryInfoDataMessageGather,
                ["StatedElementUpdatedMessage"] = CB_StatedElementUpdatedMessage,
                ["InteractiveElementUpdatedMessage"] = CB_InteractiveElementUpdatedMessage
            }
        }

        -- Gestion params
        if type(pType) == "boolean" then
            register = pType
            allSub = true
        elseif pType == nil then
            allSub = true
        end

        -- Logic 
        for kType, vPacketTbl in pairs(packetToSub) do
            if allSub then
                pType = kType
            end
            if string.lower(kType) == string.lower(pType) then
                for packetName, callBack in pairs(vPacketTbl) do
                    if register then -- Abonnement au packet
                        if not developer:isMessageRegistred(packetName) then
                            Print("Abonnement au packet : "..packetName, "packet")
                            developer:registerMessage(packetName, callBack)
                        end            
                    else -- Désabonnement des packet
                        if developer:isMessageRegistred(packetName) then
                            Print("Désabonnement du packet : "..packetName, "packet")
                            developer:unRegisterMessage(packetName)
                        end            
                    end
                end
            end
        end
    end

    function PacketSender(packetName, fn)
        Print("Envoie du packet "..packetName, "packet")
        local msg = developer:createMessage(packetName)

        if fn ~= nil then
            msg = fn(msg)
        end

        developer:sendMessage(msg)
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

--
-- Partie quête

-- Quest Manager

    function QuestManager()
        developer:suspendScriptUntilMultiplePackets({ "QuestStepInfoMessage", "QuestObjectiveValidatedMessage", "QuestObjectiveValidatedMessage", "QuestValidatedMessage"}, 0, false)

        if not questInit then
            LoadHistoricalQuestList()
            questInit = true
        end

        if objectiveValidated then
            ResetQuestVar()
        end

        PacketSubManager("quest", true)

        if not questSelected then -- Séléction de la quête
            --Print("Séléction quête")
            currentQuest = SelectQuest()
            if currentQuest == nil then
                Print("Aucune quête séléctionner !", "QuestManager", "error")
                StopScript()
            end
            questSelected = true
        end

        if questSelected and not stepSelected and currentQuest.notStepInfo ~= true and CheckIfQuestActive(currentQuest.questId) then
            --Print("Envoie packetStepInfo")
            PacketSender("QuestStepInfoRequestMessage", function(msg) msg.questId = currentQuest.questId return msg end)
            developer:suspendScriptUntil("QuestStepInfoMessage", 1000, true)
        end

        if not stepSelected then -- Séléction de l'étape de quête
            --Print("Sélection du step")
            PacketSubManager("fight")
            PacketSubManager("gather")
            currentStep = SelectStep(GetCurrentStep())
            stepSelected = true 
        end

        if currentStep ~= nil then -- Éxécution de l'étape
            --Print("Éxécution de l'étape")

            if not stepInfoDisplayed then
                Print(currentStep.displayInfo, "étape")
                stepInfoDisplayed = true
            end

            if CheckIfQuestFinish(currentQuest.questId) then
                EndQuest()
                return move()
            end

            if currentStep.stepStartMapId ~= nil then
                currentStep.EXECUTE(currentStep.stepStartMapId)
            else
                currentStep.EXECUTE()
            end

            if isDialog then
                global:leaveDialog()
            end

            local condition = currentStep.stepStartMapId ~= nil and map:currentMapId() == currentStep.stepStartMapId or currentQuest.bypassCondEndStep

            if condition and CheckIfQuestActive(currentQuest.questId) then
                EndStep()
                return move()
            elseif CheckIfQuestFinish(currentQuest.questId) then
                EndQuest()
                return move()
            elseif condition and not ( CheckIfQuestActive(currentQuest.questId) or CheckIfQuestFinish(currentQuest.questId) ) then
                Print("Impossible de commencer la quête "..currentQuest.name, "QuestManager", "error")
                Print("Séléction d'une autre quête...", "Quest")
                currentQuest.cantStart = true
                questSelected = false
                ResetQuestVar()
            else
                MoveNext()
            end
        else 
            Print("Aucune étape séléctionner", "QuestManager", "error")
            StopScript()
        end

        return move()
    end

    function LoadHistoricalQuestList()
        local packet = developer:historicalMessage("QuestListMessage")
        QuestList.activeQuests = packet[1].activeQuests
        QuestList.finishedQuestsIds = packet[1].finishedQuestsIds
        QuestList.finishedQuestsCounts = packet[1].finishedQuestsCounts
        QuestList.reinitDoneQuestsIds = packet[1].reinitDoneQuestsIds
    end

-- CallBack QuestPacket

    function CB_QuestStarted(packet)
        if not CheckIfQuestActive(packet.questId) then
            AddQuestActive(packet.questId)
        end
        --ResetQuestVar()
    end

    function CB_QuestStepInfo(packet)
        --Print("Réception du packet QuestStepInfoMessage", "packet")

        if packet.infos.questId ~= nil then
            for _, v in pairs(QuestList.activeQuests) do
                if v.questId == packet.infos.questId then
                    v.objecttives = packet.infos.objecttives
                    break
                end
            end
        end
    end

    function CB_QuestListMessage(packet)
        --Print("Réception du packet QuestListMessage", "packet")
        QuestList.activeQuests = packet.activeQuests
        QuestList.finishedQuestsIds = packet.finishedQuestsIds
        QuestList.finishedQuestsCounts = packet.finishedQuestsCounts
        QuestList.reinitDoneQuestsIds = packet.reinitDoneQuestsIds
    end

    function CB_QuestObjectiveValidated(packet)
        --Print("Objective validated", "objective")
        objectiveValidated = true
    end

    function CB_QuestValidated(packet)
        DeleteActiveQuest(packet.questId)
    end

    function CB_NpcDialogCreationMessage()
        --Print("Dialog created")
        isDialog = true
    end

    function CB_NpcDialogQuestionMessage(packet)
        --Print("Message mis a jour")
        packetDialog = packet
    end

    function CB_LeaveDialog()
        --Print("Dialog closed")
        isDialog = false
    end

-- Gestion étapes et step
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

                if vQuest.cantStart then
                    canSelect = false
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
        return nil
    end

    function SelectStep(stepId)
        if stepId == nil then
            local isActive = CheckIfQuestActive(currentQuest.questId)
            if not isActive then
                --Print('not isActive')

                if currentQuest.stepInfo.START ~= nil then
                    return currentQuest.stepInfo.START
                else
                    Print("Pas de step START sur la quête "..currentQuest.name, "SelectStep", "error")
                end
            elseif isActive then
                --Print('isActive')
                if currentQuest.stepInfo.FINISH ~= nil then
                    return currentQuest.stepInfo.FINISH
                else
                    Print("Pas de step FINISH sur la quête "..currentQuest.name, "SelectStep", "error")
                end
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
                                if StepExist(vObjecttives.objecttiveId) then
                                    return vObjecttives.objecttiveId
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    function EndStep()
        Print("Terminée -- "..currentStep.displayInfo, "étape")
        currentStep = nil
        ResetQuestVar()
    end

    function EndQuest()
        Print("Terminée -- "..Get_NameQuest(currentQuest.questId), "Quête")       
        questSelected = false
        ResetQuestVar()
    end

    function Get_NameQuest(questId)
        for kQuestName, vQuest in pairs(QUEST) do
            if vQuest.questId == questId then
                return kQuestName
            end
        end
        return "Quête non répertorier"
    end

    function ResetQuestVar()
        stepInfoDisplayed = false
        stepSelected = false
        roadLoaded = false
        objectiveValidated = false
        nextMap = 0
        global:leaveDialog()
    end

    function StepExist(stepId)
        for k, v in pairs(currentQuest.stepInfo) do
            if tostring(k) == tostring(stepId) then
                return true
            end
        end
        return false
    end

-- Tri QuestPacket

    function CheckIfQuestActive(questId)

        if QuestList.activeQuests ~= nil then
            for _, v in pairs(QuestList.activeQuests) do
                if v.questId == questId then
                    --Print('true '..v.questId.."    "..questId)
                    return true
                end
            end
        end
        --Print("false")
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

    function CheckIfAllQuestFinish()
        local impossibleStartQuest = {}
        for kNameQuest, vQuest in pairs(QUEST) do
            local finished = false
            if (vQuest.cantStart ~= nil and not vQuest.cantStart) or vQuest.cantStart == nil then
                for _, vFinishedQuest in pairs(QuestList.finishedQuestsIds) do
                    if vQuest.questId == vFinishedQuest then
                        finished = true
                        break
                    end
                end
                if not finished then
                    return false, impossibleStartQuest
                end
            else
                table.insert( impossibleStartQuest, kNameQuest)
            end
        end
        return true, impossibleStartQuest
    end

    function AddQuestActive(questId, objecttives)
        --Print(Get_NameQuest(questId).." Ajouter a QuestActive")
        local vQuest = {}
        vQuest.questId = questId

        if objecttives ~= nil then
            vQuest.objecttives = objecttives
        end

        table.insert(QuestList.activeQuests, vQuest)
    end

    function EditQuestObjecttives(questId, objecttiveId, value)
        for _, vQuest in pairs(QuestList.activeQuests) do
            if vQuest.questId == questId then
                if vQuest.objecttives ~= nil then
                    for _, vObjecttives in pairs(vQuest.objecttives) do
                        if vObjecttives.objecttiveId == objecttiveId then
                            vObjecttives.objecttiveStatus = value
                            break
                        end
                    end
                end
            end
        end

    end

    function DeleteActiveQuest(questId)
        table.insert(QuestList.finishedQuestsIds, questId)

        for i = #QuestList.activeQuests, 0, -1 do
            if QuestList.activeQuests[i].questId == questId then
                table.remove(QuestList.activeQuests, i)
                return true
            end
        end
        return false
    end

-- Npc Dialog
    function NpcDialogRequest(npcId)
        --Print("DialogRequest "..npcId)
        if not isDialog then
            isDialog = true
            PacketSender("NpcGenericActionRequestMessage", function(msg)
                msg.npcId = npcId
                msg.npcActionId = 3
                msg.npcMapId = map:currentMapId()
                return msg 
            end)
            --developer:suspendScriptUntilMultiplePackets({ "NpcDialogCreationMessage", "NpcDialogQuestionMessage"}, 300, true)
        end
    end

    function ReplyUntilLeave(tblId)
        developer:suspendScriptUntilMultiplePackets({ "NpcDialogCreationMessage", "NpcDialogQuestionMessage"}, 0, false)
        while isDialog do
            --Print("Try reply")
            local id
            for _, v in pairs(packetDialog.visibleReplies) do
                for _, c in pairs(tblId) do
                    if v == c then
                        id = v
                        break
                    end
                end
            end

            if id ~= nil and isDialog then
                NpcReply(id)
            else
                --Print("Leave no id")
                isDialog = false
                global:leaveDialog()
            end
        end
    end

    function NpcReply(id, speed)
        developer:suspendScriptUntilMultiplePackets({ "NpcDialogCreationMessage", "NpcDialogQuestionMessage"}, 0, false)

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

        global:delay(Get_RandomNumber(min, max))

        if not isDialog then
            Print("Dialog not open", "NpcReply", "error")
        end

        if id ~= nil and isDialog then
            --Print(id)
            packetDialog.visibleReplies = {}
            npc:reply(id)
        end
    end
-- Gestion Movement

    function RoadZone(tblMapId)

        if map:currentMapId() == nextMap or nextMap == 0 then
            --Print("Get next rand roadMapId")
            while map:currentMapId() == nextMap or nextMap == 0 do
                local maxDist = 0
                local tblMapIdDist = {}

                for _, v in pairs(tblMapId) do
                    local dist = map:GetDistance(map:currentMapId(), v)
                    local ins = { mapId = v, dist = dist }
                    if dist > maxDist then
                        maxDist = dist
                    end
                    --Print("Dist : "..dist)
                    table.insert(tblMapIdDist, ins)
                end
                --Print("MaxDist : "..maxDist)

                ShuffleList(tblMapIdDist)

                for _, v in pairs(tblMapIdDist) do
                    if v.dist >= math.ceil(maxDist / 2) then
                        --Print(v.dist)
                        nextMap = v.mapId
                        break
                    end
                end
            end
            --Print("Next roadMapId = "..nextMap)
            if not map:loadMove(nextMap) then
                Print("Impossible de charger le trajet jusqu'a la mapId : ("..nextMap..") changement de map avant re tentative", "RoadZone", "error")
                local dir, mapId = Get_RandomNeighbourMapId()
                map:changeMap(dir)
            end
        end
        MoveNext()
        nextMap = 0
    end

    function Get_RandomNeighbourMapId()
        local possibleDir = { "left", "right", "top", "bottom"}
        local nextMap = 0
        ShuffleList(possibleDir)

        for _, dir in pairs(possibleDir) do
            nextMap = map:neighbourId(dir)
            if nextMap ~= 0 then
                return dir, nextMap
            end
        end
    end

    function LoadRoadIfNotInMap(compareMap)
        --Print("Load road, roadLoaded = "..tostring(roadLoaded))
        if map:currentMapId() ~= compareMap and not roadLoaded then
            CheckImpossibleLoadMapid()
            if not map:loadRoadToMapId(compareMap) then
                Print("Impossible de charger un chemin jusqu'a "..currentStep.displayInfo, currentQuest.name, "error")
            else
                roadLoaded = true
            end
        elseif map:currentMapId() == compareMap then
            roadLoaded = false
        end
    end

    function CheckImpossibleLoadMapid()
        local impossibleLoadMapId = {
            { map = 153356288, cell = "410" },
            { map = 153354246, cell = "397" },
            { map = 153354244, cell = "410" },
            { map = 153355268, cell = "372" },
            { map = 153355270, cell = "415" },
            { map = 153354248, door = "328" },
            { map = 153355266, cell = "385" },
            { map = 153356296, cell = "401" },
            { map = 153354240, cell = "409" },
            { map = 153355272, cell = "382" },
            { map = 153356294, cell = "452" },
            { map = 153354242, cell = "424" },
            { map = 153355272, cell = "382" }
        }

        for _, v in pairs(impossibleLoadMapId) do
            if map:currentMapId() == v.map then
                if v.cell ~= nil then
                    map:moveToCell(tonumber(v.cell))
                elseif v.door ~= nil then
                    map:door(tonumber(v.door))
                end
            end

        end
    end

    function MoveNext()
        --Print("Try moveNext")
        if lastMapId == map:currentMapId() then
            roadLoaded = false
            lastMapId = 0
        else
            lastMapId = map:currentMapId()
        end
        map:moveRoadNext()
        roadLoaded = false
        local dir, mapId = Get_RandomNeighbourMapId()
        if dir ~= nil then
            map:changeMap(dir)
            map:moveToward(mapId)
        end
   end
--
-- Partie fight

-- Fight Manager
    function Fight(config)
        --Print("fight")
        PacketSubManager("gather", false)

        if config ~= nil then
            minMonster = config.minMonster
            maxMonster = config.maxMonster
            MONSTERS_CONF = config.conf
        end

        PacketSubManager("fight", true)

        if character:lifePointsP() < minPercentLifeBeforeAttack then
            Print("Régéneration des PV avant reprise des combats", "fight")
            while character:lifePoints() < character:maxLifePoints() do
                global:delay(1500)
            end
            Print("Fin de régéneration des PV reprise des combats", "fight")
        end

        for _, v in pairs(MAP_DATA_MONSTERS) do
            if MeetConditionsToAttack(v.idMonster) then
                if map:currentCell() ~= v.cellId then
                    Print("Déplacement vers la cellule du lancement de combat", "fight")
                    map:moveToCell(v.cellId)
                    developer:unRegisterMessage("GameMapMovementMessage")
                    TryAttack(v.contextualId)
                end
            end
        end

        MAP_DATA_MONSTERS = {}
        developer:unRegisterMessage("GameMapMovementMessage")
    end

    function TryAttack(ctxId)
        Print("Tentative attack", 'fight')

        PacketSender("GameRolePlayAttackMonsterRequestMessage", function(msg)
            msg.monsterGroupId = ctxId
            return msg
        end)

        if not developer:suspendScriptUntil("GameFightStartingMessage", 2500, false) then
            Print("Le lancement du combat a échoué", "TryAttack", "error")
        else
            MAP_DATA_MONSTERS = {}
        end
    end

    function MeetConditionsToAttack(tblIdMonsters)
        local verified = {}

        if #tblIdMonsters < minMonster or #tblIdMonsters > maxMonster then
            return false
        end

        for _, conf in pairs(MONSTERS_CONF) do
            local count = CountIdenticValue(tblIdMonsters, conf.idMonster)
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


-- CallBack FightPacket

    function CB_MapComplementaryInfoDataMessageFight(packet)
        --Print("MapComplementary")
        if #packet.actors > 0 then
            MAP_DATA_MONSTERS = Get_SortedGroupMonster(packet.actors)
        end
    end

    function CB_ShowActorMessage(packet)
        --Print("ShowActor")
        if developer:typeOf(packet.informations) == "GameRolePlayGroupMonsterInformations" then
            local updated = false
            local sortedGroup = Get_SortedGroupMonster({packet.informations})

            for _, v in pairs(MAP_DATA_MONSTERS) do
                if v.contextualId == sortedGroup[1].contextualId then
                    updated = true
                    --Print("Update groupMonster")
                    v = sortedGroup[1]
                    break
                end
            end

            if not updated then
                --Print("Ajouter a mapData")
                table.insert(MAP_DATA_MONSTERS, sortedGroup[1])
            end
        end
    end

    function CB_MapMovementMessage(packet)
        if packet.actorId < 0 then
            --Print("MapMovement")
            --Print(packet.keyMovements[1])
            --Print(packet.keyMovements[2])
            for _, v in pairs(MAP_DATA_MONSTERS) do
                if v.contextualId == packet.actorId then
                    --Print("Monster updated")
                    v.cellId = packet.keyMovements[2]
                    break
                end
            end
        end
    end

    function CB_ContextRemoveElementMessage(packet)
        --Print("ContextRemove")
        for i = #MAP_DATA_MONSTERS, 1, -1 do
            if MAP_DATA_MONSTERS[i].contextualId == packet.id then
                --Print("Monster removed")
                table.remove(MAP_DATA_MONSTERS, i)
                break
            end
        end
    end

-- Tri FightPacket

    function Get_SortedGroupMonster(pActors)
        local staticInfo = Get_GroupMonsterStaticInfo(Get_GroupMonsterInfo(pActors))
        local tbl = {}

        for i, tblGroupMonster in pairs(staticInfo) do
            local groupMonster = {}
            groupMonster.idMonster = {}
            groupMonster.cellId = tblGroupMonster.cellId
            groupMonster.contextualId = tblGroupMonster.contextualId

            for _, tblMonster in pairs(tblGroupMonster.Infos) do
                table.insert(groupMonster.idMonster, tblMonster.mainCreatureLightInfos.genericId)

                for _, sTblMonster in pairs(tblMonster.underlings) do
                    table.insert(groupMonster.idMonster, sTblMonster.genericId)
                end

            end
            table.insert(tbl, groupMonster)
        end
        return tbl
    end

    function Get_GroupMonsterInfo(pActors)
        local tbl = {}

        for _, v in pairs(pActors) do
            if developer:typeOf(v) == "GameRolePlayGroupMonsterInformations" then
                table.insert(tbl, v)
            end
        end
        
        return tbl
    end

    function Get_GroupMonsterStaticInfo(groupMonsterInfo)
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

-- Gestion Config monsters

    function AddMonsterConf(idMonster, min, max)
        local ins = { idMonster = idMonster , min = min, max = max }
        table.insert(MONSTERS_CONF, ins)
        Print(Get_NameMonster(idMonster).." Ajoutée a la configuration", "Conf")
    end

    function DelMonsterConf(idMonster)
        for i = #MONSTERS_CONF, 1, -1 do
            if MONSTERS_CONF[i].idMonster == idMonster then
                Print(Get_NameMonster(idMonster).." Supprimé de la configuration", 'Conf')
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
                Print(Get_NameMonster(idMonster).." Modifié dans la configuration", "Conf")
                break
            end
        end
    end

    function ClearMonsterConf()
        MONSTERS_CONF = {}
        Print("Configuration monstres réinitialiser", "Conf")
    end

    -- Appel API

    function Get_NameMonster(id)
        return assert(json:decode(developer:getRequest("https://fr.dofus.dofapi.fr/monsters/"..id)).name) or id
    end

--
-- Partie Gather

-- Logic GatherFunc

    function Gather()
        PacketSubManager("fight", false)
        if #CellArray == 0 then
            InitCellsArray()
        end

        if userActorId == 0 then
            local histoActor = developer:historicalMessage("CharacterSelectedSuccessMessage")
            userActorId = histoActor[1].infos.id
        end

        PacketSubManager("gather", true)
        developer:suspendScriptUntil("MapComplementaryInformationsDataMessage", 10, false)
        moveToChangeMap = false

        SortMapComplementary()

        if #HARVESTABLE_ELEMENTS > 0 then
            HARVESTABLE_ELEMENTS = TableFilter(HARVESTABLE_ELEMENTS, function(v)
                return CanGather(v.elementTypeId)
            end)

            for _, v in pairs(HARVESTABLE_ELEMENTS) do
                v.distance = ManhattanDistanceCellId(map:currentCell(), v.cellId)
            end

            table.sort(HARVESTABLE_ELEMENTS, function(a, b)
                return a.distance < b.distance
            end)

            for _, v in pairs(HARVESTABLE_ELEMENTS) do
                developer:suspendScriptUntilMultiplePackets({ "StatedElementUpdatedMessage", "InteractiveElementUpdatedMessage"}, 1, false)
                if not v.deleted then
                    map:door(v.cellId)
                end
            end
        end

        HARVESTABLE_ELEMENTS = {}
        STATED_ELEMENTS = {}

        moveToChangeMap = true
        developer:registerMessage("GameMapMovementMessage", CB_MapMovementMessageGather)
    end

    function CanGather(gatherId)
        if #GATHER == 0 then
            return true
        end
        for _, v in pairs(GATHER) do
            if v == gatherId then
                return true
            end
        end
        return false
    end

    function Dispatcher()

        Print("Start Dispatcher")
        for i = #thread, 1, -1 do
            thread[i]()
            table.remove(thread, i)
        end
        lastPacketElementId = 0
        Print("end dispatcher")
        if IsCellIdValid(nextCellDir) then
            local nextDir, cell = CellIdToDir(nextCellDir)
            nextCellDir = -1
            if nextDir ~= nil and cell ~= nil then
                map:changeMap(nextDir.."("..cell..")")
            end
        end
    end

-- Cell to X Y

    function InitCellsArray()
        local startX = 0
        local startY = 0
        local cell = 0
        local axeX = 0
        local axeY = 0

        while (axeX < 20) do
            axeY = 0

            while (axeY < 14) do
                CellArray[cell] = {x = startX + axeY, y = startY + axeY}
                cell = cell + 1
                axeY = axeY + 1
            end

            startX = startX + 1
            axeY = 0

            while (axeY < 14) do
                CellArray[cell] = {x = startX + axeY, y = startY + axeY}
                cell = cell + 1
                axeY = axeY + 1
            end

            startY = startY - 1
            axeX = axeX + 1
        end

        --Print("CellArrayInitialised")
    end

    function ManhattanDistanceCellId(fromCellId, toCellId)
        local fromCoord = CellIdToCoord(fromCellId)
        local toCoord = CellIdToCoord(toCellId)
        if fromCoord ~= nil and toCoord ~= nil then
            return (math.abs(toCoord.x - fromCoord.x) + math.abs(toCoord.y - fromCoord.y))
        end
        return nil
    end

    function ManhattanDistanceCoord(fromCoord, toCoord)
        return (math.abs(toCoord.x - fromCoord.x) + math.abs(toCoord.y - fromCoord.y))
    end

    function CellIdToCoord(cellId)
        if IsCellIdValid(cellId) then
            return CellArray[cellId]
        end

        return nil
    end

    function CoordToCellId(coord)
        return math.floor((((coord.x - coord.y) * 14) + coord.y) + ((coord.x - coord.y) / 2))
    end

    function IsCellIdValid(cellId)
        return (cellId >= 0 and cellId < 560)
    end

-- CallBack GatherFunc

    function CB_MapComplementaryInfoDataMessageGather(packet)
        MAP_COMPLEMENTARY = packet
    end

    function CB_StatedElementUpdatedMessage(packet)
        packet = packet.statedElement
        table.insert(STATED_ELEMENTS, packet)
    end

    function CB_InteractiveElementUpdatedMessage(packet)
        --Print("Interac")
        packet = packet.integereractiveElement
        if packet.onCurrentMap then
            if #packet.enabledSkills > 0 then
                --Print("Repop")
                for _, v in pairs(STATED_ELEMENTS) do
                    --Print(packet.elementId.."   "..v.elementId)
                    if v.elementId == packet.elementId then
                        if CanGather(packet.elementTypeId) then
                            --Print("Repoped elem")
                            if moveToChangeMap then
                                --[[ if lastPacketElementId ~= packet.elementId then
                                    lastPacketElementId = packet.elementId
                                    table.insert(thread, function()
                                        local cellId = v.elementCellId
                                        map:door(cellId)
                                    end)
                                end
                                developer:suspendScriptUntil("InteractiveElementUpdatedMessage", 1, false)
                                if #thread > 0 then
                                    Dispatcher()
                                end ]]
                            else
                                local elem = {}
                                elem.deleted = false
                                elem.cellId = v.elementCellId
                                elem.elementId = packet.elementId
                                table.insert(HARVESTABLE_ELEMENTS, elem)
                                break
                            end
                        end
                    end
                end
            elseif #packet.disabledSkills > 0 then
                for i = #HARVESTABLE_ELEMENTS, 1, -1 do
                    if HARVESTABLE_ELEMENTS[i].elementId == packet.elementId then
                        --Print("deleted")
                        HARVESTABLE_ELEMENTS[i].deleted = true
                        break
                    end
                end
            end
        end
    end

    function CB_MapMovementMessageGather(packet)
        if packet.actorId == userActorId then
            nextCellDir = packet.keyMovements[#packet.keyMovements]
            forcedDir = packet.forcedDirection
            developer:unRegisterMessage("GameMapMovementMessage")
        end
    end

-- Tri packet gather

    function SortMapComplementary()
        local integereractiveElements =  MAP_COMPLEMENTARY.integereractiveElements
        local statedElements = MAP_COMPLEMENTARY.statedElements

        if integereractiveElements ~= nil and statedElements ~= nil then
            for _, vIntegeractive in ipairs(integereractiveElements) do
                if vIntegeractive.onCurrentMap then
                    for _, vStated in pairs(statedElements) do
                        if vIntegeractive.elementId == vStated.elementId then
                            local elem = {}
                            elem.deleted = false
                            elem.cellId = vStated.elementCellId
                            elem.elementTypeId = vIntegeractive.elementTypeId
                            elem.elementId = vIntegeractive.elementId
                            if #vIntegeractive.enabledSkills > 0 then
                                elem.skillInstanceUid = vIntegeractive.enabledSkills[1].skillInstanceUid
                                table.insert(HARVESTABLE_ELEMENTS, elem)
                            end
                        end
                    end
                end
            end
        end
    end
--
-- Zone area mapid

    function Get_TblZoneArea(area)
        for kArea, vArea in pairs(ZONE_AREA_MAPID) do
            if isStringEqual(kArea, area) then
                return vArea
            end
        end
    end

    function Get_TblZoneSubArea(area, subArea)
        if type(subArea) == "string" then
            for kSubArea, vTblMapIdArea in pairs(Get_TblZoneArea(area)) do
                if isStringEqual(kSubArea, subArea) then
                    return vTblMapIdArea
                end
            end

        elseif type(subArea) == "table" then
            local zoneArea = Get_TblZoneArea(area)
            local tmpTblMapId = {}

            for _, vSubArea in pairs(subArea) do
                for kSubArea, vTblMapIdArea in pairs(zoneArea) do
                    if isStringEqual(kSubArea, vSubArea) then
                        for _, vMapId in pairs(vTblMapIdArea) do
                            table.insert(tmpTblMapId, vMapId)
                        end
                        break
                    end
                end
            end

            return tmpTblMapId
        end
    end

-- Utilitaire

    function isStringEqual(str1, str2)
        return string.lower(str1) == string.lower(str2)
    end

    function Get_RandomNumber(min, max)
        return global:random(min, max)
    end

    function ShuffleList(list)
        for i = #list, 2, -1 do
            local j = Get_RandomNumber(1, i)
            list[i], list[j] = list[j], list[i]
        end
    end

    function InMapChecker(tbl)
        for _, v in pairs(tbl) do
            if map:currentMapId() == v then
                return true
            end
            global:delay(2)
        end
        return false
    end

    function CountIdenticValue(tbl, value)
        local count = 0
        for _, v in pairs(tbl) do
            if v == value then
                count = count + 1
            end
        end
        return count
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

    function TableFilter(tbl, func)
        local newtbl= {}
        for i, v in pairs(tbl) do
            if func(v) then
                table.insert(newtbl, v)
            end
        end
        return newtbl
    end

    function InitCellsArray()
        local startX = 0
        local startY = 0
        local cell = 0
        local axeX = 0
        local axeY = 0

        while (axeX < 20) do
            axeY = 0

            while (axeY < 14) do
                CellArray[cell] = {x = startX + axeY, y = startY + axeY}
                cell = cell + 1
                axeY = axeY + 1
            end

            startX = startX + 1
            axeY = 0

            while (axeY < 14) do
                CellArray[cell] = {x = startX + axeY, y = startY + axeY}
                cell = cell + 1
                axeY = axeY + 1
            end

            startY = startY - 1
            axeX = axeX + 1
        end

        --Print("CellArrayInitialised")
    end

    function ManhattanDistanceCellId(fromCellId, toCellId)
        local fromCoord = CellIdToCoord(fromCellId)
        local toCoord = CellIdToCoord(toCellId)
        if fromCoord ~= nil and toCoord ~= nil then
            return (math.abs(toCoord.x - fromCoord.x) + math.abs(toCoord.y - fromCoord.y))
        end
        return nil
    end
    
    function ManhattanDistanceCoord(fromCoord, toCoord)
        return (math.abs(toCoord.x - fromCoord.x) + math.abs(toCoord.y - fromCoord.y))
    end

    function CellIdToCoord(cellId)
        if IsCellIdValid(cellId) then
            return CellArray[cellId]
        end
    
        return nil
    end
    
    function CoordToCellId(coord)
        return math.floor((((coord.x - coord.y) * 14) + coord.y) + ((coord.x - coord.y) / 2))
    end

    function IsCellIdValid(cellId)
        if #CellArray == 0 then
            InitCellsArray()
        end
        return (cellId >= 0 and cellId < 560)
    end

    function CellIdToDir(cell)
        if cell == ( 0 or 14 ) then
            if forcedDirection == 2 then
                return "left"
            else
                return "top"
            end
        end

        local cellDir = {}
        cellDir.top = {}
        cellDir.bottom = {}
        cellDir.right = {}
        cellDir.left = {}

        local x = 532
        local y = 26
    
        for i = 0, y do -- Top Bottom
            if i <= 26 then
                table.insert(cellDir.top, i)
                if i == 26 then
                    i = 533
                    y = 559    
                end
            elseif i >= 533 then
                table.insert(cellDir.bottom, i)
            end
        end

        for i = 0, x, 14 do -- Left
            table.insert(cellDir.left, i)
            if i == 532 then
                x = 559
                break
            end
        end

        for i = 13, x, 14 do -- Left
            table.insert(cellDir.right, i)
        end

        for k, v in pairs(cellDir) do
            for _, v in pairs(v) do
               if v == cell then
                    return k, cell
               end
            end
        end
    end

    function Print(msg, header, msgType)
        local msg = tostring(msg)
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