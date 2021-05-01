AI_FILE = "ModSpellPriority.lua"

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
        ["Coiffe"] = { gid = 8246, lvl = 8, pos = 6 },
        ["Cape"] = { gid = 8233, lvl = 10, pos = 7 },
        ["Amulette"] = { gid = 8216, lvl = 7, pos = 0 },
        ["Anneau n°1"] = { gid = 2475, lvl = 8, pos = 2 },
        ["Anneau n°2"] = { gid = 8222, lvl = 12, pos = 4 },
        ["Ceinture"] = { gid = 8246, lvl = 9, pos = 3 },
        ["Bottes"] = { gid = 8228, lvl = 11, pos = 5 }
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

    function phenix()
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
                ["GameMapMovementMessage"] = CB_MapMovementMessage,
                ["GameFightStartingMessage"] = CB_GameFightStartingMessage

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
                            --Print("Abonnement au packet : "..packetName, "packet")
                            developer:registerMessage(packetName, callBack)
                        end            
                    else -- Désabonnement des packet
                        if developer:isMessageRegistred(packetName) then
                            --Print("Désabonnement du packet : "..packetName, "packet")
                            developer:unRegisterMessage(packetName)
                        end            
                    end
                end
            end
        end
    end

    function PacketSender(packetName, fn)
        --Print("Envoie du packet "..packetName, "packet")
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
            PacketSubManager("fight", false)
            PacketSubManager("gather", false)
            currentStep = SelectStep(GetCurrentStep())
            stepSelected = true 
        end

        if currentStep.EXECUTE ~= nil then -- Éxécution de l'étape
            --Print("Éxécution de l'étape")

            if not stepInfoDisplayed then
                Print(currentStep.displayInfo, "étape")
                stepInfoDisplayed = true
            end

            if CheckIfQuestFinish(currentQuest.questId) then
                EndQuest()
                return move()
            end

            if currentQuest.preStartFunction ~= nil then
                currentQuest.preStartFunction()
            end

            if currentStep.preStartFunction ~= nil then
                currentQuest.preStartFunction()
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
                --MoveNext()
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
            --developer:suspendScriptUntilMultiplePackets({ "NpcDialogCreationMessage", "NpcDialogQuestionMessage"}, 0, true)
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
            packetDialog.visibleReplies = {}
            npc:reply(id)
        end
    end
-- Gestion Movement

    function GoAstrub()
        if isStringEqual(map:currentArea(), "Incarnam") then
            LoadRoadIfNotInMap(153880835)
            local possibleIdReply = {
                36982,
                36980
            }

            if map:currentMapId() == 153880835 then
                NpcDialogRequest(-20001)
                ReplyUntilLeave(possibleIdReply)
            else
                MoveNext()
            end
        end
    end

    function RoadZone(tblMapId)

        if map:currentMapId() == nextMap or nextMap == 0 then
            Print("Get next rand roadMapId")
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
                    break
                end
            end
        end
        local tmp = false

        if #MAP_DATA_MONSTERS == 0 then
            tmp = true
        end

        MAP_DATA_MONSTERS = {}

        if false then
            PacketSender("MapInformationsRequestMessage", function(msg)
                msg.mapId = map:currentMapId()
                return msg
            end)
        end

        developer:unRegisterMessage("GameMapMovementMessage")
        developer:unRegisterMessage("GameContextRemoveElementMessage")
        developer:unRegisterMessage("GameRolePlayShowActorMessage")
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

            --[[ for _, v in pairs(MAP_DATA_MONSTERS) do
                if v.contextualId == sortedGroup[1].contextualId then
                    updated = true
                    --Print("Update groupMonster")
                    v = sortedGroup[1]
                    break
                end
            end ]]

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

    function CB_GameFightStartingMessage()
        --Print("reset")
        --MAP_DATA_MONSTERS = {}
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
        return id
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

        moveToChangeMap = true
        developer:registerMessage("GameMapMovementMessage", CB_MapMovementMessageGather)
        developer:unRegisterMessage("InteractiveElementUpdatedMessage")
        developer:unRegisterMessage("StatedElementUpdatedMessage")
        HARVESTABLE_ELEMENTS = {}
        STATED_ELEMENTS = {}
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
            if #packet.enabledSkills > 100 then
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
--
-- Quête Info

    QUEST = {
        ["Drop pano Aventurier"] = {
            questId = 0000000000,
            minLevel = 12,
            bypassCondEndStep = true,
            notStepInfo = true,
            cantStart = true,
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 6 -- Start",
                    ["EXECUTE"] = function(stepStartMapId)

                        local objecttives = {
                            {
                                objecttiveId = 1,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 2,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 3,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 4,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 5,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 6,
                                objecttiveStatus = true
                            }
                        }

                        local notZero = function(int)
                            return int > 0
                        end

                        if notZero(inventory:itemCount(2473)) and notZero(inventory:itemCount(2474)) and notZero(inventory:itemCount(2475)) and notZero(inventory:itemCount(2476)) and notZero(inventory:itemCount(2477)) and notZero(inventory:itemCount(2478)) then
                            AddQuestActive(0000000000, objecttives)
                            DeleteActiveQuest(0000000000)
                        else
                            AddQuestActive(0000000000, objecttives)
                        end
                    end   
                }, 
                ["1"] = {
                    displayInfo = "Étape 1 / 6 -- Drop cape aventurier",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Route des âmes")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {}
                        }

                        if inventory:itemCount(2473) > 0 then
                            EditQuestObjecttives(0000000000, 1, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)
                        end
                    end
                },
                ["2"] = {
                    displayInfo = "Étape 2 / 6 -- Drop coiffe aventurier",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Cimetière")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {}
                        }

                        if inventory:itemCount(2474) > 0 then
                            EditQuestObjecttives(0000000000, 2, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end
                            RoadZone(tblMapId)
                        end
                    end
                }, 
                ["3"] = {
                    displayInfo = "Étape 3 / 6 -- Drop anneau aventurier",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Forêt")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {}
                        }

                        if inventory:itemCount(2475) > 0 then
                            EditQuestObjecttives(0000000000, 3, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end
                            RoadZone(tblMapId)
                        end
                    end
                }, 
                ["4"] = {
                    displayInfo = "Étape 4 / 6 -- Drop bottes aventurier",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Pâturages")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {}
                        }

                        if inventory:itemCount(2476) > 0 then
                            EditQuestObjecttives(0000000000, 4, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end
                            RoadZone(tblMapId)
                        end
                    end
                },       
                ["5"] = {
                    displayInfo = "Étape 5 / 6 -- Drop ceinture aventurier",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Lac")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {}
                        }

                        if inventory:itemCount(2477) > 0 then
                            EditQuestObjecttives(0000000000, 5, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end
                            RoadZone(tblMapId)
                        end
                    end
                },       
                ["6"] = {
                    displayInfo = "Étape 6 / 6 -- Drop amulette aventurier",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 3,
                            conf = {}
                        }

                        if inventory:itemCount(2478) > 0 then
                            DeleteActiveQuest(0000000000)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end
                            RoadZone(tblMapId)
                        end
                    end
                }
            }
        },
        ["Drop pano Piou"] = {
            questId = 0000000001,
            minLevel = 12,
            bypassCondEndStep = true,
            notStepInfo = true,
            colorPano = "Vert",
            idPano = {
                ["Coiffe"] = {
                    ["Rouge"] = 8243,
                    ["Bleu"] = 8244,
                    ["Violet"] = 8245,
                    ["Vert"] = 8246,
                    ["Jaune"] = 8247,
                    ["Rose"] = 8248
                },
                ["Cape"] = {
                    ["Rouge"] = 8231,
                    ["Bleu"] = 8232,
                    ["Violet"] = 8234,
                    ["Vert"] = 8233,
                    ["Jaune"] = 8236,
                    ["Rose"] = 8235
                },
                ["Ceinture"] = {
                    ["Rouge"] = 8237,
                    ["Bleu"] = 8238,
                    ["Violet"] = 8239,
                    ["Vert"] = 8240,
                    ["Jaune"] = 8241,
                    ["Rose"] = 8242
                },
                ["Bottes"] = {
                    ["Rouge"] = 8225,
                    ["Bleu"] = 8226,
                    ["Violet"] = 8227,
                    ["Vert"] = 8228,
                    ["Jaune"] = 8229,
                    ["Rose"] = 8230
                },
                ["Anneau"] = {
                    ["Rouge"] = 8219,
                    ["Bleu"] = 8220,
                    ["Violet"] = 8221,
                    ["Vert"] = 8222,
                    ["Jaune"] = 8223,
                    ["Rose"] = 8234
                },
                ["Amulette"] = {
                    ["Rouge"] = 8213,
                    ["Bleu"] = 8214,
                    ["Violet"] = 8215,
                    ["Vert"] = 8216,
                    ["Jaune"] = 8217,
                    ["Rose"] = 8218
                }
            },
            idMonsters = {
                ["Rouge"] = 489,
                ["Bleu"] = 491,
                ["Violet"] = 236,
                ["Vert"] = 490,
                ["Jaune"] = 493,
                ["Rose"] = 492
            },
            getPanoId = function(type)
                for kType, vTblId in pairs(currentQuest.idPano) do
                    if isStringEqual(kType, type) then
                        for kColor, id in pairs(vTblId) do
                            if isStringEqual(kColor, currentQuest.colorPano) then
                                return id
                            end
                        end
                    end
                end
            end,
            getIdMonster = function()
                for kColor, id in pairs(currentQuest.idMonsters) do
                    if isStringEqual(kColor, currentQuest.colorPano) then
                        return id
                    end
                end
            end,
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 6 -- Start",
                    ["EXECUTE"] = function(stepStartMapId)

                        local objecttives = {
                            {
                                objecttiveId = 1,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 2,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 3,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 4,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 5,
                                objecttiveStatus = true
                            },
                            {
                                objecttiveId = 6,
                                objecttiveStatus = true
                            }
                        }

                        local tblPanoId = {}

                        for k, _ in pairs(currentQuest.idPano) do
                            table.insert(tblPanoId, currentQuest.getPanoId(k))
                        end

                        local checker = function(tbl)
                            for _, v in pairs(tbl) do
                                if inventory:itemCount(v) < 1 then
                                    return false
                                end
                            end
                            return true
                        end

                        if checker(tblPanoId) then
                            AddQuestActive(0000000001, objecttives)
                            DeleteActiveQuest(0000000001)
                        else
                            AddQuestActive(0000000001, objecttives)
                            GoAstrub()
                        end
                    end   
                }, 
                ["1"] = {
                    displayInfo = "Étape 1 / 6 -- Drop cape Piou",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Astrub", "Cité d'Astrub")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {{ idMonster = currentQuest.getIdMonster(), min = 1, max = 8 }}
                        }

                        if inventory:itemCount(currentQuest.getPanoId("Cape")) > 0 then
                            EditQuestObjecttives(0000000001, 1, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)
                        end
                    end
                },
                ["2"] = {
                    displayInfo = "Étape 2 / 6 -- Drop coiffe Piou",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Astrub", "Cité d'Astrub")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {{ idMonster = currentQuest.getIdMonster(), min = 1, max = 8 }}
                        }

                        if inventory:itemCount(currentQuest.getPanoId("Coiffe")) > 0 then
                            EditQuestObjecttives(0000000001, 2, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)
                        end
                    end
                }, 
                ["3"] = {
                    displayInfo = "Étape 3 / 6 -- Drop anneau Piou",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Astrub", "Cité d'Astrub")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {{ idMonster = currentQuest.getIdMonster(), min = 1, max = 8 }}
                        }

                        if inventory:itemCount(currentQuest.getPanoId("Anneau")) > 0 then
                            EditQuestObjecttives(0000000001, 3, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)
                        end
                    end
                }, 
                ["4"] = {
                    displayInfo = "Étape 4 / 6 -- Drop bottes Piou",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Astrub", "Cité d'Astrub")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {{ idMonster = currentQuest.getIdMonster(), min = 1, max = 8 }}
                        }

                        if inventory:itemCount(currentQuest.getPanoId("Bottes")) > 0 then
                            EditQuestObjecttives(0000000001, 4, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)
                        end
                    end
                },       
                ["5"] = {
                    displayInfo = "Étape 5 / 6 -- Drop ceinture Piou",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Astrub", "Cité d'Astrub")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {{ idMonster = currentQuest.getIdMonster(), min = 1, max = 8 }}
                        }

                        if inventory:itemCount(currentQuest.getPanoId("Ceinture")) > 0 then
                            EditQuestObjecttives(0000000001, 5, false)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)
                        end
                    end
                },       
                ["6"] = {
                    displayInfo = "Étape 6 / 6 -- Drop amulette Piou",
                    ["EXECUTE"] = function()
                        local tblMapId = Get_TblZoneSubArea("Astrub", "Cité d'Astrub")

                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {{ idMonster = currentQuest.getIdMonster(), min = 1, max = 8 }}
                        }

                        if inventory:itemCount(currentQuest.getPanoId("Amulette")) > 0 then
                            DeleteActiveQuest(0000000001)
                        else
                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)
                        end
                    end
                }
            }
        },
        ["L'anneau de tous les dangers"] = {
            questId = 1629,
            stepInfo = {
                ["START"] = {
                    displayInfo = "Étape 0 / 10 -- Récupérer la quête",
                    stepStartMapId = 153092354,
                    ["EXECUTE"] = function(stepStartMapId)    
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            npc:npc(2897 , 3)
                            NpcReply(-1, "slow")
                            NpcReply(-1)
                        else
                            MoveNext()
                        end
                    end   
                },           
                ["9655"] = {
                    displayInfo = "Étape 1 / 10 -- Monter les éscalier",
                    stepStartMapId = 153092354,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(276)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9656"] = {
                    displayInfo = "Étape 2 / 10 -- Parler a maître Hoboulo",
                    stepStartMapId = 153093380,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            npc:npc(2895 , 3)
                            NpcReply(-1, "slow")
                            NpcReply(-1)
                            NpcReply(-1, "fast")
                        else
                            MoveNext()
                        end
                    end
                },
                ["9657"] = {
                    displayInfo = "Étape 3 / 10 -- Couper du blé",
                    stepStartMapId = 153093380,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            --map:moveToCell(381)
                            map:door(395)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9658"] = {
                    displayInfo = "Étape 4 / 10 -- Cueillir un ortie",
                    stepStartMapId = 153093380,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            --map:moveToCell(271)
                            map:door(258)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9659"] = {
                    displayInfo = "Étape 5 / 10 -- Couper du bois",
                    stepStartMapId = 153093380,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            --map:moveToCell(311)
                            map:door(297)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9660"] = {
                    displayInfo = "Étape 6 / 10 -- Miner du fer",
                    stepStartMapId = 153093380,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            --map:moveToCell(353)
                            map:door(340)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9661"] = {
                    displayInfo = "Étape 7 / 10 -- Pêcher un poisson",
                    stepStartMapId = 153093380,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            --map:moveToCell(330)
                            map:door(303)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9662"] = {
                    displayInfo = "Étape 8 / 10 -- Fabriquer l'anneau",
                    stepStartMapId = 153093380,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(508989, -1)
                            craft:putItem(289, 1)
                            craft:putItem(303, 1)
                            craft:putItem(312, 1)
                            craft:putItem(421, 1)
                            craft:putItem(1782, 1)
                            craft:ready()
                            global:leaveDialog()
                        else
                            MoveNext()
                        end
                    end
                },
                ["10015"] = {
                    displayInfo = "Étape 9 / 10 -- Parler a maître Hoboulo",
                    stepStartMapId = 153093380,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            npc:npc(2895 , 3)
                            NpcReply(-1, "slow")
                        else
                            MoveNext()
                        end
                    end
                },
                ["9663"] = {
                    displayInfo = "Étape 10 / 10 -- Parler a ganymède",
                    stepStartMapId = 153092354,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20001)
                            --NpcReply(-1, "slow")
                        else
                            MoveNext()
                        end
                    end
                }          
            }
        },
        ["Sous le regard des dieux"] = {
            requiredFinishedQuest = { 1629 },
            questId = 1630,
            stepInfo = {
                ["START"] = {
                    displayInfo = "Étape 0 / 6 -- Récupérer la quête",
                    stepStartMapId = 153092354,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            24749,
                            24748
                        }
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20001)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9680"] = {
                    displayInfo = "Etape 1 / 5 -- Entrer dans la salle de combat",
                    stepStartMapId = 153092354,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(189)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9685"] = {
                    displayInfo = "Etape 2 / 5 -- Parler a Maître Dam",
                    stepStartMapId = 153092356,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1, 'slow')
                            NpcReply(-1)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9720"] = {
                    displayInfo = "Etape 3 / 5 -- Combattre les deux monstres",
                    stepStartMapId = 153092356,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20002)
                            NpcReply(24793)
                        else
                            MoveNext()
                        end
                    end
                },
                ["10121"] = {
                    displayInfo = "Etape 3 / 5 -- Combattre les deux monstres",
                    stepStartMapId = 153092356,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20001)
                            NpcReply(24791)
                        else
                            MoveNext()
                        end
                    end
                },
                ["10016"] = {
                    displayInfo = "Etape 4 / 5 -- Parler a Maître Dam",
                    stepStartMapId = 153092356,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1, "slow")
                        else
                            MoveNext()
                        end
                    end
                },
                ["9734"] = {
                    displayInfo = "Etape 5 / 5 -- Parler a Ganymède",
                    stepStartMapId = 153092354,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1)
                            --return EndQuest("npcReply", -1)
                        else
                            MoveNext()
                        end
                    end
                }
            }
        },
        ["Réponses à tout"] = {
            questId = 1631,
            requiredFinishedQuest = { 1629, 1630 },
            stepInfo = {
                ["START"] = {
                    displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                    stepStartMapId = 152043521,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)                       
                            NpcReply(-1, "slow")
                            global:leaveDialog()
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9730"] = {
                    displayInfo = "Étape 1 / 4 -- Lire l'histoire des cra",
                    stepStartMapId = 152043521,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(230)
                            global:leaveDialog()
                        else
                            MoveNext()
                        end
                    end
                },
                ["9738"] = {
                    displayInfo = "Étape 2 / 4 -- Lire l'histoire des dofus",
                    stepStartMapId = 152043521,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(438)
                            global:leaveDialog()
                        else
                            MoveNext()
                        end
                    end
                },
                ["9739"] = {
                    displayInfo = "Étape 3 / 4 -- Regarde la carte du monde des douze",
                    stepStartMapId = 152043521,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(362)
                            global:leaveDialog()
                        else
                            MoveNext()
                        end
                    end
                },
                ["9740"] = {
                    displayInfo = "Étape 4 / 4 -- Parler a Ganymède",
                    stepStartMapId = 152043521,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(24801, "slow")
                            NpcReply(24800)
                            NpcReply(24799)
                        else
                            MoveNext()
                        end
                    end
                }
            }
        },
        ["Le village dans les nuages"] = {
            questId = 1632,
            stepInfo = {
                ["START"] = {
                    displayInfo = "Étape 0 / 7 -- Récupérer la quête",
                    stepStartMapId = 154010883,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            24901,
                            24899,
                            24898,
                            24896,
                            24895,
                            24893,
                            24892
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9762"] = {
                    displayInfo = "Étape 1 / 7 -- Allez voir ternette Nhin",
                    stepStartMapId = 154010371,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            24919,
                            24927,
                            24290
                        }
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)            
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9763"] = {
                    displayInfo = "Étape 2 / 7 -- Allez voir Berb Nhin",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25022,
                            25021,
                            25290
                        }
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9764"] = {
                    displayInfo = "Étape 3 / 7 -- Allez voir Grobid",
                    stepStartMapId = 153357316,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25029,
                            25028,
                            25023
                        }
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20001)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9765"] = {
                    displayInfo = "Étape 4 / 7 -- Aller voir Le capitaine des kerubims",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25044,
                            25043,
                            25038
                        }
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9766"] = {
                    displayInfo = "Étape 5 / 7 -- Allez voir Hollie Brok",
                    stepStartMapId = 153879299,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25098,
                            25097,
                            25096
                        }
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9767"] = {
                    displayInfo = "Étape 6 / 7 -- Aller voir Ternette Nhin",
                    stepStartMapId = 154010371,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            24930,
                            24929,
                            24928
                        }
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9768"] = {
                    displayInfo = "Étape 7 / 7 -- Aller voir Fécaline la sage",
                    stepStartMapId = 153356296,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25108,
                            25107,
                            25106
                        }
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                }         
            }
        },
        ["Espoirs et tragédies"] = {
            questId = 1634,
            requiredFinishedQuest = { 1632 }, 
            stepInfo = {
                ["START"] = {
                    displayInfo = "Étape 0 / 7 -- Récupérer la quête",
                    stepStartMapId = 153356296,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25109,
                            25110
                        }
        
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9772"] = {
                    displayInfo = "Étape 1 / 7 -- Lire le livre de Rykke Errel",
                    stepStartMapId = 153356296,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(426)
                            global:leaveDialog()
                        else
                            MoveNext()
                        end
                    end
                },   
                ["9773"] = {
                    displayInfo = "Étape 2 / 7 -- Parler a Fécaline la sage",
                    stepStartMapId = 153356296,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25113,
                            25112,
                            25111
                        }
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9774"] = {
                    displayInfo = "Étape 3 / 7 -- Parler a un vieux de la vieille",
                    stepStartMapId = 154010883,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            24918,
                            24917,
                            24916,
                            24915,
                            24914,
                            24911,
                            24910,
                            24909,
                            24908
                        }
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                }, 
                ["9775"] = {
                    displayInfo = "Étape 4 / 7 -- Parler a féline pantouflarde",
                    stepStartMapId = 153357316,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20002)
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                        else
                            MoveNext()
                        end
                    end
                }, 
                ["9776"] = {
                    displayInfo = "Étape 5 / 7 -- Parler a un voleur malchanceux",
                    stepStartMapId = 153879809,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                        else
                            MoveNext()
                        end
                    end
                },
                ["9777"] = {
                    displayInfo = "Étape 6 / 6 -- Retourner voir Fécaline la sage",
                    stepStartMapId = 153356296,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25118, "slow")
                            NpcReply(25117, "slow")
                        else
                            MoveNext()
                        end
                    end
                }
            }
        },
        ["Dans la gueule du Milimilou"] = {
            questId = 1635,
            minLevel = 15,
            cantStart = true,
            requiredFinishedQuest = { 1634 }, 
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 7 -- Récupérer la quête",
                    ["EXECUTE"] = function()
                        local possibleIdReply = {
                            25109,
                            25110
                        }
                        local stepStartMapId = 153356296
        
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
    
                ["9783"] = {
                    displayInfo = "Étape 1 / 7 -- ",
                    ["EXECUTE"] = function()
                        local stepStartMapId = 153356296

                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                        else
                            MoveNext()
                        end
                    end
                }
            }
        }, 
        ["Mise à l'épreuve"] = {
            questId = 1642,
            requiredFinishedQuest = { 1632 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25048, "slow")
                            NpcReply(-1)
                            NpcReply(25045)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9828"] = {
                    displayInfo = "Étape 1 / 4 -- Allez voir le Caporal Mynerve",
                    stepStartMapId = 153356292,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
                        local possibleIdReply = {
                            25091,
                            25089,
                            25088
                        }
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9829"] = {
                    displayInfo = "Étape 2 / 4 -- Combat contre le Caporal Mynerve",
                    stepStartMapId = 153356292,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1, "slow")
                            NpcReply(-1)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9830"] = {
                    displayInfo = "Étape 3 / 4 -- Parler au Capitaine Mynerve",
                    stepStartMapId = 153356292,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                        else
                            MoveNext()
                        end
                    end
                },
                ["9831"] = {
                    displayInfo = "Étape 4 / 4 -- Parler au Capitaine des kerubims",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                            NpcReply(-1, "slow")
                        else
                            MoveNext()
                        end
                    end
                }
            }
        },
        ["Champs de bataille"] = {
            questId = 1643,
            requiredFinishedQuest = { 1642 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1, "slow")
                            NpcReply(-1)
                            NpcReply(-1)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9832"] = {
                    displayInfo = "Étape 1 / 5 -- Combattre x1 Tofu chimérique",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 970, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                    end
                },
                ["9833"] = {
                    displayInfo = "Étape 2 / 5 -- Combattre x1 Pissenlit Miroitant",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 979, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                    end
                },
                ["9834"] = {
                    displayInfo = "Étape 3 / 5 -- Combattre x1 Rose Vaporeuse",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 980, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                    end
                },
                ["9835"] = {
                    displayInfo = "Étape 4 / 5 -- Combattre x1 Tournesol Nébuleux",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 981, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)                    
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                    end
                },
                ["9836"] = {
                    displayInfo = "Étape 5 / 5 -- Retourner voir le Capitaine des Kerubims",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25061, "slow")
                            global:leaveDialog()
                        else
                            MoveNext()
                        end
                    end   
                },
            }
        },
        ["Coup d'épée dans l'eau"] = {
            questId = 1644,
            requiredFinishedQuest = { 1643 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25061, "slow")
                            NpcReply(25060)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9837"] = {
                    displayInfo = "Étape 1 / 4 -- Combattre x2 Petit Gloot",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 4109, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Lac"))
                    end
                },
                ["9838"] = {
                    displayInfo = "Étape 2 / 4 -- Combattre x2 Plikplok",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 4108, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Lac"))
                    end            
                },
                ["9839"] = {
                    displayInfo = "Étape 3 / 4 -- Combattre x1 Grand Splatch",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 4110, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Lac"))
                    end
                },
                ["9840"] = {
                    displayInfo = "Étape 4 / 4 -- Retourner voir le Capitaine des Kerubims",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25063, "slow")
                            global:leaveDialog()
                        else
                            MoveNext()
                        end
                    end   
                }
            }
        },
        ["Décime-moi des bouftous"] = {
            questId = 1645,
            requiredFinishedQuest = { 1644 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25063, "slow")
                            NpcReply(25062)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9841"] = {
                    displayInfo = "Étape 1 / 5 -- Combattre x1 Boufton Pâlichon",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 972, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Pâturages"))
                    end
                },
                ["9842"] = {
                    displayInfo = "Étape 2 / 5 -- Combattre x1 Boufton Orageux",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 973, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Pâturages"))
                    end            
                },
                ["9843"] = {
                    displayInfo = "Étape 3 / 5 -- Combattre x1 Bouftou Nuageux",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 971, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Pâturages"))
                    end
                },
                ["9844"] = {
                    displayInfo = "Étape 3 / 5 -- Combattre x1 Bouftor Éthéré",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 984, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Pâturages"))
                    end
                },  
                ["9845"] = {
                    displayInfo = "Étape 5 / 5 -- Retourner voir le Capitaine des Kerubims",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25065, "slow")
                        else
                            MoveNext()
                        end
                    end   
                }      
            }
        },
        ["Chasse aux chapardams"] = {
            questId = 1646,
            requiredFinishedQuest = { 1645 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25065, "slow")
                            NpcReply(25064)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9846"] = {
                    displayInfo = "Étape 1 / 4 -- Combattre x2 Ronronchon",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 4105, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                    end
                },
                ["9847"] = {
                    displayInfo = "Étape 2 / 4 -- Combattre x2 Tigrimas",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 4106, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                    end            
                },
                ["9848"] = {
                    displayInfo = "Étape 3 / 4 -- Combattre x2 Chakrobat",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 982, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                    end
                },
                ["9849"] = {
                    displayInfo = "Étape 4 / 4 -- Retourner voir le Capitaine des Kerubims",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(-1, "slow")
                        else
                            MoveNext()
                        end
                    end   
                }      
            }
        },
        ["Leçon d'humilité"] = {
            questId = 1647,
            requiredFinishedQuest = { 1646 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 2 -- Récupérer la quête",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25067, "slow")
                            NpcReply(25066)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9850"] = {
                    displayInfo = "Étape 1 / 2 -- Combattre Kruella Freuz",
                    stepStartMapId = 153879040,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25082, "slow")
                        else
                            MoveNext()
                        end
                    end
                },
                ["9851"] = {
                    displayInfo = "Étape 2 / 2 -- Retourner voir le Capitaine des Kerubims",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25071, "slow")
                        else
                            MoveNext()
                        end
                    end            
                }
            }
        },
        ["Des chafers qui marchent"] = {
            questId = 1648,
            requiredFinishedQuest = { 1647 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 8 -- Récupérer la quête",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25071,
                            25070,
                            25069,
                            25068
                        }
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9852"] = {
                    displayInfo = "Étape 1 / 8 -- Combattre x1 Chafer débutant",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 4046, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Cimetière"))
                    end
                },
                ["9853"] = {
                    displayInfo = "Étape 2 / 8 -- Combattre x1 Chafer furtif",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 4047, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Cimetière"))
                    end
                },  
                ["9854"] = {
                    displayInfo = "Étape 3 / 8 -- Combattre x1 Chafer éclaireur",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 2,
                            conf = {
                                { idMonster = 4048, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Cimetière"))
                    end
                }, 
                ["9855"] = {
                    displayInfo = "Étape 4 / 8 -- Combattre x1 Chafer Piquier",
                    ["EXECUTE"] = function()
                        local confMonster = {
                            minMonster = 1,
                            maxMonster = 3,
                            conf = {
                                { idMonster = 4049, min = 1, max = 8 }
                            }
                        }

                        Fight(confMonster)
                        RoadZone(Get_TblZoneSubArea("Incarnam", "Cimetière"))
                    end
                }, 
                ["9856"] = {
                    displayInfo = "Étape 5 / 8 -- Découvrir la carte : Tombeau de Percy Klop",
                    stepStartMapId = 153881090,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then
                            map:door(361)                        
                        else
                            MoveNext()
                        end
                    end
                }, 
                ["9859"] = {
                    displayInfo = "Étape 6 / 8 -- Fouiller la tombe",
                    stepStartMapId = 153356288,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then
                            map:door(343)                        
                        else
                            MoveNext()
                        end
                    end
                },   
                ["9857"] = {
                    displayInfo = "Étape 7 / 8 -- Combattre x1 Percy Klop",
                    stepStartMapId = 153356288,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then
                            NpcDialogRequest(-20000)
                            NpcReply(25086)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9858"] = {
                    displayInfo = "Étape 8 / 8 -- Retourner voir le Capitaine des Kerubims",
                    stepStartMapId = 153356294,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then
                            NpcDialogRequest(-20000)
                            NpcReply(25073)
                        else
                            MoveNext()
                        end
                    end
                }
            }
        },
        ["Transport peu commun"] = {
            questId = 1639,
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 3 -- Récupérer la quête",
                    stepStartMapId = 154010371,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            24936,
                            24935,
                            24934,
                            24933,
                            24932,
                            24931
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9814"] = {
                    displayInfo = "Étape 1 / 3 -- Allez voir Xélora Fistol",
                    stepStartMapId = 153879813,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25020, "slow")
                            NpcReply(25019)
                            NpcReply(25018)
                            NpcReply(25017)
                            NpcReply(25016)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9815"] = {
                    displayInfo = "Étape 2 / 3 -- Examiner le zaap des pâturages",
                    stepStartMapId = 153879813,
                    ["EXECUTE"] = function(stepStartMapId)    
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(509249, -1) 
                        else
                            MoveNext()
                        end                
                    end
                },
                ["9816"] = {
                    displayInfo = "Étape 3 / 3 -- Retourner voir Ternette Nhin",
                    stepStartMapId = 154010371,
                    ["EXECUTE"] = function(stepStartMapId)    
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(24940, "slow")
                            global:leaveDialog()
                        else
                            MoveNext()
                        end                
                    end
                }
            }
        }, 
        ["Des vestiges de légende"] = {
            questId = 1640,
            requiredFinishedQuest = { 1639 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 3 -- Récupérer la quête",
                    stepStartMapId = 154010371,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            24943,
                            24942,
                            24941
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9817"] = {
                    displayInfo = "Étape 1 / 6 -- Examiner la stèle d'un vestige sur la route des âmes",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(485)
                            global:leaveDialog()
                        else
                            MoveNext()
                        end
                    end
                },
                ["9818"] = {
                    displayInfo = "Étape 2 / 6 -- Examiner la stèle d'un vestige des champs",
                    stepStartMapId = 154010886,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(332)
                            global:leaveDialog()                        
                        else
                            MoveNext()
                        end                
                    end
                },
                ["9819"] = {
                    displayInfo = "Étape 3 / 6 -- Examiner la stèle d'un vestige près du lac",
                    stepStartMapId = 154010882,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(471)
                            global:leaveDialog()                        
                        else
                            MoveNext()
                        end                
                    end
                },
                ["9820"] = {
                    displayInfo = "Étape 4 / 6 -- Examiner la stèle d'un vestige dans les pâturages",
                    stepStartMapId = 153879301,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(344)
                            global:leaveDialog()                        
                        else
                            MoveNext()
                        end                
                    end
                },
                ["9821"] = {
                    displayInfo = "Étape 5 / 6 -- Examiner la stèle d'un vestige dans la forêt",
                    stepStartMapId = 153879297,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:door(415)
                            global:leaveDialog()                        
                        else
                            MoveNext()
                        end                
                    end
                },
                ["9822"] = {
                    displayInfo = "Étape 6 / 6 -- Retourner voir Ternette N'hin",
                    stepStartMapId = 154010371,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(24947, "slow")
                        else
                            MoveNext()
                        end
                    end
                }
            }
        }, 
        ["Vu du ciel"] = {
            questId = 1641,
            requiredFinishedQuest = { 1640 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                    stepStartMapId = 154010371,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            24950,
                            24949,
                            24948
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9823"] = {
                    displayInfo = "Étape 1 / 5 -- Allez voir Matu Vuh",
                    stepStartMapId = 154010374,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(24957, "slow")
                            NpcReply(24956)
                        else
                            MoveNext()
                        end
                    end
                },
                ["9824"] = {
                    displayInfo = "Étape 2 / 5 -- Utiliser la longue vue de Matu Vuh",
                    stepStartMapId = 154010374,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489417, -1)
                            global:leaveDialog()                   
                        else
                            MoveNext()
                        end
                    end
                },
                ["9825"] = {
                    displayInfo = "Étape 3 / 5 -- Allez voir galilea",
                    stepStartMapId = 154010113,
                    ["EXECUTE"] = function(stepStartMapId)    
                        LoadRoadIfNotInMap(stepStartMapId)
    
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(24963)
                            NpcReply(24962)
                        elseif map:currentMapId() == 154010369 then
                            map:changeMap("left") 
                        elseif map:currentMapId() == 154010881 then
                            map:changeMap("bottom")                   
                    
                        else
                            map:moveToward(154010113)
                        end                
                    end
                },
                ["9826"] = {
                    displayInfo = "Étape 4 / 5 -- Utiliser la longue vue de Galilea",
                    stepStartMapId = 154010113,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489418, -1)
                            global:leaveDialog()                   
                        else
                            MoveNext()
                        end
                    end
                }, 
                ["9827"] = {
                    displayInfo = "Étape 5 / 5 -- Retourner voir Ternette Nhin",
                    stepStartMapId = 154010371,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(24952)
                        else
                            MoveNext()
                        end
                    end
                }
            }
        },
        ["Produits naturels"] = {
            questId = 1649,
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25298,
                            25306,
                            25304,
                            25303,
                            25302,
                            25301
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9863"] = {
                    displayInfo = "Étape 1 / 5 -- Fabriquer x1 Pain d'Incarnam",
                    stepStartMapId = 153354242,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(289) < 4 then
                            GATHER = {38}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489524, -1)
                                craft:putItem(289, 4)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end

                    end
                },
                ["9864"] = {
                    displayInfo = "Étape 2 / 5 -- Fabriquer x1 Goujon en tranche",
                    stepStartMapId = 153354246,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(1782) < 4 then
                            GATHER = {75}
                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Lac"))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489364, -1)
                                craft:putItem(1782, 4)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end
                    end
                },
                ["9866"] = {
                    displayInfo = "Étape 3 / 5 -- Fabriquer x1 Potion de mini soin",
                    stepStartMapId = 153355270,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(421) < 4 then
                            GATHER = {254}
                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", {"Forêt", "Lac", "Pâturages", "Route des âmes", "Champs"}))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489066, -1)
                                craft:putItem(421, 4)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end
                    end
                },
                ["FINISH"] = {
                    displayInfo = "Étape 4 / 4 -- Retourner voir Berb N'hin",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)

                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25311)
                        else
                            MoveNext()
                        end    
                    end
                }
            }
        }, 
        ["La hache et la pioche"] = {
            questId = 1650,
            requiredFinishedQuest = { 1649 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 3 -- Récupérer la quête",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25312,
                            25314,
                            25313,
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9871"] = {
                    displayInfo = "Étape 1 / 3 -- Fabriquer x1 Planche Agglomérée",
                    stepStartMapId = 153355266,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(303) < 6 then -- Frêne
                            GATHER = {1}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                        elseif inventory:itemCount(312) < 4 then -- Fer
                            GATHER = {17}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Mine"))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489534, -1)
                                craft:putItem(303, 6)
                                craft:putItem(312, 4)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end

                    end
                },
                ["9872"] = {
                    displayInfo = "Étape 2 / 3 -- Fabriquer x1 Ferrite",
                    stepStartMapId = 153355264,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(303) < 10 then -- Frêne
                            GATHER = {1}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                        elseif inventory:itemCount(312) < 6 then -- Fer
                            GATHER = {17}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Mine"))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489176, -1)
                                craft:putItem(303, 10)
                                craft:putItem(312, 6)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end                
                    end
                },
                ["FINISH"] = {
                    displayInfo = "Étape 3 / 3 -- Retourner voir Berb N'hin",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)

                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25320)
                        else
                            MoveNext()
                        end    
                    end
                }
            }
        },
        ["Boune un jour, boune toujours"] = {
            questId = 1651,
            requiredFinishedQuest = { 1650 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 7 -- Récupérer la quête",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25322,
                            25326,
                            25325,
                            25324,
                            25323
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9875"] = {
                    displayInfo = "Étape 1 / 7 -- Fabriquer x1 Le S'Mesme",
                    stepStartMapId = 153355272,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(16512) < 2 then -- Plume chimérique
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 2,
                                conf = {
                                    { idMonster = 970, min = 1, max = 8 }
                                }
                            }
        
                            Fight(confMonster)
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))
                        elseif inventory:itemCount(303) < 2 then -- Frêne
                            GATHER = {1}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489550, -1)
                                craft:putItem(16512, 2)
                                craft:putItem(303, 2)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end

                    end
                },
                ["9877"] = {
                    displayInfo = "Étape 2 / 7 -- Fabriquer x1 Le Plussain",
                    stepStartMapId = 153355272,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(16518) < 2 then -- Feu Intérieur
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}
                            } 

                            if InMapChecker(Get_TblZoneSubArea("Incarnam", "Route des âmes")) then
                                Fight(confMonster)
                            end                        
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Route des âmes"))                    
                        elseif inventory:itemCount(312) < 1 then -- Fer
                            GATHER = {17}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Mine"))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489550, -1)
                                craft:putItem(16518, 2)
                                craft:putItem(312, 1)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end                
                    end
                },
                ["9878"] = {
                    displayInfo = "Étape 3 / 7 -- Fabriquer x1 Les Incrustes",
                    stepStartMapId = 153354244,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(16513) < 2 then -- Pétale Diaphane
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {
                                    { idMonster = 970, min = 0, max = 0 }
                                }                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        elseif inventory:itemCount(303) < 2 then -- Frêne
                            GATHER = {1}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Forêt"))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489570, -1)
                                craft:putItem(16513, 2)
                                craft:putItem(303, 2)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end                 
                    end
                },
                ["9879"] = {
                    displayInfo = "Étape 4 / 7 -- Fabriquer x1 La Spamette",
                    stepStartMapId = 153354244,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(16522) < 2 then -- Peau de gloot
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Lac")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        elseif inventory:itemCount(421) < 2 then -- Ortie
                            GATHER = {254}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", {"Forêt", "Lac", "Pâturages", "Route des âmes", "Champs"}))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489570, -1)
                                craft:putItem(16522, 2)
                                craft:putItem(421, 2)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end                 
                    end
                },
                ["9880"] = {
                    displayInfo = "Étape 5 / 7 -- Fabriquer x1 La Cape S'loque",
                    stepStartMapId = 153354244,
                    ["EXECUTE"] = function(stepStartMapId)

                        if inventory:itemCount(1984) < 2 then -- Cendres éternelles
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Route des âmes")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        elseif inventory:itemCount(312) < 1 then -- Fer
                            GATHER = {17}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Mine"))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489571, -1)
                                craft:putItem(1984, 2)
                                craft:putItem(312, 1)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end                
                    end
                },
                ["9881"] = {
                    displayInfo = "Étape 6 / 7 -- Fabriquer x1 Le Floude",
                    stepStartMapId = 153354244,
                    ["EXECUTE"] = function(stepStartMapId)

                        if inventory:itemCount(16511) < 2 then -- Laine céleste
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Pâturages")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        elseif inventory:itemCount(421) < 2 then -- Ortie
                            GATHER = {254}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", {"Forêt", "Lac", "Pâturages", "Route des âmes", "Champs"}))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489571, -1)
                                craft:putItem(16511, 2)
                                craft:putItem(421, 2)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end                  
                    end
                },
                ["FINISH"] = {
                    displayInfo = "Étape 7 / 7 -- Retourner voir Berb N'hin",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)

                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25330)
                        else
                            MoveNext()
                        end    
                    end
                }
            }
        }, 
        ["Le choix des armes"] = {
            questId = 1652,
            requiredFinishedQuest = { 1651 },
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25333,
                            25336,
                            25335,
                            25334
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9888"] = {
                    displayInfo = "Étape 1 / 4 -- Fabriquer x1 Demi-Baguette",
                    stepStartMapId = 153355266,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(16513) < 3 then -- Pétale Diaphane
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {
                                    { idMonster = 970, min = 0, max = 0 }
                                }                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        elseif inventory:itemCount(16511) < 3 then -- Laine céleste
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Pâturages")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489533, -1)
                                craft:putItem(16513, 3)
                                craft:putItem(16511, 3)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end
                    end
                },
                ["9889"] = {
                    displayInfo = "Étape 2 / 4 -- Fabriquer x1 Hachette de bûcheron",
                    stepStartMapId = 153355264,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(16511) < 5 then -- Laine céleste
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Pâturages")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        elseif inventory:itemCount(312) < 1 then -- Fer
                            GATHER = {17}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Mine"))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489177, -1)
                                craft:putItem(16511, 5)
                                craft:putItem(312, 1)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end                  
                    end
                },
                ["9890"] = {
                    displayInfo = "Étape 3 / 4 -- Fabriquer x1 Clef de la crypte de kardorim",
                    stepStartMapId = 153354248,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(16524) < 3 then -- Relique d'incarnam
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Cimetière")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        elseif inventory:itemCount(1984) < 5 then -- Cendre éternelles
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Route des âmes")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(490183, -1)
                                craft:putItem(16524, 3)
                                craft:putItem(1984, 5)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end
                    end
                },
                ["FINISH"] = {
                    displayInfo = "Étape 4 / 4 -- Retourner voir Berb N'hin",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25337)
                            NpcReply(25341)
                        else
                            MoveNext()
                        end    
                    end
                }
            }
        },
        ["La galette secrète"] = {
            questId = 1637,
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 5 -- Récupérer la quête",
                    stepStartMapId = 153879298,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25216,
                            25214,
                            25213,
                            25212
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9805"] = {
                    displayInfo = "Étape 1 / 5 -- Lire la recette de la galette d'Incarnam",
                    ["EXECUTE"] = function()
                        inventory:useItem(16517)
                        global:leaveDialog()
                    end
                },
                ["9806"] = {
                    displayInfo = "Étape 2 / 5 -- Fabriquer x1 Galette d'Incarnam",
                    stepStartMapId = 153354242,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(289) < 10 then -- Blé
                            GATHER = {38}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", "Champs"))

                        elseif inventory:itemCount(519) < 4 then -- Poudre de perlinpainpain
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)

                        elseif inventory:itemCount(367) < 2 then -- Oeufs de tofu
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Champs")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {
                                    { idMonster = 970, min = 1, max = 8 }
                                }                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)
                        elseif inventory:itemCount(6765) < 1 then -- LaitLait
                            LoadRoadIfNotInMap(153357316)

                            if map:currentMapId() == 153357316 then
                                NpcDialogRequest(-20001)
                                NpcReply(25036)
                                NpcReply(25035)
                            else
                                MoveNext()
                            end
                        elseif inventory:itemCount(1984) < 4 then -- Cendres éternelles
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Route des âmes")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)
                        elseif inventory:itemCount(385) < 4 then -- Bave de bouftout
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Paturâges")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)

                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489524, -1)
                                craft:putItem(289, 10)
                                craft:putItem(519, 4)
                                craft:putItem(367, 2)
                                craft:putItem(6765, 1)
                                craft:putItem(1984, 4)
                                craft:putItem(385, 4)
                                craft:ready()
                                global:leaveDialog()
                            else
                                MoveNext()
                            end    
                        end                  
                    end
                },
                ["9807"] = {
                    displayInfo = "Étape 3 / 5 -- Retourner voir AntaBrok",
                    stepStartMapId = 153879298,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25218)
                            NpcReply(25217)
                        else
                            MoveNext()
                        end    
                    end
                },
                ["9808"] = {
                    displayInfo = "Étape 4 / 5 -- Allez voir Pipelette",
                    stepStartMapId = 153879811,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(421) < 5 then -- Ortie
                            GATHER = {254}

                            Gather()
                            RoadZone(Get_TblZoneSubArea("Incarnam", {"Forêt", "Lac", "Pâturages", "Route des âmes", "Champs"}))
                        else
                            LoadRoadIfNotInMap(stepStartMapId)

                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                NpcDialogRequest(-20002)
                                NpcReply(25229)
                                NpcReply(25228)
                                NpcReply(25227)
                                NpcReply(25226)
                            else
                                MoveNext()
                            end 
                        end   
                    end
                },
                ["FINISH"] = {
                    displayInfo = "Étape 5 / 5 -- Montrer à Anta Brok 1 Pot de confiture Maison",
                    stepStartMapId = 153879298,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25224,
                            25221,
                            25220,
                            25219
                        }

                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end    
                    end
                }
            }
        },
        ["Mort au rat !"] = {
            questId = 1633,
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 4 -- Récupérer la quête",
                    stepStartMapId = 153878787,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489412, -1)
                            PacketSender("QuestStartRequestMessage", function(msg)
                                msg.questId = 1633
                                return msg
                            end)
                            developer:suspendScriptUntil("QuestStartedMessage", 1000, false)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9895"] = {
                    displayInfo = "Étape 1 / 4 -- Inspecter la cave",
                    stepStartMapId = 153358340,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            map:useById(489505, -1)                     
                        else
                            MoveNext()
                        end                
                    end
                },
                ["9769"] = {
                    displayInfo = "Étape 2 / 4 -- Faire sortir le rat de sa cachette",
                    stepStartMapId = 153358340,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(8543) < 1 then -- Limonade d'incarnam
                            LoadRoadIfNotInMap(153357316)

                            if map:currentMapId() == 153357316 then
                                NpcDialogRequest(-20001)
                                NpcReply(25036)
                                NpcReply(25034)
                            else
                                MoveNext()
                            end

                        else
                            LoadRoadIfNotInMap(stepStartMapId)
                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                map:useById(489505, -1)                     
                            else
                                MoveNext()
                            end    
                        end                  
                    end
                },
                ["9770"] = {
                    displayInfo = "Étape 3 / 4 -- Vaincre x1 Rat Soiffé",
                    stepStartMapId = 153358340,
                    ["EXECUTE"] = function(stepStartMapId)
                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            NpcReply(25037)
                        else
                            MoveNext()
                        end    
                    end
                },
                ["FINISH"] = {
                    displayInfo = "Étape 4 / 4 -- Allez voir Grobid",
                    stepStartMapId = 153357316,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25033,
                            25032
                        }

                        LoadRoadIfNotInMap(stepStartMapId)

                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20001)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end    
                    end
                }
            }
        },
        ["Cryptologie"] = {
            questId = 1638,
            minLevel = 12,
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 3 -- Récupérer la quête",
                    stepStartMapId = 153881600,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            24973,
                            24970,
                            24971
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end
                    end   
                }, 
                ["9811"] = {
                    displayInfo = "Étape 1 / 3 -- Découvrir la carte : Salle du tombeau de kardorim",
                    stepStartMapId = 153881600,
                    ["EXECUTE"] = function(stepStartMapId)       
                        if not InMapChecker(Get_TblZoneSubArea("Incarnam", "Crypte de Kardorim")) then
                            local possibleIdReply = {
                                24967,
                                24966,
                                24973,
                                24970,
                                24968,
                                24971
                            }

                            LoadRoadIfNotInMap(stepStartMapId)

                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                NpcDialogRequest(-20000)
                                ReplyUntilLeave(possibleIdReply)
                            else
                                MoveNext()
                            end  
                        else
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 8,
                                conf = {}                        
                            }

                            if #MAP_DATA_MONSTERS < 1 then
                                PacketSender("MapInformationsRequestMessage", function(msg)
                                    msg.mapId = map:currentMapId()
                                    return msg
                                end)
                            end

                            Fight(confMonster)
                        end              
                    end
                },
                ["9812"] = {
                    displayInfo = "Étape 2 / 3 -- Vaincre x1 Kardorim",
                    stepStartMapId = 153881600,
                    ["EXECUTE"] = function(stepStartMapId)
                        if not InMapChecker(Get_TblZoneSubArea("Incarnam", "Crypte de Kardorim")) then
                            local possibleIdReply = {
                                24967,
                                24966,
                                24973,
                                24970,
                                24968,
                                24971
                            }

                            LoadRoadIfNotInMap(stepStartMapId)

                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                NpcDialogRequest(-20000)
                                ReplyUntilLeave(possibleIdReply)
                            else
                                MoveNext()
                            end  
                        else
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 8,
                                conf = {}                        
                            } 

                            if #MAP_DATA_MONSTERS < 1 then
                                PacketSender("MapInformationsRequestMessage", function(msg)
                                    msg.mapId = map:currentMapId()
                                    return msg
                                end)
                            end

                            Fight(confMonster)
                        end                     
                    end
                },
                ["FINISH"] = {
                    displayInfo = "Étape 3 / 3 -- Allez voir Kardorim",
                    stepStartMapId = 152835072,
                    ["EXECUTE"] = function(stepStartMapId)
                        if not InMapChecker(Get_TblZoneSubArea("Incarnam", "Crypte de Kardorim")) then
                            local possibleIdReply = {
                                24967,
                                24966,
                                24973,
                                24970,
                                24968,
                                24971
                            }

                            LoadRoadIfNotInMap(stepStartMapId)

                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                NpcDialogRequest(-20000)
                                ReplyUntilLeave(possibleIdReply)
                            else
                                MoveNext()
                            end  
                        elseif map:currentMapId() ~= stepStartMapId then
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 8,
                                conf = {}                        
                            } 

                            if #MAP_DATA_MONSTERS < 1 then
                                PacketSender("MapInformationsRequestMessage", function(msg)
                                    msg.mapId = map:currentMapId()
                                    return msg
                                end)
                            end

                            Fight(confMonster)
                        elseif map:currentMapId() == stepStartMapId then
                            NpcDialogRequest(-20000)
                            NpcReply(24993)
                            NpcReply(24992)
                            NpcReply(25000)
                        end                     
                    end
                }
            }
        },
        ["Un peu de pigment"] = {
            questId = 1655,
            stepInfo = { 
                ["START"] = {
                    displayInfo = "Étape 0 / 1 -- Récupérer la quête",
                    stepStartMapId = 153880325,
                    ["EXECUTE"] = function(stepStartMapId)
                        local possibleIdReply = {
                            25487,
                            25486,
                            25485
                        }

                        LoadRoadIfNotInMap(stepStartMapId)
        
                        if map:currentMapId() == stepStartMapId then -- Execution étape
                            NpcDialogRequest(-20000)
                            ReplyUntilLeave(possibleIdReply)
                        else
                            MoveNext()
                        end                    
                    end   
                }, 
                ["FINISH"] = {
                    displayInfo = "Étape 1 / 1 -- Ramener à Marylock : x3 Poudre d'Aminite",
                    stepStartMapId = 153880325,
                    ["EXECUTE"] = function(stepStartMapId)
                        if inventory:itemCount(16999) < 3 then -- Relique d'incarnam
                            local tblMapId = Get_TblZoneSubArea("Incarnam", "Mine")
                            local confMonster = {
                                minMonster = 1,
                                maxMonster = 4,
                                conf = {}                        
                            } 

                            if InMapChecker(tblMapId) then
                                Fight(confMonster)
                            end                        
                            RoadZone(tblMapId)                    
                        else
                            LoadRoadIfNotInMap(stepStartMapId)

                            if map:currentMapId() == stepStartMapId then -- Execution étape
                                NpcDialogRequest(-20000)
                                NpcReply(25489)                
                            else
                                MoveNext()
                            end         
                        end       
                    end
                }
            }
        },
    }

    ZONE_AREA_MAPID = {
        ["Incarnam"] = {
            ["Route des âmes"] = {
                154010883,
                154010371,
                153878787,
                153879299,
                153879811,
                153880323,
                153880835
            },
            ["Pâturages"] = {
                153879301,
                153879813,
                153880325,
                153880836,
                153880324,
                153879812,
                153879300
            },
            ["Champs"] = {
                153878788,
                154010372,
                154010884,
                154010885,
                154011397,
                154011398,
                154010886,
                154010374,
                154010373
            },
            ["Lac"] = {
                153878786,
                153878785,
                153878528,
                153878529,
                154010113,
                154010112,
                154010624,
                154010881,
                154010369,
                154010882,
                154010370
            },
            ["Forêt"] = {
                153879298,
                153879297,
                153879040,
                153879552,
                153879809,
                153879810,
                153880322,
                153880321
            },
            ["Cimetière"] = {
                153881090,
                153880578,
                153881089,
                153881601,
                153881600,
                153881088
            },
            ["Mine"] = {
                153358338,
                153358336,
                153357314,
                153357312
            },
            ["Crypte de Kardorim"] = {
                152829952,
                152830976,
                152832000,
                152833024,
                152834048,
                152835072
            }
        },
        ["Astrub"] = {
            ["Cité d'Astrub"] = {
                188746756,
                188746755,
                188746754,
                188746753,
                188746241,
                188746242,
                188745730,
                188745729,
                188745217,
                188745218,
                188744706,
                188744705,
                188744193,
                188744194,
                188743681,
                188743682,
                188743683,
                188744195,
                188744196,
                188743684,
                188743685,
                188744197,
                188744198,
                188743686,
                188743687,
                188744199,
                188744198,
                188744710,
                188744711,
                188745223,
                188745222,
                188745734,
                188745735,
                188746247,
                188746246,
                188746759,
                188746758,
                188746757,
                191106050,
                191106048,
                191105024,
                191104000,
                191102976,
                191102978,
                191102980,
                191104004,
                191105028,
                191106052,
                191105026,
                191104002
            }
        }
    }