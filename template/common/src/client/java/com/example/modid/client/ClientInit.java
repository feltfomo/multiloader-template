package com.example.modid.client;

import com.example.modid.ModInit;

// Client-only common entry point.
public final class ClientInit {
    private ClientInit() {}

    public static void init() {
        ModInit.LOGGER.info("{} client init", ModInit.MOD_ID);
    }
}
