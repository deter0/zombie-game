-- Entity Manager Init
-- Deter
-- July 27, 2021



local EntityManagerInit = {Client = {}};

function EntityManagerInit:Start()
	self.Shared.EntityManager:Start();
end

return EntityManagerInit;