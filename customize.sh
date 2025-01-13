#!/system/bin/sh

# A guard for devices supporting AIDL only (like Pixel 9 series) and pre 7.0 audio policy implementations
# Busybox cannot execute {,64} expansion properly unlike mksh, so manually expanded
if [ -z "`ls /vendor/lib64/android.hardware.audio@7.?.so 2>/dev/null`"  -a  -z "`ls /vendor/lib/android.hardware.audio@7.?.so 2>/dev/null`" ] && \
   [ -z "`ls /system/lib64/android.hardware.audio@7.?.so 2>/dev/null`"  -a  -z "`ls /system/lib/android.hardware.audio@7.?.so 2>/dev/null`" ]; then
    abort "  ***
  Aborted: no 7.0 audio policy implementation; 
     this module doesn't support recent AIDL only devices and old ones based on pre 7.0 audio implementations
  ***"
elif [ "`getprop ro.build.product`" = "jfltexx" ]; then
    # Galaxy S4 has a bug for the 7.0 audio policy configuration
    abort "  ***
  Aborted: Galaxy S4 has a bug for the 7.0 audio policy implementation
  ***"
fi

[ -z "$(magisk --path)" ] && alias magisk='ksu-magisk'

. "$MODPATH/customize-functions.sh"

if ! isMagiskMountCompatible; then
    abort '  ***
  Aborted by no Magisk-mirrors:
    try again either
      a.) with official Magisk v27.0 (mounting mirrors), or
      b.) after installing "compatible Magisk-mirroring" Magisk module and rebooting
  ***'
fi

MAGISKTMP="$(magisk --path)/.magisk"

REPLACE=""
REPLACEFILES=""

# Note: almost all equalizers and some apps cannot work for greater than 192kHz audio outputs, but of which quality is far better sometimes
# If you prefer such ones, change "384000" below to "190000" or even "48000"
SampleRatePrimary="384000"
AudioFormatPrimary="AUDIO_FORMAT_PCM_32_BIT"

DRC_enabled="false"
USB_module="usb"
templateFile="$MODPATH/templates/bypass_offload_template.xml"

if [ "`getprop persist.bluetooth.bluetooth_audio_hal.disabled`" = "true" ]; then
    BT_module="a2dp"
elif [ -e "/vendor/lib64/hw/audio.bluetooth.default.so" ]; then
    BT_module="bluetooth"
else
    BT_module="a2dp"
fi

# Check if on a specific device or not
case "`getprop ro.board.platform`" in
    gs* | "zuma" )
        # A conflicting guard for "Hifi maximizer" on Tensor devices
        if [ -e "${MODDIR%/*/*}/modules/hifi-maximizer-mod" ]; then
            abort '  ***
  Aborted: detecting Hifi maximizer already containing this feature on Tensor devices
  ***'
        fi
        
        # Tensor's max. samplerate for internal speakers
        SampleRatePrimary="48000"
        USB_module="usbv2"
        templateFile="$MODPATH/templates/offload_hifi_playback_template.xml"
        ;;
    "pineapple" )
        # POCO F6 cannot output AOSP "bluetooth" driver, but "bluetooth_qti" driver can except its offload driver
        if [ -e "/vendor/lib64/hw/audio.bluetooth_qti.default.so" ]; then
            BT_module="bluetooth_qti"
        fi
        # Workaround for a DRC inverted bug of POCO F6 crDroid 14.0 (Nov. 27, 2024 and later) ROM's
        if [ "`getprop ro.crdroid.device`" = "peridot"  -a  "`getprop ro.build.version.release`" = "14"  -a  "`getprop ro.system_ext.build.date.utc`" -ge "1732697965" ]; then
            DRC_enabled="true"
        fi
        ;;
    mt* )
        # MTK devices max. samplerate for internal speakers
        SampleRatePrimary="48000"
        ;;
    * )
        case "`getprop ro.product.board`" in
             "taro" )
                # for Asus Zenfone 9
                if [ -e "/vendor/lib64/hw/audio.bluetooth_qti.default.so" ]; then
                    BT_module="bluetooth_qti"
                fi
                ;;
            "blueline" )
                ;;
             * )
                ;;
        esac
        ;;
esac

# Set the active configuration file name retrieved from the audio policy server
configXML="`getActivePolicyFile`"

# configXML is usually placed under "/vendor/etc" (or "/vendor/etc/audio"), but
# "/my_product/etc" and "/odm/etc" are used on ColorOS (RealmeUI) and OxygenOS(?)
case "$configXML" in
    /vendor/etc/* | /my_product/etc/* | /odm/etc/* | /system/etc/* | /product/etc/* )
        VolumeFile=$(getVolumeFile "${MAGISKTMP}/mirror/${configXML}")
        if [ -z "$VolumeFile" ]; then
            VolumeFile="/vendor/etc/audio_policy_volumes.xml"
        fi
        
        DefaultVolumeFile=$(getDefaultVolumeFile "${MAGISKTMP}/mirror/${configXML}")
        if [ -z "$DefaultVolumeFile" ]; then
            DefaultVolumeFile="/vendor/etc/default_volume_tables.xml"
        fi
        
        case "${configXML}" in
            /system/* )
                configXML="${configXML#/system}"
            ;;
        esac
        modConfigXML="$MODPATH/system${configXML}"
        
        mkdir -p "${modConfigXML%/*}"
        touch "$modConfigXML"
        
        sed   -e "s|%DRC_ENABLED%|$DRC_enabled|" -e "s|%USB_MODULE%|$USB_module|" -e "s|%BT_MODULE%|$BT_module|" \
                -e "s|%SAMPLING_RATE%|$SampleRatePrimary|" -e "s|%AUDIO_FORMAT%|$AudioFormatPrimary|" \
                -e "s|%VOLUME_FILE%|$VolumeFile|" -e "s|%DEFAULT_VOLUME_FILE%|$DefaultVolumeFile|" \
                "$templateFile" >"$modConfigXML"
        
        chmod 644 "$modConfigXML"
        chcon u:object_r:vendor_configs_file:s0 "$modConfigXML"
        chown root:root "$modConfigXML"
        chmod -R a+rX "${modConfigXML%/*}"
        if [ -z "${REPLACEFILES}" ]; then
            REPLACEFILES="/system${configXML}"
        else
            REPLACEFILES="${REPLACEFILES} /system${configXML}"
        fi
        
        # If "${configXML}" isn't symbolically linked to "$/system/{configXML}", 
        #   disable Magisk's "magic mount" and mount "${configXML}" by this module itself in "service.sh"
        if [ ! -e "/system${configXML}" ]; then
            touch "$MODPATH/skip_mount"
        fi
        ;;
    * )
        ;;
esac

# Note: Don't use "${MAGISKTMP}/mirror/system/vendor/*" instaed of "${MAGISKTMP}/mirror/vendor/*".
# In some cases, the former may link to overlaied "/system/vendor" by Magisk itself (not mirrored original one).

#   "max" below this line means "up to 768kHz unlock";
#    for "up to 384kHz unlock", replace "max" with "full" below this line;
#    for "up to 192kHz unlock", replace "full" with "default" below this line.

for ld in "lib" "lib64"; do
    d="/system/vendor/${ld}"
    for lname in "libalsautils.so" "libalsautilsv2.so"; do
        if [ -r "${MAGISKTMP}/mirror/vendor/${ld}/${lname}"  -a  -r "${d}/${lname}" ]; then
            mkdir -p "${MODPATH}${d}"
            patchClearLock "${MAGISKTMP}/mirror/vendor/${ld}/${lname}" "${MODPATH}${d}/${lname}" "max"

            chmod 644 "${MODPATH}${d}/${lname}"
            chcon u:object_r:vendor_file:s0 "${MODPATH}${d}/${lname}"
            chown root:root "${MODPATH}${d}/${lname}"
            chmod -R a+rX "${MODPATH}${d}"
            if [ -z "${REPLACEFILES}" ]; then
                REPLACEFILES="${d}/${lname}"
            else
                REPLACEFILES="${REPLACEFILES} ${d}/${lname}"
            fi
        fi
    done
    
    for lname in "audio_usb_aoc.so"; do
        if [ -r "${MAGISKTMP}/mirror/vendor/${ld}/${lname}"  -a  -r "${d}/${lname}" ]; then
            mkdir -p "${MODPATH}${d}"
            patchClearTensorOffloadLock "${MAGISKTMP}/mirror/vendor/${ld}/${lname}" "${MODPATH}${d}/${lname}"

            chmod 644 "${MODPATH}${d}/${lname}"
            chcon u:object_r:vendor_file:s0 "${MODPATH}${d}/${lname}"
            chown root:root "${MODPATH}${d}/${lname}"
            chmod -R a+rX "${MODPATH}${d}"
            if [ -z "${REPLACEFILES}" ]; then
                REPLACEFILES="${d}/${lname}"
            else
                REPLACEFILES="${REPLACEFILES} ${d}/${lname}"
            fi
        fi
    done
    
done

fname="/system/vendor/etc/audio_platform_configuration.xml"
if [ -r "$fname" ]; then
    mkdir -p "${MODPATH}${fname%/*}"
    sed -e 's|min_rate="[1-9][0-9]*"|min_rate="44100"|g' \
        -e 's/"MaxSamplingRate=[1-9][0-9]*,/"MaxSamplingRate=192000,/' <"${MAGISKTMP}/mirror${fname#/system}" >"${MODPATH}${fname}"
    touch "${MODPATH}${fname}"
    chmod 644 "${MODPATH}${fname}"
    chcon u:object_r:vendor_configs_file:s0 "${MODPATH}${fname}"
    chown root:root "${MODPATH}${fname}"
    chmod -R a+rX "${MODPATH}${fname%/*}"
    if [ -z "${REPLACEFILES}" ]; then
        REPLACEFILES="${fname}"
    else
        REPLACEFILES="${REPLACEFILES} ${fname}"
    fi
fi

rm -f "$MODPATH/customize-functions.sh" "$MODPATH/LICENSE" "$MODPATH/README.md" "$MODPATH/changelog.md"
rm -rf "$MODPATH/templates"
ui_print_replacelist "${REPLACEFILES}"

if [ -e "${MODPATH%/*/*}/modules/drc-remover" ]; then
    ui_print ""
    ui_print "****************************************************************"
    ui_print " Uninstall \"DRC remover\" manually later; this module includes all its features"
    ui_print "****************************************************************"
    ui_print ""
fi
if [ -e "${MODPATH%/*/*}/modules/usb-samplerate-unlocker" ]; then
    ui_print ""
    ui_print "****************************************************************"
    ui_print " Uninstall \"USB Samplerate Unlocker\" manually later; this module includes all its features"
    ui_print "****************************************************************"
    ui_print ""
fi
