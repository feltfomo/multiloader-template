package com.example.modid.mixin.client;

import com.mojang.logging.LogUtils;
import net.minecraft.client.gui.screens.TitleScreen;
import org.slf4j.Logger;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

// Sample client-only mixin. Delete or replace -- proves the client mixin config
// is generated from pkl and wired into both loaders.
@Mixin(TitleScreen.class)
public class TitleScreenMixin {
  private static final Logger LOGGER = LogUtils.getLogger();

  @Inject(method = "init", at = @At("TAIL"))
  private void modid$onInit(CallbackInfo ci) {
    LOGGER.info("[modid] client mixin active: TitleScreen.init TAIL");
  }
}
