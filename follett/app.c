#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "peripheral/pio/plib_pio.h"
#include "system/time/sys_time.h"
#include "gfx/legato/generated/le_gen_init.h"
#include "gfx/legato/legato.h"
#include "gfx/legato/widget/legato_widget.h"
#include "gfx/legato/widget/button/legato_widget_button.h"
#include "bsp/bsp.h"
#include "configuration.h"
#include "screens/start.h"
#include "app.h"
#include "peripheral/pwm/plib_pwm.h"
#include "timer.h"
#include "comTaskDrv.h"
//#include "cmd_fifo.h"
#include "modbus.h"
#include "app_touchless.h"
#include "usb/src/usb_host_local.h"
#include "usb/usb_host.h"
#include "system/fs/sys_fs.h"
#include "usb/usb_host_hid_keyboard.h"
#include "app_file.h"
#include "app_json.h"
#include "initModbusReg.h"
#include "peripheral/pwm/plib_pwm.h"
#include "peripheral\lcdc\plib_lcdc.h"
#include "screenStack.h"
#include "splash_utility.h"
#include "splash.h"
#include "main_menu.h"
#include "service_gear_motor.h"
#include "self_help.h"

#include "definitions.h"
#include "peripheral\wdt\plib_wdt.h"
#include "eventlog.h"

bool stopClrWDT = false;
APP_STATES appState = APP_MOUNT_WAIT;
int8_t initModcount = -1;
static int8_t wdt_pos = 0;
uint16_t temp_for_uart;
uint16_t firmwareVal = 0xffff;

void WDT_callback(uintptr_t context) {
    printf("%d\n", wdt_pos);
}

void APP_Initialize(void) {
    printf("app init\n");

    Ms100Periodic_Initialize();

    modBus->_com_Init_(modBus);

    appState = APP_MOUNT_WAIT;

    PWM_ChannelDutySet(PWM_CHANNEL_2, 0); // White
    PWM_ChannelDutySet(PWM_CHANNEL_3, 0); // Red
    PWM_ChannelsStart(PWM_CHANNEL_2_MASK);
    PWM_ChannelsStart(PWM_CHANNEL_3_MASK);

    LCDC_SetPWMCompareValue(55);

    //PIO_PinInterruptCallbackRegister(GPIO_PA23_PIN, encoderCallback, (uintptr_t)NULL);
    //PIO_PinInterruptEnable(GPIO_PA23_PIN);   
    //PIO_PinInterruptCallbackRegister(DET_HOB2_PA25_PIN, getSingleOrDualCallback, (uintptr_t)NULL);
    //PIO_PinInterruptEnable(DET_HOB2_PA25_PIN);   
    //WDT_CallbackRegister(WDT_callback, 0);
    APP_Touchless_Initialize();
    //printf("sethandler\n");
    //for usb function, now only test FS.
    //  USB_HOST_HID_KEYBOARD_EventHandlerSet(USBHostHIDKeyboardEventHandler); // initialize USB scanner event handler
    SYS_FS_EventHandlerSet(SYS_FS_EventHandler, 0); //added by bing 
    USB_HOST_EventHandlerSet(&USBHostEventHandler, 0); // initialize USB device event handler
    USB_HOST_BusEnable(0);
}

bool APPinitWithDefault(char ** memJsonFileP) {
    if (memJsonFileP == NULL) {
        DBG_P;
        return false;
    }
    if (*memJsonFileP != NULL) {
        free(*memJsonFileP);
        *memJsonFileP = NULL;
    }
    *memJsonFileP = calloc(9000, 1);
    if (*memJsonFileP == NULL) {
        printf("no enough mem to json");
        DBG_P;
        return false;
    }

    strcpy(*memJsonFileP, default_json_data);
    printf("copy default to mem\n");
    return true;
}

void APPinitWithJson(void) {
    if (false != readJsonFromDrvToMem(&sst, CONFIG_FILE, &memJsonFile)) return;

    APPinitWithDefault(&memJsonFile);
    printf("read sst json fail,init with default config.json\n");
    return;
}

bool APPinitWithSettingFile(void) {
    if (false == readJsonFromDrvToMem(&sst, SETTING_FILE, &memSettingFile)) {
        printf("read setting json from sst fail");
        DBG_P;
        return false;
    }

    if (false != settingJsonParse()) return true;
    printf("settingJsonParse fail");
    DBG_P;
    return false;
}

bool setSettingFileToDefault(void) {
    memSettingFile = calloc(600, 1);
    if (memSettingFile == NULL) {
        printf("no enough mem for setting");
        DBG_P;
        return false;
    }
    if (memSettingFile != NULL) {
        strcpy(memSettingFile, default_setting_data);

        if (writeJsonFromMemtoDrv(&sst, SETTING_FILE, default_setting_data))
            return true;

        printf("write default setting json to sst fail");
        DBG_P;
        return false;
    }
    printf("no enough mem to json\n");
    return false;
}

void copyConfigJsonToSettingJson(void) {
    int32_t val;
    char* str;
    str = calloc(150, 1);
    if (str == NULL) {
        printf("no mem");
        DBG_P;
        return;
    }

    int8_t i;
    for (i = 0; i < 8; i++) {
        readWriteValInJson(1, root, &val, &str, 149, 2, "settings", settingkey[i]);
        readWriteValInJson(0, settingRoot, &val, &str, 149, 1, settingkey[i]);
    }
    for (i = 8; i < 14; i++) {
        readWriteValInJson(1, root, &val, &str, 149, 4, "languages", "english", "contact", settingkey[i]);
        readWriteValInJson(0, settingRoot, &val, &str, 149, 1, settingkey[i]);
    }
    for (int8_t i = 0; i < 14; i++) {
        readWriteValInJson(1, settingRoot, &val, &str, 149, 1, settingkey[i]);
        printf("val = %ld,  str = %s \n", val, str);
    }
    saveJsonChangeToDev(&sst, SETTING_FILE, settingRoot);
    free(str);
}

void mountTask(void) {
    sst.drvDetected = mountDiskState(&sst, true);
    usb.drvDetected = mountDiskState(&usb, false);
}

#define CMD_TIME_OUT 1

void modBusPoll(void) {

    if (cmdTimeout_timer > CMD_TIME_OUT) //modbus cmd timeout; reset uart and init modbus;
    {
        initModBus();
        FLEXCOM0_USART_Initialize();
        modBus->_com_Init_(modBus);
        return;
    }

    if (-1 != cmdTimeout_timer) return; //modbus busy;

    static uint8_t nextCMD = 0;

    uint8_t modNo = (count256 % 100) / 10;

    switch (modNo) {
        case 0: if (nextCMD == 0) {
                readAI_Rd_RegCmd(SENSOR_REGISTER, 1, modBus);
                nextCMD++;
            }
            break;
        case 1:if (nextCMD == 1) {
                readAO_Wr_H_RegCmd(OUTPUT_REGISTER, 1, modBus);
                nextCMD++;
            }
            break;
        case 2:if (nextCMD == 2) {
                readAI_Rd_RegCmd(GEAR_CURRENT_REGISTER, 1, modBus);
                nextCMD++;
            }
            break;
        case 3:if (nextCMD == 3) {
                readAO_Wr_H_RegCmd(PM_DUE_REGISTER, 1, modBus);
                nextCMD++;
            }
            break;
        case 4:if (nextCMD == 4) {
                readAI_Rd_RegCmd(GEAR_CURRENT_MAX_REGISTER, 1, modBus);
                nextCMD++;
            }
            break;
        case 5:if (nextCMD == 5) {
                readAO_Wr_H_RegCmd(FILTER_DUE_REGISTER, 1, modBus);
                nextCMD++;
            }
            break;
        case 6:if (nextCMD == 6) {
                readAI_Rd_RegCmd(GEAR_CURRENT_MIN_REGISTER, 1, modBus);
                nextCMD++;
            }
            break;
        case 7:if (nextCMD == 7) {
                readAI_Rd_RegCmd(STATUS_REGISTER, 1, modBus);
                nextCMD++;
            }
            break;
        case 8:if (nextCMD == 8) {
                if (firmwareVal == 0xffff)
                    readAI_Rd_RegCmd(IMCREVISION_REGISTER, 1, modBus);
                else
                    readAI_Rd_RegCmd(HOT_WATER_TEMP_REGISTER, 1, modBus);
                nextCMD++;
            }
            break;
        case 9: if (nextCMD >= 9) nextCMD = 0;
            break; //leMemoryPrintReport();break; 

        default: break;
    }
}

void testDue(void) {
    //    pmDueRegVal = pmDueRegVal+20;
    //    filterDueRegVal = filterDueRegVal +30;
    //    if(pmDueRegVal > 12*30) pmDueRegVal = 0;
    //    if((filterDueRegVal++) > 12*30) filterDueRegVal = 0;
    //
    //    outputRegVal.w ++;
    //    //sensorRegVal.w ++;
    //    gearCurrentRegVal = (gearCurrentRegVal > 511)?0:(gearCurrentRegVal+1);

    //gearCurrentMaxRegVal++;
    //gearCurrentMinRegVal++;

    firmwareVal = 134;
    statusRegVal.w = ~statusRegVal.w;

    //statusRegVal.w =((statusRegVal.w) == 0)? 1:(statusRegVal.w) << 1;

    //    sensorRegVal.w =(((sensorRegVal.w)&0x3f) == 0)? 1:(sensorRegVal.w) << 1;
    //   
    //    if((hotWaterTempRegVal++) > 185) hotWaterTempRegVal = 185;
    //    hotWaterTempRegVal ++;
}

void dueAlert(void) {
    static int8_t alert = 3;
    filterDue = 30 * ((int16_t) ((settingRegVal.w) >> 8)&0x0f) -(int16_t) filterDueRegVal;
    PM_Due = 30 * ((int16_t) ((settingRegVal.w) >> 12)&0x0f) - (int16_t) pmDueRegVal;
    //if(splashInput.evtButton != HOLD_NONE) return;

    if ((filterDue > 0) && (PM_Due > 0)&&(alert != 0)) {
        alert = 0;
        splash_panelDue->fn->setVisible(splash_panelDue, LE_FALSE);
        return;
    }

    if ((alert == 1)&&(PM_Due <= 0)) return;
    if ((alert == 2)&&(filterDue <= 0)) return;
    if ((alert != 1)&&(PM_Due <= 0)) {
        alert = 1;
        splash_LblDueAlert ->fn->setString(splash_LblDueAlert, (leString*) (&string_ALERT_PMDue));
        splash_panelDue->fn->setVisible(splash_panelDue, LE_TRUE);
    } else if ((alert != 2)&&(filterDue <= 0)) {
        alert = 2;
        splash_LblDueAlert ->fn->setString(splash_LblDueAlert, (leString*) (&string_ALERT_FilterReplacementRequired));
        splash_panelDue->fn->setVisible(splash_panelDue, LE_TRUE);
    }

    return;
}

void alertUI(void) {
    if ((!IN_UI(screenID_splash))&&(!IN_UI(screenID_alert3))&&
            (!IN_UI(screenID_alert2))) return;

    switch (getCurScreen()) {
        case screenID_splash:
            if (((sensorRegVal.w)& 0x08) != 0) {
                PUSH_SHOW(screenID_alert3) return;
            }
            if (((sensorRegVal.w)& 0x04) != 0) {
                PUSH_SHOW(screenID_alert2) return;
            }

            dueAlert();
            break;
        case screenID_alert3:
            if (((sensorRegVal.w)& 0x08) != 0) return;
            popScreen();
            if (((sensorRegVal.w)& 0x04) != 0) {
                PUSH_SHOW(screenID_alert2) return;
            }
            SHOW(screenID_splash)
                    //dueAlert();            
            break;

        case screenID_alert2:
            if (((sensorRegVal.w)& 0x04) != 0) return;

            popScreen();

            if (((sensorRegVal.w)& 0x08) != 0) {
                PUSH_SHOW(screenID_alert3) return;
            }
            SHOW(screenID_splash)
                    //dueAlert();            
            break;
        default:break;
    }
}

extern int8_t start_UI_delay5s;

void initSensorFronJson(void) {
    touchLessCfg[11] = readSetValFromSettingJson("sensor1", 32);
    touchLessCfg[13] = readSetValFromSettingJson("sensor2", 32);
    touchLessCfg[15] = readSetValFromSettingJson("sensor3", 32);
}

void updateAction(void) {
    uint8_t modNo = count256 % 50;
    static uint8_t nextUpdate = 0;
    switch (modNo / 10) {
        case 0: if (nextUpdate == 0) {
                updateGearMotor();
                nextUpdate++;
            }
            break;

        case 1: if (nextUpdate == 1) {
                alertUI();
                nextUpdate++;
            }
            break;
        case 2: if (nextUpdate == 2) {
                mainMenuAlert();
                nextUpdate++;
            }
            break;

        case 3: if (nextUpdate == 3) {
                selfHelpMenuAlert();
                nextUpdate++;
            }
            break;
        case 4: if (nextUpdate == 4) {
                updateEveLog();
                nextUpdate = 0;
            }
            break;

        default:break;
    }
}

extern bool logoLoad;

void APP_Tasks(void) {

    static bool WDT_ON = false;
    //if((WDT_ON)&&(IN_UI(screenID_splash))) WDT_Clear();
    //if((WDT_ON)&&(!stopClrWDT)) WDT_Clear();
    WDT_Clear();
    mountTask();
    if (count256 % 20 < 10) LED_RED_Off();
    else LED_RED_On(); //heartbeat

    switch (appState) {
        case APP_MOUNT_WAIT:
            if (SYS_FS_EVENT_MOUNT == sst.Event) {
                appState = APP_INIT;
            }
            break;

        case APP_INIT:
            if (read_logo_from_flash())
                logo_process();
            logoLoad = true;
            APPinitWithJson();

            if (memJsonFile == NULL) {
                printf("memJsonFile null\n");
                jsonParse(default_json_data, &root);
            } else jsonParse(memJsonFile, &root);

            free(memJsonFile);
            memJsonFile = NULL;

            if (false == APPinitWithSettingFile()) {
                setSettingFileToDefault();
                settingJsonParse();
                copyConfigJsonToSettingJson();
            }

            free(memSettingFile);
            memSettingFile = NULL;

            appState = APP_START_UI;
            break;

        case APP_START_UI:
            initSensorFronJson();
            sendInitToMachine();
            initLogEvent();
            appState = APP_STANDBY;
            break;

        case APP_STANDBY:
            if ((!WDT_ON) &&(IN_UI(screenID_splash))) {
                WDT_Enable();
                WDT_ON = true;
            }
            WDT_Clear();
            lockTimerFnInApp();
            if (start_UI_delay5s == 3) {
                start_UI_delay5s = -1;
                PUSH_SHOW(screenID_splash);
            }
            if ((splashInput.evtButton != HOLD_NONE) || (splashInput.evtSensor != HOLD_NONE)) break;
            modBusPoll();
            updateAction();
            break;

        default:
            break;
    }
}


