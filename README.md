# Cartridge Tilt

You can either run main.lua with Lua or as an executable script, like so:

```bash
# Run with Lua
$ lua main.lua [args]
```

```bash
# Run as an executable script
$ chmod +x main.lua
$ ./main.lua [args]
```

The script accepts the following arguments:

```
Arguments:
  -d, --directory       Set the directory to generate the files in (if not provided as the first argument)
  -s, --seed            Set the random seed used to generate levels (defaults to "Cartridge Tilt")
  -v, --verbosity       Set how in-depth the info printed to the console is (0-5, default 1)
Level format:
      --1.6             Generate levels in vanilla Mari0 1.6 format (default)
      --AE              Generate levels in Alesan's Entities format
Level parameters:
  -w, --worlds          Number of worlds to generate (default 8)
  -l, --levels          Number of levels to generate per world (default 4, other values not supported by 1.6)
      --height          Height of levels to generate (experimental, not supported by 1.6)
Generator options:
      --no-distortions  Turn off distortions (random blocks)
      --no-enemies      Turn off enemies
```
