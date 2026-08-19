#!/usr/bin/env nu

# copies the tracked template before the one-shot scaffolder rewrites it

def fail [message: string, code: int = 1] {
  print --stderr $"error: ($message)"
  exit $code
}

def env-string [name: string] {
  $env | get -o $name | default ""
}

def main [
  id?: string
  group?: string
  name?: string
  --language: string
  --side: string
  --kotlin
  --scala
  --no-datagen
] {
  let here = ($env.FILE_PWD? | default $env.PWD)
  let src = ($here | path join "template")

  if not ($src | path exists) {
    fail $"($src) not found, run this from the cloned repo root"
  }

  mut mod_id = ($id | default "")
  mut mod_group = ($group | default "")
  let mod_name = ($name | default "")

  if ($mod_id | is-empty) {
    $mod_id = (input "mod id (lowercase): ")
  }
  if ($mod_group | is-empty) {
    let reply = (input $"group / package [com.example.($mod_id)]: ")
    $mod_group = if ($reply | is-empty) { $"com.example.($mod_id)" } else { $reply }
  }

  let requested_language = ($language | default "")
  if (($kotlin and $scala) or (($kotlin or $scala) and not ($requested_language | is-empty))) {
    fail "choose exactly one of --language, --kotlin, or --scala"
  }

  let legacy_language = if $kotlin { "kotlin" } else if $scala { "scala" } else { "" }
  let env_language = (env-string "SCAFFOLD_LANGUAGE")
  let mod_language = if not ($legacy_language | is-empty) {
    $legacy_language
  } else if not ($requested_language | is-empty) {
    $requested_language
  } else if not ($env_language | is-empty) {
    $env_language
  } else {
    "java"
  }
  let requested_side = ($side | default "")
  let env_side = (env-string "SCAFFOLD_SIDE")
  let mod_side = if not ($requested_side | is-empty) {
    $requested_side
  } else if not ($env_side | is-empty) {
    $env_side
  } else {
    "both"
  }

  if not ($mod_language in ["java" "kotlin" "scala"]) {
    fail $"language must be java, kotlin, or scala (got ($mod_language))"
  }
  if not ($mod_side in ["both" "client" "server"]) {
    fail $"side must be both, client, or server (got ($mod_side))"
  }

  let dest = ($env.PWD | path join $mod_id)
  if ($dest | path exists) {
    fail $"./($mod_id) already exists"
  }

  if $env.PWD == $here {
    print "note: this project will land inside the template repo and be picked up by git and notion-sync"
    print "      run the generator from somewhere like ~/Projects to keep generated mods separate"
  }

  print $"copying template -> ./($mod_id)"
  mkdir $dest
  let tar_args = [
    "-C" $src
    "--exclude=./.git"
    "--exclude=./build" "--exclude=*/build"
    "--exclude=./.jdk"
    "--exclude=*/.gradle" "--exclude=*/.kotlin"
    "--exclude=*/run"
    "--exclude=*/generated"
    "-cf" "-" "."
  ]
  ^tar ...$tar_args | ^tar -C $dest -xf -

  ^chmod -R u+w $dest

  let env_datagen = (env-string "SCAFFOLD_DATAGEN")
  let scaffold_env = {
    SCAFFOLD_ID: $mod_id
    SCAFFOLD_GROUP: $mod_group
    SCAFFOLD_NAME: $mod_name
    SCAFFOLD_LANGUAGE: $mod_language
    SCAFFOLD_SIDE: $mod_side
    SCAFFOLD_DATAGEN: (if $no_datagen { "0" } else { $env_datagen })
  }

  cd $dest
  with-env $scaffold_env {
    nu scaffold.nu --non-interactive
  }

  print ""
  print $"created ./($mod_id)"
  print $"  cd ($mod_id)"
  if $mod_side != "server" {
    print "  ./mcw :fabric:runClient"
  } else {
    print "  ./mcw :fabric:runServer"
  }
  print "  # or enter nix develop and use ./gradlew"
}
