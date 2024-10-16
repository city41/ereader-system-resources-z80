    ; RST 0
    ERAPI_FadeIn                   = 0x00
    ERAPI_FadeOut                  = 0x01
    ERAPI_LoadSystemBackground     = 0x10
    ERAPI_SetBackgroundOffset      = 0x11
    ERAPI_SetBackgroundAutoScroll  = 0x12
    ERAPI_SetBackgroundMode        = 0x19

    ;; can't get this to work, I am assuming it changes background priority
    ERAPI_LayerShow                = 0x20
    ERAPI_LayerHide                = 0x21
    ERAPI_LoadCustomBackground     = 0x2D
    ERAPI_CreateSystemSprite       = 0x30
    ERAPI_SpriteFree               = 0x31
    ERAPI_SetSpritePos             = 0x32
    ERAPI_SetSpriteFrame           = 0x36
    ERAPI_SpriteAutoAnimate        = 0x3c
    ERAPI_SpriteShow               = 0x46
    ERAPI_SpriteHide               = 0x47
    ERAPI_SpriteMirrorToggle       = 0x48
    ERAPI_SpriteCreate             = 0x4D
    ERAPI_SpriteAutoScaleUntilSize = 0x5B
    ERAPI_SetBackgroundPalette     = 0x7E
    ERAPI_CreateRegion             = 0x90
    ERAPI_SetRegionColor           = 0x91
    ERAPI_ClearRegion              = 0x92
    ERAPI_SetTextColor             = 0x98
    ERAPI_DrawText                 = 0x99
    ERAPI_SetTextSize              = 0x9A
    ERAPI_SystemSpriteIdIsValid    = 0xF0

    ; RST 8
    ERAPI_Exit                     = 0x00
    ERAPI_Mul8                     = 0x01
    ERAPI_Mul16                    = 0x02
    ERAPI_Div                      = 0x03
    ERAPI_PlaySystemSound          = 0x05
    ERAPI_PauseSound               = 0x16
