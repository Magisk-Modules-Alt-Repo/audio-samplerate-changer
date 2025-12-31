## A Magisk module changing audio samplerates at the system-wide mixer for the best Hi-Fi experience

This module has been developed for casual music lovers to be able to experience the essence of my root script ["USB SampleRate Changer"](https://github.com/yzyhk904/USB_SampleRate_Changer) by the automation of Magisk.

Its features:
<ol>
    <li>Setting the samplerate of the USB HAL audio driver to be maximum automatically (up to 768 kHz & 32 bits; but 192 kHz & 32 bits for Tensor devices only)</li>
    <li>Setting its USB data transfer period to be 2000 usec for reducing jitter, instead of usual 5000 usec</li>
    <li>Setting the samplerate of the AOSP Bluetooth audio driver automatically depending upon a selected codec without double re-sampling unlike offload drivers</li>
    <li>Setting the samplerate of internal speakers to be maximum; 384 kHz & 32 bits for Qcom devices, 48 kHz & 32 bits for others</li>
    <li>Default re-sampling parameters are the same as <a href="https://github.com/Magisk-Modules-Alt-Repo/resampling-for-cheapies">"Resampling for cheapies"</a> (can be overridden by other modules), i.e., very mastering level quality being much better than the over-sammpling quality of very expensive DAC's applied when "The bit-perfect mode"</li>
    <li>Optimizing I/O kernel tunables for reducing jitter (most effective and almost safe as kernel tuning)</li>
    <li>Designed for using <a href="https://github.com/Magisk-Modules-Alt-Repo/audio-misc-settings">"Audio Msic. Settings"</a> or <a href="https://github.com/yzyhk904/hifi-maximizer-mod">"Hifi maximizer"</a> together, but can be used by itself only</li>
    <ol><li>Since the above two modules override re-sampling parameters, use <a href="https://github.com/Magisk-Modules-Alt-Repo/resampling-for-cheapies">"Resampling for cheapies"</a> in addition if you use cheapie devices (Bluetooth LDAC earphones, cheap USB DAC's, and internal speakers, etc.)</li>
    <li>Strongly recommending to install <a href="https://github.com/Magisk-Modules-Alt-Repo/audio-jitter-silencer">"Audio jitter silencer"</a> together and uninstall (or disable) "Digital Wellbeing" app (for reducing very large jitters which this module cannot reduce by itself)!</li></ol>
    <li>Disabling DRC (a kind of compression) if enabled, and the call screening framework under audio HAL's for reducing jitter</li>
</ol>
<br/>
<br/>

Notes:
* This module can run only on devices using a 7.0 audio policy configuration prevailing since Android 14 or so including custom ROM's supporting relatively old ones (especially phh GSI's doing since Android 12), excluding recent AIDL only ones like Pixel 9 series.
* This module has been tested on LineageOS and crDroid ROM's, and phh GSI's (Android 14~16, and Qualcomm SoC & MediaTek SoC & Tensors combinations). 
* Also don't forget disabling "Absolute Volume" of Bluetooth devices in developer settings and setting a volume at the Bluetooth devices side to be maximum for the best audio quality, though most people may think inversely.
* Almost all equalizers and some apps (using a much worse internal re-sampler to output; e.g. old Am@zon music app, some VOIP apps, etc.) cannot work for greater than 192 kHz audio outputs (but of which quality is far better sometimes). And the latest Am@zon music app re-samples up to 192 kHz for such high frequency audio output, i.e. incurs much worse double re-sampling. If you prefer such ones, modify `SampleRatePrimary="384000"` to `SampleRatePrimary="192000"` or even `SampleRatePrimary="48000"` (these samplerates affect only internal speakers and wired headsets), and also the third argument of `patchClearLock` command from "max" (means up to 768 kHz) to "default" (does up to 192 kHz) in "customize.sh" in a ZIP file of this module and install (or update) the modified one.
* <a href="https://github.com/Magisk-Modules-Alt-Repo/drc-remover">"DRC remover"</a> and <a href="https://github.com/Magisk-Modules-Alt-Repo/usb-samplerate-unlocker">"USB Samplerate Unlocker"</a> are already  included; Don't try installing them together</li>


## DISCLAIMER

* I am not responsible for any damage that may occur to your device, so it is your own choice whether to attempt this module or not.

##
