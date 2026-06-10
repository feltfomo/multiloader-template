package com.example.modid.mixin;

import com.mojang.logging.LogUtils;
import net.minecraft.server.Bootstrap;
import org.slf4j.Logger;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

// Sample common mixin: runs on client and dedicated server. Delete it or swap
// in your own -- it exists to prove the common mixin path end to end.
@Mixin(Bootstrap.class)
public class BootstrapMixin {
    private static final Logger LOGGER = LogUtils.getLogger();

    @Inject(method = "bootStrap", at = @At("TAIL"))
    private static void modid$onBootStrap(CallbackInfo ci) {
        LOGGER.info("[modid] common mixin active: Bootstrap.bootStrap TAIL");
    }
}
