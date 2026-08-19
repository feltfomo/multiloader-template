package com.example.modid.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// physical-client logic starts here
public final class ClientInit {
    private static final Logger LOGGER = LoggerFactory.getLogger("modid/client");

    private ClientInit() {}

    public static void init() {
        LOGGER.info("modid client init");
    }
}
