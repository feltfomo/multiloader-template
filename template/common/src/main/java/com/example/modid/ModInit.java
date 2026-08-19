package com.example.modid;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// shared, server-safe logic starts here
public final class ModInit {
  private static final String MOD_ID = "modid";
  private static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

  private ModInit() {}

  public static void init() {
    LOGGER.info("{} common init", MOD_ID);
  }
}
