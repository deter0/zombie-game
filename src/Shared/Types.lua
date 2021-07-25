export type Signal = {
	Fire: () -> (),
	new: () -> (),
	Proxy: (RBXScriptSignal, any) -> (),
	Is: (RBXScriptSignal, any) -> boolean,
	_setProxy: (RBXScriptSignal) -> (),
	_clearProxy: () -> (),
	Fire: (any) -> (),
	Wait: () -> (),
	WaitPromise: () -> any,
	Connect: ((any) -> (any)) -> (any),
	DisconnectAll: () -> (),
	Destroy: () -> (),
	Init: () -> (),
};

return nil;