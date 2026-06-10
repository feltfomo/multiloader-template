package com.example.modid

import org.slf4j.LoggerFactory

// Optional Scala 3 sample. Flip `scala = true` in pkl/mod.pkl and this compiles
// into common; the scala3 runtime is bundled into each loader jar automatically.
// Standalone by design -- the Java core never calls it, so the mod still builds
// with Scala off. Wire ExampleScala.init() into your own code, or delete this.
object ExampleScala:
  private val logger = LoggerFactory.getLogger("modid/scala")

  def greet: String = "hello from scala"

  def init(): Unit = logger.info(greet)
