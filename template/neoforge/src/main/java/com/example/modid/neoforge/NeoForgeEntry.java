package com.example.modid.neoforge;

import com.example.modid.@@MOD_INIT_TYPE@@;
import net.neoforged.fml.common.Mod;

// loader-facing shim for shared or server-safe initialization
@Mod("modid")
public final class NeoForgeEntry {
    public NeoForgeEntry() {
        @@MOD_INIT_CALL@@
    }
}
