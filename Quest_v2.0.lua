-- Var

Packet = {}
Movement = {}
Quest = {}
Dialog = {}
Utils = {}
Error = {}

-- Ankabot var

MIN_MONSTERS = 1
MAX_MONSTERS = 8

FORBIDDEN_MONSTERS = {}
FORCE_MONSTERS = {}

-- Ankabot Main

function move()
    Quest:QuestManager()
end

function bank()

end

function stopped()
    Packet:PacketManager("quest", false)

end

-- Quest

Quest.QuestSolution = {}
Quest.CurrentQuestToDo = {}
Quest.CurrentStepToDo = {}
Quest.HistoricalQuestList = {}

Quest.Init = false

Quest.SelectedQuestToDo = false
Quest.SelectedStepToDo = false

Quest.StepInfoShowing = false

Quest.StepValidated = false
Quest.QuestValidated = false

function Quest:QuestManager()

    if not self.Init then -- Initialisation
        Packet:PacketManager("quest") -- Abonnement au packet
        Packet:PacketManager("dialog") -- Abonnement au packet
        self:LoadHistoricalQuest() -- Charge les quête déja faite
        self.Init = true
    end

    developer:suspendScriptUntilMultiplePackets({"QuestStepInfoMessage", "QuestObjectiveValidatedMessage", "QuestValidatedMessage", "QuestStartedMessage"}, 200, false)

    if self.QuestValidated then
        Utils:Print("Quête terminée -- "..self.CurrentQuestToDo.name, "Quête")
        table.insert(self.HistoricalQuestList.FinishedQuestsIds, self.CurrentQuestToDo.questId)
        self.SelectedQuestToDo = false
        self.SelectedStepToDo = false
        self.StepValidated = false
        self.QuestValidated = false
        self.CurrentQuestToDo = {}
        self.CurrentStepToDo = {}
        global:leaveDialog()
    end

    if not self.SelectedQuestToDo then -- Séléctionne une quête a faire
        self.CurrentQuestToDo = self:SelectQuestToDo()

        if Utils:LenghtOfTable(self.CurrentQuestToDo) == 0 then
            Error:ErrorManager("Aucune quête séléctionner !", "QuestManager")
        else
            self.SelectedQuestToDo = true
        end
    end

    self:StepManager()
end

function Quest:StepManager()
    --Utils:Print("StepManager")

    if not self.SelectedStepToDo then -- Séléction de l'étape
        self.StepInfoShowing = false
        --Utils:Print("selectStep")

        self.CurrentStepToDo = self:SelectStepToDo()

        --Utils:Print("step selected")

        if Utils:LenghtOfTable(self.CurrentStepToDo) == 0 then
            Error:ErrorManager("Aucun step trouvé !", "QuestManager")
        else
            self.SelectedStepToDo = true
        end
    end

    if self.CurrentStepToDo.EXECUTE ~= nil and not self.StepValidated then

        if not self.StepInfoShowing then -- Affichage des info du step
            Utils:Print(self.CurrentStepToDo.displayInfo, "étape")
            self.StepInfoShowing = true
        end

        developer:suspendScriptUntilMultiplePackets({"QuestStepInfoMessage", "QuestObjectiveValidatedMessage", "QuestValidatedMessage"}, 0, false)

        if self.CurrentStepToDo.stepStartMapId ~= nil then
            Movement:LoadRoad(self.CurrentStepToDo.stepStartMapId)

            if self.CurrentStepToDo.stepStartMapId == map:currentMapId() and not self.StepValidated then
                self.CurrentStepToDo.EXECUTE() -- Éxécution de l'étape
            elseif self.CurrentStepToDo.stepStartMapId ~= map:currentMapId() then -- Déplacement jusqu'a la carte du step
                Movement:MoveNext()
            end
        else
            self.CurrentStepToDo.EXECUTE() -- Éxécution de l'étape
        end
    end

    developer:suspendScriptUntilMultiplePackets({"QuestStepInfoMessage", "QuestObjectiveValidatedMessage", "QuestValidatedMessage", "QuestStartedMessage"}, 200, false)

    if self.StepValidated and not self.QuestValidated then
        Utils:Print("Étape terminée -- "..self.CurrentStepToDo.displayInfo, "Étape")
        self.SelectedStepToDo = false
        self.StepValidated = false
        self:EditQuestObjecttives(self.CurrentQuestToDo.questId, self.CurrentStepToDo.stepId, false)
        self.CurrentStepToDo = {}
        global:leaveDialog()
    end

    self:QuestManager()
end

function Quest:LoadHistoricalQuest()
    if Utils:LenghtOfTable(self.HistoricalQuestList) == 0 then
        local packet = developer:historicalMessage("QuestListMessage")
        self.HistoricalQuestList.ActiveQuests = packet[1].activeQuests
        self.HistoricalQuestList.FinishedQuestsIds = packet[1].finishedQuestsIds
        self.HistoricalQuestList.FinishedQuestsCounts = packet[1].finishedQuestsCounts
        self.HistoricalQuestList.ReinitDoneQuestsIds = packet[1].reinitDoneQuestsIds
    end
end

function Quest:SelectQuestToDo()
    for kQuestName, vQuestSolution in pairs(self.QuestSolution) do
        if not self:CheckIfQuestFinish(vQuestSolution.questId) and not self:CheckIfRequiredFinishedQuest(vQuestSolution.requiredFinishedQuest) then
            local canSelect = true

            if vQuestSolution.minLevel ~= nil then
                if character:level() < vQuestSolution.minLevel then
                    canSelect = false
                end
            end

            if vQuestSolution.cantStart then
                canSelect = false
            end

            if canSelect then
                Utils:Print("Quête "..kQuestName.." séléctionné ", "quête")
                vQuestSolution.name = kQuestName
                return vQuestSolution
            end
        else
            Utils:Print("La quête "..kQuestName.. " est fini", "quête")
        end
    end
    return nil
end

function Quest:SelectStepToDo()
    local stepId = self:GetCurrentStep()

    if stepId ~= nil then
        for kStepId, vStep in pairs(self.CurrentQuestToDo.stepSolution) do
            if Utils:Equal(tostring(kStepId), tostring(stepId)) then
                vStep.stepId = kStepId
                --Utils:Print("select  "..vStep.stepId)
                return vStep
            end
        end
    else
        if not self:CheckIfQuestLaunched(self.CurrentQuestToDo.questId) then
            if self.CurrentQuestToDo.stepSolution.START ~= nil then
                return self.CurrentQuestToDo.stepSolution.START
            else
                Utils:Print("Pas de step START sur la quête "..self.CurrentQuestToDo.name, "SelectStep", "error")
            end
        else
            if self.CurrentQuestToDo.stepSolution.FINISH ~= nil then
                return self.CurrentQuestToDo.stepSolution.FINISH
            else
                Utils:Print("Pas de step FINISH sur la quête "..self.CurrentQuestToDo.name, "SelectStep", "error")
            end
        end
    end
end

function Quest:GetCurrentStep()
    if self.HistoricalQuestList.ActiveQuests ~= nil then
        for _, vQuest in pairs(self.HistoricalQuestList.ActiveQuests) do
            if vQuest.questId == self.CurrentQuestToDo.questId then
                if vQuest.objecttives ~= nil then
                    for _, vObjecttives in pairs(vQuest.objecttives) do
                        if vObjecttives.objecttiveStatus then
                            --Utils:Print(vObjecttives.objecttiveId.." getcurrent")
                            if self:CheckIfStepExist(vObjecttives.objecttiveId) then
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

function Quest:CheckIfQuestLaunched(questId)
    if self.HistoricalQuestList.ActiveQuests ~= nil then
        for _, v in pairs(self.HistoricalQuestList.ActiveQuests) do
            if v.questId == questId then
                return true
            end
        end
    end
    return false
end

function Quest:CheckIfQuestFinish(questId)
    if self.HistoricalQuestList.FinishedQuestsIds ~= nil then
        for _, v in pairs(self.HistoricalQuestList.FinishedQuestsIds) do
            if v == questId then
                return true
            end
        end
    end
    return false
end

function Quest:CheckIfRequiredFinishedQuest(requiredFinishedQuest)
    if requiredFinishedQuest ~= nil then -- Verifie si une quête est requis, si oui verifie si elle terminée
        for _, questId in pairs(requiredFinishedQuest) do
            if not self:CheckIfQuestFinish(questId) then
                return true -- Une quête requis n'est pas fini
            end
        end
    end
    return false
end

function Quest:CheckIfStepExist(stepId)
    for k, _ in pairs(self.CurrentQuestToDo.stepSolution) do
        if Utils:Equal(tostring(k), tostring(stepId)) then
            return true
        end
    end
    Utils:Print("Le step : "..stepId.." n'éxiste pas dans stepSolution pour la quête ("..self.CurrentQuestToDo.name..")", "quête", "error")
    return false
end

function Quest:AddActiveQuest(questId, objecttives)
    local vQuest = {}
    vQuest.questId = questId
    vQuest.objecttives = objecttives or nil
    table.insert(self.HistoricalQuestList.ActiveQuests, vQuest)
end

function Quest:EditQuestObjecttives(questId, stepId, val)
    for _, vQuest in pairs(self.HistoricalQuestList.ActiveQuests) do
        local goBreak = false
        if Utils:Equal(vQuest.questId, questId) then
            if vQuest.objecttives ~= nil then
                for _, vObjecttives in pairs(vQuest.objecttives) do
                    --Utils:Print(stepId)
                    --Utils:Print(vObjecttives.objecttiveId)
                    if Utils:Equal(vObjecttives.objecttiveId, stepId) then
                        --Utils:Print("equal")
                        vObjecttives.objecttiveStatus = val
                        goBreak = true
                        break
                    end
                end
            end
        end
        if goBreak then
            break
        end
    end
end

-- Packet

function Packet:PacketManager(pType, register)
    --Utils:Dump(self.packetToSub)
    for kType, vPacketTbl in pairs(self.packetToSub) do
        if Utils:Equal(kType, pType) then
            --Utils:Dump(vPacketTbl)
            for packetName, callBack in pairs(vPacketTbl) do
                if register or register == nil then -- Abonnement au packet
                    if not developer:isMessageRegistred(packetName) then
                        Utils:Print("Abonnement au packet : "..packetName, "packet")
                        developer:registerMessage(packetName, callBack)
                    end
                else -- Désabonnement des packet
                    if developer:isMessageRegistred(packetName) then
                        Utils:Print("Désabonnement du packet : "..packetName, "packet")
                        developer:unRegisterMessage(packetName)
                    end
                end
            end
        end
    end
end

function Packet:PacketSender(packetName, fn)
    Utils:Print("Envoie du packet "..packetName, "packet")
    local msg = developer:createMessage(packetName)

    if fn ~= nil then
        msg = fn(msg)
    end

    developer:sendMessage(msg)
end

-- Movement

Movement.RoadLoaded = false

Movement.RZNextMapId = -1

function Movement:LoadRoad(mapIdDest)
    local currentMapId = map:currentMapId()
    if currentMapId ~= mapIdDest and not self.RoadLoaded then
        if not map:loadRoadToMapId(mapIdDest) then
            Error:ErrorManager("Impossible de charger un chemin pour le step ("..Quest.CurrentStepToDo.displayInfo..") Quête = ("..Quest.CurrentQuestToDo.name..")", "LoadRoad")
        else
            self.RoadLoaded = true
        end
    elseif currentMapId == mapIdDest then
        self.RoadLoaded = false
    end
end

function Movement:MoveNext()
    map:moveRoadNext()
end

function Movement:RoadZone(tblMapId)
    if tblMapId ~= nil and Utils:LenghtOfTable(tblMapId) > 0 then
        if map:currentMapId() == self.RZNextMapId or self.RZNextMapId == -1 then
            Utils:Print("Get next rand roadMapId")

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

            tblMapIdDist = Utils:ShuffleTbl(tblMapIdDist)

            for _, v in pairs(tblMapIdDist) do
                if v.dist >= math.ceil(maxDist / 1.5) then
                    self.RZNextMapId = v.mapId
                    break
                end
            end

            Utils:Print("Next roadMapId = "..self.RZNextMapId)

            if not map:loadMove(self.RZNextMapId) then
                Utils:Print("Impossible de charger un chemin jusqu'a la mapId : ("..self.RZNextMapId..") changement de map avant re tentative", "RoadZone", "warn")
                --local dir, mapId = Get_RandomNeighbourMapId()
                --map:changeMap(dir)
            end
        end

        self:MoveNext()

        Utils:Print("Apres MoveNext", "RoadZone")
        self.RZNextMapId = -1
    else
        Utils:Print("Table nil", "RoadZone", "error")
    end
end

function Movement:Get_TblZoneArea(area)
    for kArea, vArea in pairs(self.ZoneAreaMapId) do
        if Utils:Equal(kArea, area) then
            return vArea
        end
    end
end

function Movement:Get_TblZoneSubArea(area, subArea)
    if type(subArea) == "string" then
        for kSubArea, vTblMapIdArea in pairs(self:Get_TblZoneArea(area)) do
            if Utils:Equal(kSubArea, subArea) then
                return vTblMapIdArea
            end
        end

    elseif type(subArea) == "table" then
        local zoneArea = self:Get_TblZoneArea(area)
        local retTblMapId = {}

        for _, vSubArea in pairs(subArea) do
            for kSubArea, vTblMapIdArea in pairs(zoneArea) do
                if Utils:Equal(kSubArea, vSubArea) then
                    for _, vMapId in pairs(vTblMapIdArea) do
                        table.insert(retTblMapId, vMapId)
                    end
                    break
                end
            end
        end

        return retTblMapId
    end
end

-- Dialog

Dialog.IsDialog = false

Dialog.CurrentPacketDialog = {}

function Dialog:NpcDialogRequest(npcId)
    if not self.IsDialog then
        Packet:PacketSender("NpcGenericActionRequestMessage", function(msg)
            msg.npcId = npcId
            msg.npcActionId = 3
            msg.npcMapId = map:currentMapId()
            return msg
        end)
    else
        Utils:Print("Un dialog et ouvert avec un NPC", "NpcDialogRequest", "error")
        global:leaveDialog()
        self.IsDialog = false
    end
    developer:suspendScriptUntilMultiplePackets({"NpcDialogCreationMessage", "NpcDialogQuestionMessage"}, 0, false)
end

function Dialog:NpcReplyUntilLeave(tblReplyId)
    while self.IsDialog do
        developer:suspendScriptUntil("NpcDialogQuestionMessage", 0, false)
        --Utils:Print("Try NpcReplyUntilLeave")
        local id

        for _, v in pairs(self.CurrentPacketDialog.visibleReplies) do
            local goBreak = false
            for _, c in pairs(tblReplyId) do
                if v == c then
                    id = v
                    goBreak = true
                    break
                end
            end
            if goBreak then
                break
            end
        end

        if id ~= nil and self.IsDialog then
            self:NpcReply(id)
        else
            --Print("Leave no id")
            self.IsDialog = false
            global:leaveDialog()
        end
    end
end

function Dialog:NpcReply(id, speed)
    developer:suspendScriptUntilMultiplePackets({"NpcDialogCreationMessage", "NpcDialogQuestionMessage"}, 0, false)

    if not Utils:Equal(speed, "ultraFast") then
        local min, max

        if speed == nil then
            min = 492
            max = 728
        elseif Utils:Equal(speed, "slow") then
            min = 621
            max = 1149
        elseif Utils:Equal(speed, "fast") then
            min = 189
            max = 436
        end

        global:delay(global:random(min, max))
    end

    if not self.IsDialog then
        Utils:Print("Dialog not open", "Dialog:NpcReply", "error")
    end

    if id ~= nil and self.IsDialog then
        --packetDialog.visibleReplies = {}
        npc:reply(id)
    end

    developer:suspendScriptUntil("LeaveDialogMessage", 0, false)
end

-- CallBack Quest

function CB_QuestStarted(packet)
    --Utils:Print("Réception packet QuestStarted")
    Quest.StepValidated = true
    Quest:AddActiveQuest(packet.questId)
end

function CB_QuestListMessage(packet)
    --Utils:Print("Réception packet QuestListMessage")
    Quest.HistoricalQuestList.ActiveQuests = packet.activeQuests
    Quest.HistoricalQuestList.FinishedQuestsIds = packet.finishedQuestsIds
    Quest.HistoricalQuestList.FinishedQuestsCounts = packet.finishedQuestsCounts
    Quest.HistoricalQuestList.ReinitDoneQuestsIds = packet.reinitDoneQuestsIds
end

function CB_QuestStepInfo(packet)
    --Utils:Print("Réception packet QuestStepInfo")
    if packet.infos.questId ~= nil then
        for _, vQuest in pairs(Quest.HistoricalQuestList.ActiveQuests) do
            if Utils:Equal(vQuest.questId, packet.infos.questId) then
                --Utils:Print("Objecttives mis a jour")
                vQuest.objecttives = packet.infos.objecttives
                break
            end
        end
    end
end

function CB_QuestObjectiveValidated()
    --Utils:Print("Réception packet stepValidated")
    Quest.StepValidated = true
end

function CB_QuestValidated()
    --Utils:Print("Réception packet QuestValidated")
    Quest.QuestValidated = true
end

-- Callback Dialog

function CB_NpcDialogQuestionMessage(packet)
    Dialog.CurrentPacketDialog = packet
end

function CB_NpcDialogCreationMessage()
    Dialog.IsDialog = true
end

function CB_LeaveDialog()
    Dialog.IsDialog = false
end

Packet.packetToSub = {
    ["Quest"] = {
        ["QuestListMessage"] = CB_QuestListMessage,
        ["QuestStepInfoMessage"] = CB_QuestStepInfo,
        ["QuestObjectiveValidatedMessage"] = CB_QuestObjectiveValidated,
        ["QuestStartedMessage"] = CB_QuestStarted,
        ["QuestValidatedMessage"] = CB_QuestValidated,
    },
    ["Fight"] = {
        ["MapComplementaryInformationsDataMessage"] = CB_MapComplementaryInfoDataMessageFight,
        ["GameRolePlayShowActorMessage"] = CB_ShowActorMessage,
        ["GameContextRemoveElementMessage"] = CB_ContextRemoveElementMessage,
        ["GameMapMovementMessage"] = CB_MapMovementMessage,
    },
    ["Gather"] = {
        ["MapComplementaryInformationsDataMessage"] = CB_MapComplementaryInfoDataMessageGather,
        ["StatedElementUpdatedMessage"] = CB_StatedElementUpdatedMessage,
        ["InteractiveElementUpdatedMessage"] = CB_InteractiveElementUpdatedMessage
    },
    ["Dialog"] = {
        ["NpcDialogCreationMessage"] = CB_NpcDialogCreationMessage,
        ["NpcDialogQuestionMessage"] = CB_NpcDialogQuestionMessage,
        ["LeaveDialogMessage"] = CB_LeaveDialog
    }
}

-- Error

function Error:ErrorManager(msgError, funcName)
    Utils:Print(msgError, funcName, "Error")
    Utils:Print("Arrêt du script", "STOP", "Error")
    global:finishScript()
end

-- Utils

function Utils:Equal(str1, str2)
    if str1 == nil then
        str1 = ""
    end
    if str2 == nil then
        str2 = ""
    end
    return string.lower(tostring(str1)) == string.lower(tostring(str2))
end

function Utils:Print(msg, header, msgType)
    local prefabStr = ""
    msg = tostring(msg)

    if header ~= nil then
        prefabStr = "["..string.upper(header).."] "..msg
    else
        prefabStr = msg
    end

    if msgType == nil then
        global:printSuccess(prefabStr)
    elseif string.lower(msgType) == "warn" then
        global:printMessage("[WARNING]["..header.."] "..msg)
    elseif string.lower(msgType) == "error" then
        global:printError("[ERROR]["..header.."] "..msg)
    end
end

function Utils:Dump(tbl)
    local function dmp(t, l, k)
        if type (t) == "table" then
            self:Print(string.format ("% s% s:", string.rep ("", l * 2 ), tostring (k)))
            for key, v in pairs(t) do
                dmp(v, l + 1, key)
            end
        else
            self:Print(string.format ("% s% s:% s", string.rep ( "", l * 2), tostring (k), tostring (t)))
        end
    end

    dmp(tbl, 1, "root")
end

function Utils:GetTableValue(index, tbl)
    local i = 1
    for _, v in pairs(tbl) do
        if index == i then
            return v
        end
        i = i + 1
    end
end

function Utils:LenghtOfTable(tbl)
    if tbl ~= nil then
        local ret = 0

        for _, _ in pairs(tbl) do
            ret = ret + 1
        end

        return ret
    else
        return 0
    end
end

function Utils:ShuffleTbl(tbl)
    local ret = tbl

    for i = #ret, 2, -1 do
        local j = global:random(1, i)
        ret[i], ret[j] = ret[j], ret[i]
    end

    return ret
end

-- Quest Solution

Quest.QuestSolution["L'anneau de tous les dangers"] = {
    questId = 1629,
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 10 -- Récupérer la quête",
            stepStartMapId = 153092354,
            ["EXECUTE"] = function()
                npc:npc(2897 , 3)
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1)
            end
        },
        ["9655"] = {
            displayInfo = "Étape 1 / 10 -- Monter les éscalier",
            stepStartMapId = 153092354,
            ["EXECUTE"] = function()
                map:door(276)
            end
        },
        ["9656"] = {
            displayInfo = "Étape 2 / 10 -- Parler a maître Hoboulo",
            stepStartMapId = 153093380,
            ["EXECUTE"] = function()
                npc:npc(2895 , 3)
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1)
                Dialog:NpcReply(-1, "fast")
            end
        },
        ["9657"] = {
            displayInfo = "Étape 3 / 10 -- Couper du blé",
            stepStartMapId = 153093380,
            ["EXECUTE"] = function()
                map:door(395)
            end
        },
        ["9658"] = {
            displayInfo = "Étape 4 / 10 -- Cueillir un ortie",
            stepStartMapId = 153093380,
            ["EXECUTE"] = function()
                map:door(258)
            end
        },
        ["9659"] = {
            displayInfo = "Étape 5 / 10 -- Couper du bois",
            stepStartMapId = 153093380,
            ["EXECUTE"] = function()
                map:door(297)
            end
        },
        ["9660"] = {
            displayInfo = "Étape 6 / 10 -- Miner du fer",
            stepStartMapId = 153093380,
            ["EXECUTE"] = function()
                map:door(340)
            end
        },
        ["9661"] = {
            displayInfo = "Étape 7 / 10 -- Pêcher un poisson",
            stepStartMapId = 153093380,
            ["EXECUTE"] = function()
                map:door(303)
            end
        },
        ["9662"] = {
            displayInfo = "Étape 8 / 10 -- Fabriquer l'anneau",
            stepStartMapId = 153093380,
            ["EXECUTE"] = function()
                map:useById(508989, -1)
                craft:putItem(289, 1)
                craft:putItem(303, 1)
                craft:putItem(312, 1)
                craft:putItem(421, 1)
                craft:putItem(1782, 1)
                craft:ready()
                global:leaveDialog()
            end
        },
        ["10015"] = {
            displayInfo = "Étape 9 / 10 -- Parler a maître Hoboulo",
            stepStartMapId = 153093380,
            ["EXECUTE"] = function()
                npc:npc(2895 , 3)
                Dialog:NpcReply(-1, "slow")
            end
        },
        ["9663"] = {
            displayInfo = "Étape 10 / 10 -- Parler a ganymède",
            stepStartMapId = 153092354,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20001)
            end
        }
    }
}

Quest.QuestSolution["Sous le regard des dieux"] = {
    requiredFinishedQuest = { 1629 },
    questId = 1630,
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 6 -- Récupérer la quête",
            stepStartMapId = 153092354,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    24749,
                    24748
                }

                Dialog:NpcDialogRequest(-20001)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9680"] = {
            displayInfo = "Etape 1 / 5 -- Entrer dans la salle de combat",
            stepStartMapId = 153092354,
            ["EXECUTE"] = function()
                map:door(189)
            end
        },
        ["9685"] = {
            displayInfo = "Etape 2 / 5 -- Parler a Maître Dam",
            stepStartMapId = 153092356,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1, 'slow')
                Dialog:NpcReply(-1)
            end
        },
        ["9720"] = {
            displayInfo = "Etape 3 / 5 -- Combattre les deux monstres",
            stepStartMapId = 153092356,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20002)
                Dialog:NpcReply(24793)
            end
        },
        ["10121"] = {
            displayInfo = "Etape 3 / 5 -- Combattre les deux monstres",
            stepStartMapId = 153092356,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20001)
                Dialog:NpcReply(24791)
            end
        },
        ["10016"] = {
            displayInfo = "Etape 4 / 5 -- Parler a Maître Dam",
            stepStartMapId = 153092356,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1, "slow")
            end
        },
        ["9734"] = {
            displayInfo = "Etape 5 / 5 -- Parler a Ganymède",
            stepStartMapId = 153092354,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1)
            end
        }
    }
}

Quest.QuestSolution["Réponses à tout"] = {
    questId = 1631,
    requiredFinishedQuest = { 1629, 1630 },
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 4 -- Récupérer la quête",
            stepStartMapId = 152043521,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1, "slow")
                global:leaveDialog()
            end
        },
        ["9730"] = {
            displayInfo = "Étape 1 / 4 -- Lire l'histoire des cra",
            stepStartMapId = 152043521,
            ["EXECUTE"] = function()
                map:door(230)
                global:leaveDialog()
            end
        },
        ["9738"] = {
            displayInfo = "Étape 2 / 4 -- Lire l'histoire des dofus",
            stepStartMapId = 152043521,
            ["EXECUTE"] = function()
                map:door(438)
                global:leaveDialog()
            end
        },
        ["9739"] = {
            displayInfo = "Étape 3 / 4 -- Regarde la carte du monde des douze",
            stepStartMapId = 152043521,
            ["EXECUTE"] = function()
                map:door(362)
                global:leaveDialog()
            end
        },
        ["9740"] = {
            displayInfo = "Étape 4 / 4 -- Parler a Ganymède",
            stepStartMapId = 152043521,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(24801, "slow")
                Dialog:NpcReply(24800)
                Dialog:NpcReply(24799)
            end
        }
    }
}

Quest.QuestSolution["Le village dans les nuages"] = {
    questId = 1632,
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 7 -- Récupérer la quête",
            stepStartMapId = 154010883,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    24901,
                    24899,
                    24898,
                    24896,
                    24895,
                    24893,
                    24892
                }

                Dialog:NpcDialogRequest(-20001)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9762"] = {
            displayInfo = "Étape 1 / 7 -- Allez voir ternette Nhin",
            stepStartMapId = 154010371,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    24919,
                    24927,
                    24290
                }

                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9763"] = {
            displayInfo = "Étape 2 / 7 -- Allez voir Berb Nhin",
            stepStartMapId = 153878787,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    25022,
                    25021,
                    25290
                }

                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9764"] = {
            displayInfo = "Étape 3 / 7 -- Allez voir Grobid",
            stepStartMapId = 153357316,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    25029,
                    25028,
                    25023
                }

                Dialog:NpcDialogRequest(-20001)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9765"] = {
            displayInfo = "Étape 4 / 7 -- Aller voir Le capitaine des kerubims",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    25044,
                    25043,
                    25038
                }

                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9766"] = {
            displayInfo = "Étape 5 / 7 -- Allez voir Hollie Brok",
            stepStartMapId = 153879299,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    25098,
                    25097,
                    25096
                }

                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9767"] = {
            displayInfo = "Étape 6 / 7 -- Aller voir Ternette Nhin",
            stepStartMapId = 154010371,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    24930,
                    24929,
                    24928
                }

                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9768"] = {
            displayInfo = "Étape 7 / 7 -- Aller voir Fécaline la sage",
            stepStartMapId = 153356296,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    25108,
                    25107,
                    25106
                }

                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        }
    }
}

Quest.QuestSolution["Espoirs et tragédies"] = {
    questId = 1634,
    requiredFinishedQuest = { 1632 },
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 7 -- Récupérer la quête",
            stepStartMapId = 153356296,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    25109,
                    25110
                }

                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9772"] = {
            displayInfo = "Étape 1 / 7 -- Lire le livre de Rykke Errel",
            stepStartMapId = 153356296,
            ["EXECUTE"] = function()
                map:door(426)
                global:leaveDialog()
            end
        },
        ["9773"] = {
            displayInfo = "Étape 2 / 7 -- Parler a Fécaline la sage",
            stepStartMapId = 153356296,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    25113,
                    25112,
                    25111
                }
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9774"] = {
            displayInfo = "Étape 3 / 7 -- Parler a un vieux de la vieille",
            stepStartMapId = 154010883,
            ["EXECUTE"] = function()
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

                Dialog:NpcDialogRequest(-20001)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9775"] = {
            displayInfo = "Étape 4 / 7 -- Parler a féline pantouflarde",
            stepStartMapId = 153357316,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20002)
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
            end
        },
        ["9776"] = {
            displayInfo = "Étape 5 / 7 -- Parler a un voleur malchanceux",
            stepStartMapId = 153879809,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
            end
        },
        ["9777"] = {
            displayInfo = "Étape 6 / 6 -- Retourner voir Fécaline la sage",
            stepStartMapId = 153356296,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25118, "slow")
                Dialog:NpcReply(25117, "slow")
            end
        }
    }
}

Quest.QuestSolution["Mise à l'épreuve"] = {
    questId = 1642,
    requiredFinishedQuest = { 1632 },
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 4 -- Récupérer la quête",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25048, "slow")
                Dialog:NpcReply(-1)
                Dialog:NpcReply(25045)
            end
        },
        ["9828"] = {
            displayInfo = "Étape 1 / 4 -- Allez voir le Caporal Mynerve",
            stepStartMapId = 153356292,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    25091,
                    25089,
                    25088
                }
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9829"] = {
            displayInfo = "Étape 2 / 4 -- Combat contre le Caporal Mynerve",
            stepStartMapId = 153356292,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1)
            end
        },
        ["9830"] = {
            displayInfo = "Étape 3 / 4 -- Parler au Capitaine Mynerve",
            stepStartMapId = 153356292,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
            end
        },
        ["9831"] = {
            displayInfo = "Étape 4 / 4 -- Parler au Capitaine des kerubims",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1, "slow")
            end
        }
    }
}

Quest.QuestSolution["Champs de bataille"] = {
    questId = 1643,
    requiredFinishedQuest = { 1642 },
    stepSolution = { 
        ["START"] = {
            displayInfo = "Étape 0 / 5 -- Récupérer la quête",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1, "slow")
                Dialog:NpcReply(-1)
                Dialog:NpcReply(-1)
            end
        },
        ["9832"] = {
            displayInfo = "Étape 1 / 5 -- Combattre x1 Tofu chimérique",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {970}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Champs"))
            end
        },
        ["9833"] = {
            displayInfo = "Étape 2 / 5 -- Combattre x1 Pissenlit Miroitant",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {979}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Champs"))
            end
        },
        ["9834"] = {
            displayInfo = "Étape 3 / 5 -- Combattre x1 Rose Vaporeuse",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {980}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Champs"))
            end
        },
        ["9835"] = {
            displayInfo = "Étape 4 / 5 -- Combattre x1 Tournesol Nébuleux",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {981}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Champs"))
            end
        },
        ["9836"] = {
            displayInfo = "Étape 5 / 5 -- Retourner voir le Capitaine des Kerubims",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25061, "slow")
            end
        }
    }
}

Quest.QuestSolution["Coup d'épée dans l'eau"] = {
    questId = 1644,
    requiredFinishedQuest = { 1643 },
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 4 -- Récupérer la quête",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                    Dialog:NpcDialogRequest(-20000)
                    Dialog:NpcReply(25061, "slow")
                    Dialog:NpcReply(25060)
            end
        },
        ["9837"] = {
            displayInfo = "Étape 1 / 4 -- Combattre x2 Petit Gloot",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {4109}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Lac"))
            end
        },
        ["9838"] = {
            displayInfo = "Étape 2 / 4 -- Combattre x2 Plikplok",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {4108}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Lac"))
            end
        },
        ["9839"] = {
            displayInfo = "Étape 3 / 4 -- Combattre x1 Grand Splatch",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {4110}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Lac"))
            end
        },
        ["9840"] = {
            displayInfo = "Étape 4 / 4 -- Retourner voir le Capitaine des Kerubims",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                    Dialog:NpcDialogRequest(-20000)
                    Dialog:NpcReply(25063, "slow")
                    global:leaveDialog()
            end
        }
    }
}

Quest.QuestSolution["Décime-moi des bouftous"] = {
    questId = 1645,
    requiredFinishedQuest = { 1644 },
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 5 -- Récupérer la quête",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25063, "slow")
                Dialog:NpcReply(25062, "slow")
            end
        },
        ["9841"] = {
            displayInfo = "Étape 1 / 5 -- Combattre x1 Boufton Pâlichon",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {972}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Pâturages"))
            end
        },
        ["9842"] = {
            displayInfo = "Étape 2 / 5 -- Combattre x1 Boufton Orageux",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {973}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Pâturages"))
            end
        },
        ["9843"] = {
            displayInfo = "Étape 3 / 5 -- Combattre x1 Bouftou Nuageux",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {971}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Pâturages"))
            end
        },
        ["9844"] = {
            displayInfo = "Étape 4 / 5 -- Combattre x1 Bouftor Éthéré",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {984}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Pâturages"))
            end
        },
        ["9845"] = {
            displayInfo = "Étape 5 / 5 -- Retourner voir le Capitaine des Kerubims",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25065, "slow")
            end
        }
    }
}

Quest.QuestSolution["Chasse aux chapardams"] = {
    questId = 1646,
    requiredFinishedQuest = { 1645 },
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 4 -- Récupérer la quête",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25065, "slow")
                Dialog:NpcReply(25064)
            end
        },
        ["9846"] = {
            displayInfo = "Étape 1 / 4 -- Combattre x2 Ronronchon",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {4105}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Forêt"))
            end
        },
        ["9847"] = {
            displayInfo = "Étape 2 / 4 -- Combattre x2 Tigrimas",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {4106}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Forêt"))
            end
        },
        ["9848"] = {
            displayInfo = "Étape 3 / 4 -- Combattre x2 Chakrobat",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {982}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Forêt"))
            end
        },
        ["9849"] = {
            displayInfo = "Étape 4 / 4 -- Retourner voir le Capitaine des Kerubims",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(-1, "slow")
            end
        }
    }
}

Quest.QuestSolution["Leçon d'humilité"] = {
    questId = 1647,
    requiredFinishedQuest = { 1646 },
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 2 -- Récupérer la quête",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25067, "slow")
                Dialog:NpcReply(25066)
            end
        },
        ["9850"] = {
            displayInfo = "Étape 1 / 2 -- Combattre Kruella Freuz",
            stepStartMapId = 153879040,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25082, "slow")
            end
        },
        ["9851"] = {
            displayInfo = "Étape 2 / 2 -- Retourner voir le Capitaine des Kerubims",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25071, "slow")
            end
        }
    }
}

Quest.QuestSolution["Des chafers qui marchent"] = {
    questId = 1648,
    requiredFinishedQuest = { 1647 },
    stepSolution = {
        ["START"] = {
            displayInfo = "Étape 0 / 8 -- Récupérer la quête",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                local possibleIdReply = {
                    25071,
                    25070,
                    25069,
                    25068
                }

                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReplyUntilLeave(possibleIdReply)
            end
        },
        ["9852"] = {
            displayInfo = "Étape 1 / 8 -- Combattre x1 Chafer débutant",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {4046}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Cimetière"))
            end
        },
        ["9853"] = {
            displayInfo = "Étape 2 / 8 -- Combattre x1 Chafer furtif",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {4047}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Cimetière"))
            end
        },
        ["9854"] = {
            displayInfo = "Étape 3 / 8 -- Combattre x1 Chafer éclaireur",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {4048}


                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Cimetière"))
            end
        },
        ["9855"] = {
            displayInfo = "Étape 4 / 8 -- Combattre x1 Chafer Piquier",
            ["EXECUTE"] = function()
                MIN_MONSTERS = 1
                MAX_MONSTERS = 2

                FORCE_MONSTERS = {4049}

                map:fight()
                Movement:RoadZone(Movement:Get_TblZoneSubArea("Incarnam", "Cimetière"))
            end
        },
        ["9856"] = {
            displayInfo = "Étape 5 / 8 -- Découvrir la carte : Tombeau de Percy Klop",
            stepStartMapId = 153881090,
            ["EXECUTE"] = function()
                map:door(361)
            end
        },
        ["9859"] = {
            displayInfo = "Étape 6 / 8 -- Fouiller la tombe",
            stepStartMapId = 153356288,
            ["EXECUTE"] = function()
                map:door(343)
            end
        },
        ["9857"] = {
            displayInfo = "Étape 7 / 8 -- Combattre x1 Percy Klop",
            stepStartMapId = 153356288,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25086)
            end
        },
        ["9858"] = {
            displayInfo = "Étape 8 / 8 -- Retourner voir le Capitaine des Kerubims",
            stepStartMapId = 153356294,
            ["EXECUTE"] = function()
                Dialog:NpcDialogRequest(-20000)
                Dialog:NpcReply(25073)
            end
        }
    }
}

-- Zone area mapId

Movement.ZoneAreaMapId = {
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