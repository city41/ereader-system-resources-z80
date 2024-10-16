# E-Reader System-Resource app, ported to z80

This is [AkBKuKu's System-Resources](https://github.com/AkBKukU/e-reader-dev/tree/main/projects/system-resources) E-Reader app ported from GBA to z80.

Since I'm using a pretty bespoke dev environment, assembling this might be tough. But if you just want to try it, the .raw and .bmp files are here in the repo.

## Known Issues

- The backgrounds section doesn't skip bad backgrounds.
- The sprite section doesn't always skip bad sprites and I'm not sure why. It successfully avoids most bad sprites with `ERAPI_SystemSpriteIdIsValid`
