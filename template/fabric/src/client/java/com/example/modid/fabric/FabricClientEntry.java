package com.example.modid.fabric;

import com.example.modid.client.@@CLIENT_INIT_TYPE@@;
import net.fabricmc.api.ClientModInitializer;

// loader-facing shim for physical-client initialization
public final class FabricClientEntry implements ClientModInitializer {
    @Override
    public void onInitializeClient() {
        @@CLIENT_INIT_CALL@@
    }
}
