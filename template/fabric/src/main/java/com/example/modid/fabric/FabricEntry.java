package com.example.modid.fabric;

import com.example.modid.@@MOD_INIT_TYPE@@;
import net.fabricmc.api.ModInitializer;

// loader-facing shim for shared or server-safe initialization
public final class FabricEntry implements ModInitializer {
    @Override
    public void onInitialize() {
        @@MOD_INIT_CALL@@
    }
}
