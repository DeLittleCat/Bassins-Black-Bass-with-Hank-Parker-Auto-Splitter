state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}

init {
	vars.lakeNumber = 0;
	vars.resultsSeen = false;
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
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x08D1) { Name = "tileType" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x11D3) { Name = "place" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x10185) { Name = "activeScreen" },
	};
}

start {
	return vars.watchers["tileType"].Current == 3 && vars.watchers["tileType"].Old != 3;
}

update {
	vars.watchers.UpdateAll(game);
}

split {
	if (vars.watchers["activeScreen"].Current == vars.watchers["place"].Current && vars.watchers["tileType"].Current != 0 && !vars.resultsSeen) {  // First frame on results screen(colored) with console reset protection
		if (vars.lakeNumber == 3) {
			if (vars.watchers["place"].Current == 0x00) {
				vars.resultsSeen = true;
				return true;
			}
		}
		else if (vars.watchers["place"].Current < 0x03) {
			vars.resultsSeen = true;
			vars.lakeNumber += 1;
			return true;
		}
	}
	else if (vars.resultsSeen && vars.watchers["activeScreen"].Current != vars.watchers["place"].Current){  // First frame off results screen
		vars.resultsSeen = false;
	}
}