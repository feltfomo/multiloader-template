package com.example.modid.mixin.client

import com.example.modid.scala.ScalaGreeter
import net.minecraft.client.gui.screens.TitleScreen
import org.spongepowered.asm.mixin.Mixin
import org.spongepowered.asm.mixin.injection.{At, Inject}
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo

// Proves Scala can author mixins: injects into the title screen and calls
// into common Scala logic. Client-only — listed in clientMixins in mod.pkl.
@Mixin(Array(classOf[TitleScreen]))
abstract class TitleScreenScalaMixin:
  @Inject(method = Array("init"), at = Array(new At(value = "HEAD")))
  private def onTitleInit(ci: CallbackInfo): Unit =
    ScalaGreeter.greet()
