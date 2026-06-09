package com.example.modid.fabric;

import com.example.modid.ModInit;
import net.fabricmc.api.ModInitializer;

// Fabric main shim. Loader-facing; just calls common init.
public final class FabricEntry implements ModInitializer {
    @Override
    public void onInitialize() {
        ModInit.init();
    }
}
