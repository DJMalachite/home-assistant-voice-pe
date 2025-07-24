# Home Assistant Voice: Preview Edition

This is the ESPHome source code of the [Home Assistant Voice: Preview Edition](https://www.home-assistant.io/voice-pe/).

See [the documentation](https://voice-pe.home-assistant.io/) for set up and troubleshooting.

If you need to re-install the firmware, [use this installer](https://esphome.github.io/home-assistant-voice-pe/).


# Custom Changes

## home-assistant-voice-BT-Edition.yaml
- Adds BT Activation Sound clip
- Adds E1.31 Support

### Usage
In your ESPHome config file use the following Package entry

```yaml
packages:
  DJMalachite.Home Assistant Voice PE: 
    url: https://github.com/DJMalachite/home-assistant-voice-pe
    ref: dev
    files: [home-assistant-voice-BT-Edition.yaml]
    refresh: 30s```
