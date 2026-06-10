package com.example.modid.scala

import org.slf4j.LoggerFactory

// Scala 3 sample logic, compiled into common alongside the Java code.
// Delete this file (and its mixin) to drop Scala from a scaffolded mod.
object ScalaGreeter:
  private val LOGGER = LoggerFactory.getLogger("modid")
  def greet(): Unit =
    LOGGER.info("hello from scala 3 — the mixin layer is live")
