package com.example.modid.neoforge;

import com.example.modid.ModInit;
import net.neoforged.fml.common.Mod;

@Mod(ModInit.MOD_ID)
public final class NeoForgeEntry {
    public NeoForgeEntry() {
        ModInit.init();
    }
}
