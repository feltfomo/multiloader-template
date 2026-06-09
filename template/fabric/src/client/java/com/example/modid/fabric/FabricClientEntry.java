package com.example.modid.fabric;

import com.example.modid.client.ClientInit;
import net.fabricmc.api.ClientModInitializer;

// Fabric client shim.
public final class FabricClientEntry implements ClientModInitializer {
    @Override
    public void onInitializeClient() {
        ClientInit.init();
    }
}
