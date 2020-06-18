# Corona Plugin Submission Template

Please read the [Plugin Submission Guidelines](https://docs.coronalabs.com/native/plugin/submission.html) for more information.

This template provides stubs for two of the top level directories that are needed in your plugin submission:

* `metadata.json` You should modify this with information about your company and plugin
* `plugins/`
    + `VERSION/`
        - `android/`
            - `metadata.lua` This is a stub for the metadata describing the binary
            - `resources/`
                - `package.txt` Contains the name of the package for which to generate an R file.
                - `assets/` This folder contains files to be added to the assets folder and can be retrieved via the assets manager
                - `res/` This folder contains files you want to put in the res folder and can be access via [getIdentifier](http://developer.android.com/reference/android/content/res/Resources.html#getIdentifier(java.lang.String, java.lang.String, java.lang.String)).  The structure of the subfolder is exactly the same as the res folder.
        - `iphone/`
            - `metadata.lua` This is a stub for the metadata describing the binary
            - `resources/` This folder will contain all the resources you want in the app.  It is relative to the root app directory.
        - `iphone-sim/`
            - `metadata.lua` This is a stub for the metadata describing the binary
            - `resources/` This folder will contain all the resources you want in the app.  It is relative to the root app directory.
        - `mac-sim/`
            - `plugin_solarjs.lua` This is a stub Lua file to be used by the Corona Simulator
        - `win32-sim/`
            - `plugin_solarjs.lua` This is a stub Lua file to be used by the Corona Simulator

The complete directory structure is explained in the [Plugin Submission Guidelines](https://docs.coronalabs.com/native/plugin/submission.html)


## Replacing strings in ALL CAPS

In each file there are strings in ALL CAPS that should be replaced with information specific to your plugin. You should 'grep' for the following strings and replace them appropriately:

* `solarjs` This should be the name of the plugin. 
    + You should preserve any prefix such as `plugin.` or `plugin_`. 
    + Note the trailing `.` and `_`, respectively.
    + Don't forget to rename any file __and__ directory with `solarjs` in it, e.g. `plugin_solarjs.lua` => `plugin_openudid.lua`.
* `VERSION`
    + This is a directory
    + You should rename this to the daily build version of Corona in which the plugin is available, e.g. `2017.3070`.
* `contact` The e-mail of the main contact person for support.
* `PUBLISHER_NAME` The brand name of the publisher.
* `joehinkle.io` The url of the publisher
* `REVERSE_joehinkle.io` The reverse domain that uniquely identifies the publisher, e.g. `com.mycompany`.
* `SERVICE_NAME` The name of the service provided by the publisher (if applicable)
* `CORONA_REFERRAL_URL` The referral link if the service requires a separate account registration.

