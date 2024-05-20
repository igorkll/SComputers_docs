audienceCounter = class()

function audienceCounter:sv_n_audienceCounter_request(state, player)
    if not self._audienceData then
        self._audienceData = {}
        self._getAudienceCount = function()
            local count = 0
            local ctick = sm.game.getCurrentTick()
            for id, updateTick in pairs(self._audienceData) do
                if ctick - updateTick <= 80 then
                    count = count + 1
                end
            end
            return count
        end
    end
    if state then
        self._audienceData[player.id] = sm.game.getCurrentTick()
    else
        self._audienceData[player.id] = nil
    end
end

function audienceCounter:audienceCounter(state)
    if self.old_audienceCounter_state ~= state or sm.game.getCurrentTick() % 40 == 0 then
        self.network:sendToServer("sv_n_audienceCounter_request", state)
        self.old_audienceCounter_state = state
    end
end