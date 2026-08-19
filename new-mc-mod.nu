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

  let env_kotlin = (env-string "SCAFFOLD_KOTLIN")
  let env_scala = (env-string "SCAFFOLD_SCALA")
  let env_datagen = (env-string "SCAFFOLD_DATAGEN")

  let scaffold_env = {
    SCAFFOLD_ID: $mod_id
    SCAFFOLD_GROUP: $mod_group
    SCAFFOLD_NAME: $mod_name
    SCAFFOLD_KOTLIN: (if $kotlin { "1" } else { $env_kotlin })
    SCAFFOLD_SCALA: (if $scala { "1" } else { $env_scala })
    SCAFFOLD_DATAGEN: (if $no_datagen { "0" } else { $env_datagen })
  }

  cd $dest
  with-env $scaffold_env {
    nu scaffold.nu --non-interactive
  }

  print ""
  print $"created ./($mod_id)"
  print $"  cd ($mod_id)"
  print "  ./mcw :fabric:runClient"
  print "  # or enter nix develop and use ./gradlew"
}
