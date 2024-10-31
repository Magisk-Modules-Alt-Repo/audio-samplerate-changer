#!/system/bin/sh
#
# This script will be executed in service mode
#

MODDIR=${0%/*}

. "$MODDIR/service-functions.sh"
. "$MODDIR/jitter-reducer-functions.shlib"

#
function optimizeIoJitter()
{
# A conflicting gurd for "Hifi maximizer" module
    if [ -e "${MODDIR%/*/*}/modules/hifi-maximizer-mod" ]; then
        return 1
    fi
    reduceIoJitter 1 '*' 'boost' 0
}

#
function setResamplingParameters()
{
#  A conflicting guard for "Resampling-for-cheapies" and other my modules
if [ \( -e "${MODDIR%/*/*}/modules/resampling-for-cheapies"  -a  ! -e "${MODDIR%/*/*}/modules/resampling-for-cheapies/disable" \) \
        -o  -e "${MODDIR%/*/*}/modules_update/resampling-for-cheapies" ] || \
    [ \( -e "${MODDIR%/*/*}/modules/audio-misc-settings"  -a  ! -e "${MODDIR%/*/*}/modules/audio-misc-settings/disable" \) \
        -o  -e "${MODDIR%/*/*}/modules_update/audio-misc-settings" ] || \
    [ \( -e "${MODDIR%/*/*}/modules/hifi-maximizer-mod"  -a  ! -e "${MODDIR%/*/*}/modules/hifi-maximizer-mod/disable" \) \
        -o  -e "${MODDIR%/*/*}/modules_update/hifi-maximizer-mod" ]; then
        return 1
    fi

#  Workaround for recent Pixel Firmwares (not to reboot when resetprop'ing)
    resetprop --delete ro.audio.resampler.psd.enable_at_samplerate
    resetprop --delete ro.audio.resampler.psd.stopband
    resetprop --delete ro.audio.resampler.psd.halflength
    resetprop --delete ro.audio.resampler.psd.cutoff_percent
    resetprop --delete ro.audio.resampler.psd.tbwcheat
#  End of workaround
    
    resetprop ro.audio.resampler.psd.enable_at_samplerate 44100
    resetprop ro.audio.resampler.psd.stopband 194
    resetprop ro.audio.resampler.psd.halflength 520
    
    #  If you feel your LDAC earphones or "cheapie" DAC wouldn't become to sound well or loses mellowness at all, 
    #  try replacing "85" (below)  with "86" or "87" for appropriately cutting off ultrasonic noise causing intermodulation
    #
    resetprop ro.audio.resampler.psd.cutoff_percent 85
    
    #  Uncomment the following resetprop lines if you intend to replay only 44.1 kHz & 16 and 24 bit tracks; 
    #  If you feel your LDAC earphones or "cheapie" DAC wouldn't become to sound well or loses mellowness at all, 
    #  try replacing "93" (below)  with "94" or "95"  for appropriately cutting off ultrasonic noise causing intermodulation
    #
    #resetprop ro.audio.resampler.psd.stopband 179
    #resetprop ro.audio.resampler.psd.cutoff_percent 93

    #  Uncomment the following resetprop lines if you intend to replay only 96 kHz & 24 bit Hires. tracks.
    #  If you feel your LDAC earphones or "cheapie" DAC wouldn't become to sound well, 
    #  try replacing "43" (below)  with "44" for appropriately cutting off ultrasonic noise causing intermodulation
    #
    #resetprop ro.audio.resampler.psd.enable_at_samplerate 96000
    #resetprop ro.audio.resampler.psd.cutoff_percent 43

    reloadAudioserver
}

# sleep more than 30 secs (waitAudioServer) needed for "settings" commands to become effective in an orphan process

(((waitAudioServer; setResamplingParameters; optimizeIoJitter; remountFile "$MODDIR" )  0<&- &>"/dev/null" &) &)
