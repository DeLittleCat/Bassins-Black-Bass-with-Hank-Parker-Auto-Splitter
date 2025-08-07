state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}

init {
	vars.resultsSeen = false;
	vars.willSplit = false;
	vars.lake = 0;
	var states = new Dictionary<int, long> {
		{ 9646080,   0x97EE04 },      // Snes9x-rr 1.60
        	{ 13565952,  0x140925118 },   // Snes9x-rr 1.60 (x64)
        	{ 9027584,   0x94DB54 },      // Snes9x 1.60
        	{ 12836864,  0x1408D8BE8 },   // Snes9x 1.60 (x64)
        	{ 10399744,  0x9B74D0 },      // Snes9x 1.62.3
        	{ 15474688,  0x140A62390 },   // Snes9x 1.62.3 (x64)
        	{ 11124736,  0xA63DF0 },      // Snes9x 1.63
        	{ 16994304,  0x140BC1CA0 },   // Snes9x 1.63 (x64)
        	{ 16019456,  0x94D144 },      // higan v106
        	{ 15360000,  0x8AB144 },      // higan v106.112
        	{ 10096640,  0x72BECC },      // bsnes v107
        	{ 10338304,  0x762F2C },      // bsnes v107.1
        	{ 47230976,  0x765F2C },      // bsnes v107.2/107.3
        	{ 131543040, 0xA9BD5C },      // bsnes v110
        	{ 51924992,  0xA9DD5C },      // bsnes v111
        	{ 52056064,  0xAAED7C },      // bsnes v112
        	{ 52477952,  0xB16D7C },      // bsnes v115
        	{ 7061504,   0x36F11500240 }, // BizHawk 2.3.0
        	{ 7249920,   0x36F11500240 }, // BizHawk 2.3.1
        	{ 6938624,   0x36F11500240 }, // BizHawk 2.3.2
        	{ 4538368,   0x36F05F94040 }, // BizHawk 2.6.0
    	};

	long memoryOffset;
	if (states.TryGetValue(modules.First().ModuleMemorySize, out memoryOffset)) {
		var procName = memory.ProcessName.ToLower();
		if (procName.Contains("snes9x")) {
			if (procName.Contains("x64")) {
				memoryOffset = memory.ReadValue<long>((IntPtr)memoryOffset);
			}
			else {
				memoryOffset = memory.ReadValue<int>((IntPtr)memoryOffset);
			}
		}
	}

	if (memoryOffset == 0) {
		throw new Exception("Memory not yet initialized.");
	}
	else {
		print("[Autosplitter] Memory address: " + memoryOffset.ToString("X8"));
	}

	vars.watchers = new MemoryWatcherList {
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x008D1) { Name = "tileType" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x011D3) { Name = "place" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x10185) { Name = "paletteOverlay" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x01130) { Name = "stageNumber" },
	};
}

start {
	vars.resultsSeen = false;
	vars.willSplit = false;
	vars.lake = 0;
	return vars.watchers["tileType"].Current == 0x03;
}

update {
	vars.watchers.UpdateAll(game);
	vars.willSplit = false;
	vars.resultsSeen = vars.resultsSeen && vars.watchers["paletteOverlay"].Current == 4;
	if (vars.watchers["paletteOverlay"].Current == 0x04 && vars.watchers["place"].Current < 0x03 && vars.watchers["tileType"].Current != 0x00 && !vars.resultsSeen){
		vars.resultsSeen = true;
		vars.willSplit = vars.watchers["stageNumber"].Current != 3 || vars.watchers["place"].Current == 0x00;
	}
	else if (vars.watchers["stageNumber"].Current > vars.lake){ vars.willSplit = true; }
	if (vars.willSplit){ vars.lake += 1; }
}

split { return vars.willSplit; }
