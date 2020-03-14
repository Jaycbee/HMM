local HMM = {}
local Main = script.Parent
local Class = require(Main.Class)
local Time = require(Main.Time)

local Sequence = Class.New 
local Cache = Class.New

function NewTable(...)
	local NewTable = {}
	local Args = ...
	if typeof(Args) ~= "table" then
		Args = {...}
	end
	for _, val in pairs(Args) do
		table.insert(NewTable, val)
	end
 return NewTable
end



function Sequence.GenerateList(states,SL)
	local Sequences_All = {}
	local Depth = SL
	print(Depth)
    local function  Reccursion(states, nodes, depth)
		if depth == 0 then
		    table.insert(Sequences_All, nodes)
		else
			
			for _,state in pairs(states) do
				local Temp_Nodes = NewTable(nodes)
			    table.insert(Temp_Nodes, state)
				 Reccursion(states,Temp_Nodes, math.abs(depth-1))
			end
		end
	end
	
	Reccursion(states, {}, Depth )
   return Sequences_All
end





function Sequence.Score(sequences,initial,transition,emission,obv)
  local Best = -1
   local BestSeq
	 local SequenceScores = {}
	  for _, seq in pairs(sequences)  do
		local TotalScore = 1
         local first = true
		   for i =1,#seq, 1 do
			 local StateScore = 1
            if first == true then
			StateScore = StateScore *  initial[seq[i]]
			first = false
			else
           StateScore = StateScore * transition[seq[i] .. "|"..seq[i-1]]
           StateScore =  StateScore *  emission[obv[i].. "|" .. seq[i]]
          TotalScore =   TotalScore  * StateScore           
			end
		end
		table.insert(SequenceScores, TotalScore)	
	end
	return SequenceScores
end





   function Cache.alpha(info, alphac, pos, state, cachedrecur)
	if  cachedrecur then
		  if  alphac[pos] then
			    return alphac[pos]
			end
		end
			if pos == 1 then
				 return info.initial[state] * info.emission[info._obv[pos + 1] .."|" .. state]
	       else
			local Total = 0
		    for  i,stateval in pairs(info.states) do
				Total = Total +Cache.alpha(info, alphac,pos-1 ,stateval,cachedrecur) *
			     info.transition[state.."|"..stateval] * info.emission[info._obv[pos].."|"..state]
			    if cachedrecur then
					 if alphac[pos] == nil then
						alphac[pos] = Total
					end
				end
			end
			return Total
	end
end

function HMM.WinningSequence(sequences_score, sequences)
	local Best = 0
	local Seq = nil
         for i = 1, #sequences_score do
		if sequences_score[i] > Best then
			Best = sequences_score[i]
			Seq = sequences[i]
		end
	end
	return Seq,Best
end




function HMM.WriteSequence(sequences_score, sequences, writewinningseq)
	for i = 1, #sequences_score do 
		print("Sequence:", table.concat(sequences[i], "/"),":Score:", string.format("%0.6f",sequences_score[i]) )
end
	if writewinningseq then
		local WinningSequence, score = HMM.WinningSequence(sequences_score, sequences)
            print("WinningSequence:", table.concat(WinningSequence, "/"),":Score:", score)
	end
	print("#Sequences: "..#sequences)
end

function Cache.GetMBR(info, pos) 
	local Mbrscores ={}
	for i = 1, #info.states do
		local AlphaCache = {}
		local BetaCache = {}
		local AlphaCache = Cache.alpha(info,AlphaCache, pos,  info.states[i], true)
		local BetaScore = Cache.beta(info,BetaCache, pos, info.states[i],0,nil, true)
		Mbrscores[ info.states[i]] = AlphaCache * BetaScore 
    end 
	return Mbrscores
end	

function Cache.beta(info,betac, pos, state, currIndex,currState, cachedrecur)
	if cachedrecur then
		
		if  betac[currIndex] then
			return  betac[currIndex]
		end
	end
		  if currIndex == 0 then
			currIndex = #info._obv
			 if pos == currIndex or pos == currIndex - 1 then
				return 1
			end
			local total = 0 
			  for  k,stateval in pairs(info.states) do
			   local tempSum =  Cache.beta(info, betac, pos, state, currIndex -1 ,stateval, cachedrecur)
				total = total +  tempSum
				if cachedrecur then
					if betac[currIndex] == nil then
						betac[currIndex]  = total
					end
				end
              return total
			end 
	elseif currIndex == pos + 1 then
			return info.transition[currState.."|"..state] * info.emission[info._obv[currIndex].."|"..currState]
		else
			local total = 0
			   for  i,stateval in pairs(info.states) do
				 local  inStateProb = info.transition[currState.."|"..stateval] * info.emission[info._obv[currIndex].."|"..currState]
				local  tempSum = inStateProb * Cache.beta(info, betac, pos, state,currIndex-1 ,stateval, cachedrecur)
				total = total + tempSum
			end
		if cachedrecur then
			if betac[currIndex] == nil then
					betac[currIndex]  = total
				end
			end
			return total
	   end
  end




HMM.Cache = Cache




function HMM.initialize(info)
	local Length = #info._obv
	local Sequences = Sequence.GenerateList(info.states, Length )
	local SequenceScores = Sequence.Score(Sequences, info.initial, info.transition, info.emission, info._obv)
	return Length, Sequences, SequenceScores
end

return HMM
