package com.example.modid;

import com.example.modid.kotlin.KotlinGreeter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// Common entry point. All shared, server-safe logic starts here.
// The loaders never see this directly; their shims call init().
public final class ModInit {
    public static final String MOD_ID = "modid";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    private ModInit() {}

    public static void init() {
        LOGGER.info("{} common init", MOD_ID);
        KotlinGreeter.greet();
    }
}
