# E-Reader System-Resource app, ported to z80

This is [AkBKuKu's System-Resources](https://github.com/AkBKukU/e-reader-dev/tree/main/projects/system-resources) E-Reader app ported from GBA to z80.

Since I'm using a pretty bespoke dev environment, assembling this might be tough. But if you just want to try it, the .raw and .bmp files are here in the repo.

## Known Issues

- The backgrounds section doesn't skip bad backgrounds.
- The sprite section doesn't always skip bad sprites and I'm not sure why. It successfully avoids most bad sprites with `ERAPI_SystemSpriteIdIsValid`

## dotcode bmp won't work in mGBA

The dotcode bmp here is 600dpi, which is intended for physical printing (I wrote a [blog post](https://mattgreer.dev/blog/printing-ereader-cards/) with tips on how to do this).

This bmp will not load into mGBA. I'm guessing mGBA wants 300dpi bmps?

If using mGBA, use the .raw file instead. That will scan and load just fine.
