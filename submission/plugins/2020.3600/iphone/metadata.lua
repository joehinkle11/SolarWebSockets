-- iOS / iOS Simulator
local metadata =
{
    plugin =
    {
        format = "staticLibrary",
 
        -- This is the name without the "lib" prefix
        -- In this case, the static library is called "libplugin_openudid.a" should be "plugin_openudid"
        staticLibs = { "plugin_solarwebsockets", },
 
        frameworks = {},
        frameworksOptional = {},
    },
    coronaManifest = {
        dependencies = {
            -- ["shared.memoryBitmap"] = "com.coronalabs",
        },
    },
}
 
return metadata