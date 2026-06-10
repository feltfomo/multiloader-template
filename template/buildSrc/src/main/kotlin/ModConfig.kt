package mod

import org.pkl.core.Evaluator
import org.pkl.core.ModuleSource
import java.io.File

// Identity comes straight out of pkl/mod.pkl so Gradle and the generated
// manifests can't drift apart. We embed the Pkl evaluator rather than shelling
// out to the `pkl` cli, so there's nothing to install on PATH.
data class ModConfig(
    val id: String,
    val group: String,
    val version: String,
    val mcVersion: String,
    val fabricLoaderVersion: String,
    val neoVersion: String,
) {
    companion object {
        fun load(modPkl: File): ModConfig =
            Evaluator.preconfigured().use { evaluator ->
                val module = evaluator.evaluate(ModuleSource.path(modPkl.toPath()))
                ModConfig(
                    id = module.get("id") as String,
                    group = module.get("group") as String,
                    version = module.get("version") as String,
                    mcVersion = module.get("mcVersion") as String,
                    fabricLoaderVersion = module.get("fabricLoaderVersion") as String,
                    neoVersion = module.get("neoVersion") as String,
                )
            }
    }
}