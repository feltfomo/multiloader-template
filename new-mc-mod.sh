#!/usr/bin/env bash
set -euo pipefail

# feltfomo multiloader template generator
# Produces a ready-to-build zip from your Fabric + NeoForge + Java/Kotlin/Scala stack.

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}=>${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}✓${RESET} $*"; }
die()     { echo -e "${RED}${BOLD}error:${RESET} $*" >&2; exit 1; }

ask() {
    local prompt="$1" default="$2"
    read -r -p "$(echo -e "${BOLD}${prompt}${RESET} ${CYAN}(${default})${RESET}: ")" var
    echo "${var:-$default}"
}

echo
echo -e "${BOLD}feltfomo multiloader template${RESET}"
echo -e "Minecraft 26.1.2 · Fabric + NeoForge · Java/Kotlin/Scala"
echo

MOD_ID=$(ask      "mod id"          "modid")
MOD_NAME=$(ask    "mod name"        "Modid")
MOD_GROUP=$(ask   "group/package"   "com.example.${MOD_ID}")
MOD_VERSION=$(ask "version"         "1.0.0")
MOD_AUTHORS=$(ask "authors"         "yourname")
MOD_LICENSE=$(ask "license"         "All Rights Reserved")
MOD_DESC=$(ask    "description"     "A Minecraft mod.")

# mod id and group need to be valid identifiers, so check them before building anything
[[ "$MOD_ID" =~ ^[a-z][a-z0-9_]*$ ]] || die "mod id must start with a lowercase letter and use only lowercase letters, digits, and underscores."
[[ "$MOD_GROUP" =~ ^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)*$ ]] || die "group must be a valid package like com.example.${MOD_ID}."

# turn com.example.mymod into com/example/mymod for directory creation
MOD_GROUP_PATH="${MOD_GROUP//.//}"

# build a class prefix from the name: drop punctuation, capitalize each word, join them
MOD_CLASS=$(echo "$MOD_NAME" | sed 's/[^[:alnum:] ]//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' | tr -d ' ')
[[ -n "$MOD_CLASS" ]] || die "mod name needs at least one letter or digit."

OUT_DIR="${MOD_ID}"
ZIP_NAME="${MOD_ID}-template.zip"

[[ -e "$OUT_DIR" ]] && die "Directory '${OUT_DIR}' already exists."

echo
echo -e "${BOLD}About to generate:${RESET}"
echo "  mod id      : ${MOD_ID}"
echo "  mod name    : ${MOD_NAME}"
echo "  class prefix: ${MOD_CLASS}"
echo "  group       : ${MOD_GROUP}"
echo "  package path: ${MOD_GROUP_PATH}"
echo "  version     : ${MOD_VERSION}"
echo "  authors     : ${MOD_AUTHORS}"
echo "  license     : ${MOD_LICENSE}"
echo "  description : ${MOD_DESC}"
echo "  output      : ${ZIP_NAME}"
echo
echo -ne "${BOLD}Continue?${RESET} [Y/n]: "
read -r confirm
[[ "${confirm,,}" == n* ]] && { info "Aborted."; exit 0; }

info "Creating directory tree..."

mkdir -p "${OUT_DIR}"/{common,fabric,neoforge}/src
mkdir -p "${OUT_DIR}/gradle/wrapper"

for module in common fabric neoforge; do
    envs=(main)
    [[ "$module" != neoforge ]] && envs+=(client)
    for env in "${envs[@]}"; do
        mkdir -p "${OUT_DIR}/${module}/src/${env}/java/${MOD_GROUP_PATH}/$(  [[ $env == client ]] && echo 'client/' || echo '')mixin"
        mkdir -p "${OUT_DIR}/${module}/src/${env}/kotlin/${MOD_GROUP_PATH}/$(  [[ $env == client ]] && echo 'client' || echo '')"
        mkdir -p "${OUT_DIR}/${module}/src/${env}/scala/${MOD_GROUP_PATH}/$(  [[ $env == client ]] && echo 'client' || echo '')"
        mkdir -p "${OUT_DIR}/${module}/src/${env}/resources"
    done
done

mkdir -p "${OUT_DIR}/neoforge/src/main/resources/META-INF"
mkdir -p "${OUT_DIR}/fabric/src/main/resources/assets/${MOD_ID}"

write_file() {
    local path="${OUT_DIR}/$1"
    mkdir -p "$(dirname "$path")"
    cat > "$path"
}

info "Writing Gradle wrapper properties..."

write_file "gradle/wrapper/gradle-wrapper.properties" << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.4-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

write_file "build.gradle.kts" << EOF
// Root build script. Shared config only.
// All real code lives in common/, fabric/, neoforge/.

plugins {
    id("org.jetbrains.kotlin.jvm")
}

subprojects {
    group = providers.gradleProperty("mod_group").get()
    version = providers.gradleProperty("mod_version").get()
}
EOF

write_file "settings.gradle.kts" << EOF
pluginManagement {
    repositories {
        maven {
            name = "Fabric"
            url = uri("https://maven.fabricmc.net/")
        }
        maven {
            name = "NeoForge"
            url = uri("https://maven.neoforged.net/releases")
        }
        maven {
            name = "Kotori316"
            url = uri("https://maven.kotori316.com")
        }
        maven {
            name = "MinecraftForge"
            url = uri("https://maven.minecraftforge.net/")
        }
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("org.jetbrains.kotlin.jvm") version "2.4.0"
        id("net.fabricmc.fabric-loom") version "1.16-SNAPSHOT"
        id("net.neoforged.moddev") version "2.0.141"
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "${MOD_ID}"

include("common")
include("fabric")
include("neoforge")
EOF

write_file "gradle.properties" << EOF
# Gradle performance
org.gradle.jvmargs=-Xmx2G
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configuration-cache=false

# Minecraft
minecraft_version=26.1.2

# Mod
mod_id=${MOD_ID}
mod_name=${MOD_NAME}
mod_group=${MOD_GROUP}
mod_version=${MOD_VERSION}
mod_license=${MOD_LICENSE}
mod_authors=${MOD_AUTHORS}
mod_description=${MOD_DESC}

# Fabric
fabric_loader_version=0.19.3
loom_version=1.16-SNAPSHOT
fabric_api_version=0.150.0+26.1.2

# NeoForge
neo_version=26.1.2.73
minecraft_version_range=[26.1.2,)
neo_version_range=[26.1.2.73,)

# Language plugins
kotlin_version=2.4.0
scala_version=3.8.3
fabric_kotlin_version=1.13.12+kotlin.2.4.0

# Scala language provider. Handles Scala entrypoints on both loaders.
# Fabric:   https://github.com/Kotori316/SLP-fabric
# NeoForge: https://github.com/Kotori316/SLP
slp_fabric_version=4.0.4
slp_neoforge_version=4.0.5-mc26.1.2-3.8.3
EOF

write_file "common/build.gradle.kts" << EOF
// Compiled against vanilla MC only. No Fabric, no NeoForge.
plugins {
    id("java-library")
    id("org.jetbrains.kotlin.jvm")
    id("scala")
    id("net.fabricmc.fabric-loom")
}

val minecraftVersion: String = providers.gradleProperty("minecraft_version").get()
val scalaVersion: String     = providers.gradleProperty("scala_version").get()

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_25)
    }
}

dependencies {
    minecraft("com.mojang:minecraft:\$minecraftVersion")
    implementation("org.scala-lang:scala3-library_3:\$scalaVersion")
}

sourceSets {
    val main by getting
    create("client") {
        compileClasspath += main.compileClasspath + main.output
        runtimeClasspath += main.runtimeClasspath + main.output
    }
}

sourceSets.configureEach {
    java.srcDir("src/\$name/java")
    scala.srcDir("src/\$name/scala")
    resources.srcDir("src/\$name/resources")
}

kotlin {
    sourceSets.configureEach {
        kotlin.srcDir("src/\$name/kotlin")
    }
}

// Scala goes last so it can see Java and Kotlin classes at compile time
tasks.named("compileClientScala") { dependsOn("compileClientKotlin", "compileClientJava") }
tasks.named("compileScala")       { dependsOn("compileKotlin", "compileJava") }

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release  = 25
}

tasks.withType<ProcessResources>().configureEach {
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}
EOF

write_file "fabric/build.gradle.kts" << EOF
// Fabric bootstrap. Wires the common module into Fabric's loader.
plugins {
    id("java-library")
    id("org.jetbrains.kotlin.jvm")
    id("scala")
    id("net.fabricmc.fabric-loom")
}

val minecraftVersion: String    = providers.gradleProperty("minecraft_version").get()
val scalaVersion: String        = providers.gradleProperty("scala_version").get()
val slpFabricVersion: String    = providers.gradleProperty("slp_fabric_version").get()
val fabricLoaderVersion: String = providers.gradleProperty("fabric_loader_version").get()

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_25)
    }
}

loom {
    splitEnvironmentSourceSets()
    mods {
        register("${MOD_ID}") {
            sourceSet(sourceSets.main.get())
            sourceSet(sourceSets.getByName("client"))
        }
    }
}

sourceSets.configureEach {
    kotlin.srcDir("src/\$name/kotlin")
}

repositories {
    maven {
        name = "Kotori316"
        url = uri("https://maven.kotori316.com")
        content {
            includeGroup("com.kotori316")
            includeVersion("org.typelevel", "cats-core_3",   "2.13.0-kotori")
            includeVersion("org.typelevel", "cats-kernel_3", "2.13.0-kotori")
            includeVersion("org.typelevel", "cats-free_3",   "2.13.0-kotori")
        }
    }
}

val commonProject    = project(":common")
val commonSourceSets = commonProject.extensions.getByType<SourceSetContainer>()

dependencies {
    minecraft("com.mojang:minecraft:\$minecraftVersion")
    implementation("net.fabricmc:fabric-loader:\$fabricLoaderVersion")
    implementation("com.kotori316:scalable-cats-force-fabric:\$slpFabricVersion:dev")
    implementation("org.scala-lang:scala3-library_3:\$scalaVersion")
    implementation(commonProject)
    "clientImplementation"(commonSourceSets.getByName("client").output)
}

tasks.processResources {
    val props = mapOf(
        "version"               to version,
        "mod_id"                to providers.gradleProperty("mod_id").get(),
        "mod_name"              to providers.gradleProperty("mod_name").get(),
        "mod_description"       to providers.gradleProperty("mod_description").get(),
        "mod_license"           to providers.gradleProperty("mod_license").get(),
        "mod_authors"           to providers.gradleProperty("mod_authors").get(),
        "minecraft_version"     to minecraftVersion,
        "fabric_loader_version" to fabricLoaderVersion,
        "fabric_kotlin_version" to providers.gradleProperty("fabric_kotlin_version").get(),
    )
    inputs.properties(props)
    filesMatching("fabric.mod.json") { expand(props) }
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release  = 25
}
EOF

write_file "neoforge/build.gradle.kts" << EOF
// NeoForge bootstrap. Wires the common module into NeoForge's loader.
plugins {
    id("java-library")
    id("org.jetbrains.kotlin.jvm")
    id("scala")
    id("net.neoforged.moddev")
}

val minecraftVersion: String = providers.gradleProperty("minecraft_version").get()
val neoVersion: String       = providers.gradleProperty("neo_version").get()
val scalaVersion: String     = providers.gradleProperty("scala_version").get()
val slpNeoVersion: String    = providers.gradleProperty("slp_neoforge_version").get()

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_25)
    }
}

sourceSets.configureEach {
    kotlin.srcDir("src/\$name/kotlin")
}

// common's compiled classes, without loom's remapped deps
val commonProject    = project(":common")
val commonSourceSets = commonProject.extensions.getByType<SourceSetContainer>()

neoForge {
    version = neoVersion
    runs {
        create("client") { client() }
        create("server") {
            server()
            programArguments.add("--nogui")
        }
    }
    mods {
        create("${MOD_ID}") {
            // neoforge ships one jar, so common rides inside this mod
            sourceSet(sourceSets.main.get())
            sourceSet(commonSourceSets.getByName("main"))
            sourceSet(commonSourceSets.getByName("client"))
        }
    }
}

repositories {
    maven {
        name = "Kotori316"
        url = uri("https://maven.kotori316.com")
        content { includeGroup("com.kotori316") }
    }
}

dependencies {
    implementation("com.kotori316:scalablecatsforce-neoforge:\$slpNeoVersion") {
        isTransitive = false
    }
    // slp provides the scala library at runtime
    compileOnly("org.scala-lang:scala3-library_3:\$scalaVersion")
    // compile against common, runtime comes from the mods block
    compileOnly(commonSourceSets.getByName("main").output)
    compileOnly(commonSourceSets.getByName("client").output)
}

// fold common into the built jar
tasks.named<Jar>("jar") {
    from(commonSourceSets.getByName("main").output)
    from(commonSourceSets.getByName("client").output)
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}

tasks.named<ProcessResources>("processResources") {
    val props = mapOf(
        "mod_id"                  to providers.gradleProperty("mod_id").get(),
        "mod_name"                to providers.gradleProperty("mod_name").get(),
        "mod_description"         to providers.gradleProperty("mod_description").get(),
        "mod_license"             to providers.gradleProperty("mod_license").get(),
        "mod_authors"             to providers.gradleProperty("mod_authors").get(),
        "mod_version"             to version.toString(),
        "neo_version"             to neoVersion,
        "minecraft_version"       to minecraftVersion,
        "minecraft_version_range" to providers.gradleProperty("minecraft_version_range").get(),
        "neo_version_range"       to providers.gradleProperty("neo_version_range").get(),
    )
    inputs.properties(props)
    filesMatching("META-INF/neoforge.mods.toml") { expand(props) }
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release  = 25
}
EOF

info "Writing mixin configs..."

MIXIN_MAIN='{
  "required": true,
  "package": "'"${MOD_GROUP}"'.mixin",
  "compatibilityLevel": "JAVA_25",
  "mixins": [],
  "injectors": { "defaultRequire": 1 }
}'

MIXIN_CLIENT='{
  "required": true,
  "package": "'"${MOD_GROUP}"'.client.mixin",
  "compatibilityLevel": "JAVA_25",
  "client": [],
  "injectors": { "defaultRequire": 1 }
}'

for module in common fabric neoforge; do
    echo "$MIXIN_MAIN" > "${OUT_DIR}/${module}/src/main/resources/${MOD_ID}.mixins.json"
    if [[ "$module" == neoforge ]]; then
        # neoforge has no client source set, so its client mixin config ships in main resources
        echo "$MIXIN_CLIENT" > "${OUT_DIR}/${module}/src/main/resources/${MOD_ID}.client.mixins.json"
    else
        echo "$MIXIN_CLIENT" > "${OUT_DIR}/${module}/src/client/resources/${MOD_ID}.client.mixins.json"
    fi
done

info "Writing fabric.mod.json..."

write_file "fabric/src/main/resources/fabric.mod.json" << EOF
{
  "schemaVersion": 1,
  "id": "\${mod_id}",
  "version": "\${version}",
  "name": "\${mod_name}",
  "description": "\${mod_description}",
  "authors": ["\${mod_authors}"],
  "license": "\${mod_license}",
  "icon": "assets/${MOD_ID}/icon.png",
  "environment": "*",
  "entrypoints": {
    "main": [
      {
        "adapter": "kotori_scala",
        "value": "${MOD_GROUP}.${MOD_CLASS}Fabric"
      }
    ],
    "client": [
      {
        "adapter": "kotori_scala",
        "value": "${MOD_GROUP}.client.${MOD_CLASS}ClientFabric"
      }
    ]
  },
  "mixins": [
    "${MOD_ID}.mixins.json",
    {
      "config": "${MOD_ID}.client.mixins.json",
      "environment": "client"
    }
  ],
  "depends": {
    "fabricloader": ">=\${fabric_loader_version}",
    "minecraft": "~\${minecraft_version}",
    "java": ">=25"
  }
}
EOF

info "Writing neoforge.mods.toml..."

write_file "neoforge/src/main/resources/META-INF/neoforge.mods.toml" << EOF
modLoader = "kotori_scala"
loaderVersion = "[1,)"
license = "\${mod_license}"

[[mods]]
modId      = "\${mod_id}"
version    = "\${mod_version}"
displayName = "\${mod_name}"
description = '''\${mod_description}'''
authors    = "\${mod_authors}"
modEntry   = "${MOD_GROUP}.${MOD_CLASS}NeoForge"

[[mixins]]
config = "${MOD_ID}.mixins.json"

[[mixins]]
config = "${MOD_ID}.client.mixins.json"

[[dependencies.\${mod_id}]]
modId        = "neoforge"
type         = "required"
versionRange = "\${neo_version_range}"
ordering     = "NONE"
side         = "BOTH"

[[dependencies.\${mod_id}]]
modId        = "minecraft"
type         = "required"
versionRange = "\${minecraft_version_range}"
ordering     = "NONE"
side         = "BOTH"
EOF

info "Writing Scala entry points..."

write_file "common/src/main/scala/${MOD_GROUP_PATH}/${MOD_CLASS}Common.scala" << EOF
package ${MOD_GROUP}

import org.slf4j.LoggerFactory

object ${MOD_CLASS}Common:
  val logger = LoggerFactory.getLogger(${MOD_CLASS}Constants.MOD_ID)

  def init(): Unit =
    logger.info("${MOD_NAME} common init")
EOF

write_file "common/src/main/scala/${MOD_GROUP_PATH}/${MOD_CLASS}Constants.scala" << EOF
package ${MOD_GROUP}

object ${MOD_CLASS}Constants:
  inline val MOD_ID = "${MOD_ID}"
EOF

write_file "common/src/client/scala/${MOD_GROUP_PATH}/client/${MOD_CLASS}ClientCommon.scala" << EOF
package ${MOD_GROUP}.client

import ${MOD_GROUP}.${MOD_CLASS}Common

object ${MOD_CLASS}ClientCommon:
  def init(): Unit =
    ${MOD_CLASS}Common.logger.info("${MOD_NAME} client init")
EOF

write_file "fabric/src/main/scala/${MOD_GROUP_PATH}/${MOD_CLASS}Fabric.scala" << EOF
package ${MOD_GROUP}

import net.fabricmc.api.ModInitializer
import ${MOD_GROUP}.${MOD_CLASS}Common

object ${MOD_CLASS}Fabric extends ModInitializer:
  override def onInitialize(): Unit =
    ${MOD_CLASS}Common.init()
EOF

write_file "fabric/src/client/scala/${MOD_GROUP_PATH}/client/${MOD_CLASS}ClientFabric.scala" << EOF
package ${MOD_GROUP}.client

import net.fabricmc.api.ClientModInitializer
import ${MOD_GROUP}.client.${MOD_CLASS}ClientCommon

object ${MOD_CLASS}ClientFabric extends ClientModInitializer:
  override def onInitializeClient(): Unit =
    ${MOD_CLASS}ClientCommon.init()
EOF

write_file "neoforge/src/main/scala/${MOD_GROUP_PATH}/${MOD_CLASS}NeoForge.scala" << EOF
package ${MOD_GROUP}

import net.neoforged.api.distmarker.Dist
import net.neoforged.bus.api.IEventBus
import net.neoforged.fml.common.Mod
import ${MOD_GROUP}.${MOD_CLASS}Common
import ${MOD_GROUP}.client.${MOD_CLASS}ClientCommon
import ${MOD_GROUP}.${MOD_CLASS}Constants.MOD_ID

@Mod(MOD_ID)
class ${MOD_CLASS}NeoForge(modBus: IEventBus, dist: Dist):
  ${MOD_CLASS}Common.init()
  if dist == Dist.CLIENT then ${MOD_CLASS}ClientCommon.init()
EOF

write_file "README.md" << EOF
# ${MOD_NAME}

${MOD_DESC}

## Stack

- **Minecraft 26.1.2** — unobfuscated, Mojang mappings
- **Java 25** — required by MC 26.1+
- **Gradle 9.4** / Kotlin DSL throughout
- **Languages**: Java → Kotlin → Scala (compiled in this order; Scala can call everything)
- **Scala entrypoints** via [SLP (Kotori316)](https://github.com/Kotori316/SLP) on both loaders

## Structure

\`\`\`
.
├── common/          # All real mod code — no loader deps
│   └── src/
│       ├── main/    # Shared, server-safe code
│       └── client/  # Client-only code
├── fabric/          # Fabric bootstrap shim
└── neoforge/        # NeoForge bootstrap shim
\`\`\`

## Running

\`\`\`bash
./gradlew :fabric:runClient
./gradlew :neoforge:runClient
\`\`\`

## Language rules

- **Java** — mixins, low-level bindings
- **Kotlin** — primary application language
- **Scala** — entrypoints, data pipelines, transformation layers

Scala compiles last so it can freely call Java and Kotlin. Don't call Scala from Java or Kotlin directly.
EOF

info "Zipping..."
zip -r "${ZIP_NAME}" "${OUT_DIR}" -x "*.DS_Store" > /dev/null
rm -rf "${OUT_DIR}"

success "Generated ${ZIP_NAME}"
echo -e "  Unzip and run: ${CYAN}unzip ${ZIP_NAME} && cd ${MOD_ID} && ./gradlew :fabric:runClient${RESET}"
