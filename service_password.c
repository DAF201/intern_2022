#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "gfx/legato/generated/le_gen_init.h"
#include "system/time/sys_time.h"
#include "gfx/legato/legato.h"
#include "gfx/legato/widget/legato_widget.h"
#include "gfx/legato/widget/button/legato_widget_button.h"
#include "bsp/bsp.h"
#include "configuration.h"
#include "app.h"
#include "peripheral/pwm/plib_pwm.h"
#include "screenStack.h"

leFixedString* lePassword;
static int32_t passVal = -1;
static uint8_t zeroNo = 0;

void printarr(int * array, int size) {
    for (int i = 0; i < size / 4; i++) {
        printf("%d ", array[i]);
    }
    printf("\n");
}

int get_array_size(int *array, int kw) {
    int i = 0;
    while (array[i] != kw) {
        i++;
    }
    return i;
}

void star_update(int index, int statu_code) {
    if (statu_code == 0) {
        char star_box[11] = "**********";
        if (index == 0) strcpy(star_box, "          \0");
        else star_box[index] = '\0';
        //    printf("%d\n", statu_code);
        lePassword->fn->setFromCStr(lePassword, star_box);
        service_password_LblInputBox->fn->setString(service_password_LblInputBox, (leString*) lePassword);
    }
    if (statu_code == -1) {
        lePassword->fn->setFromCStr(lePassword, "FAILED");
        service_password_LblInputBox->fn->setString(service_password_LblInputBox, (leString*) lePassword);
    }

}

//void updatePassCode(int32_t passVal) {
//    char charPassCode[20];
//    uint8_t riskNo = 0;
//
//    if ((passVal == -1) || (passVal == 0)&&(zeroNo == 0)) {
//        memset(charPassCode, 0x20, 20);
//        charPassCode[19] = '\0';
//    } else if (passVal == -2) {
//        sprintf(charPassCode, "Failed");
//    } else {
//        for (uint8_t i = 0; i < zeroNo; i++) //prefix zero number
//        {
//            charPassCode[i] = '*';
//            charPassCode[i + 1] = '\0';
//        }
//        while (passVal > 0) {
//            riskNo++;
//            passVal = passVal / 10;
//            charPassCode[zeroNo + riskNo - 1] = '*';
//            charPassCode[zeroNo + riskNo] = '\0';
//        }
//    }
//    lePassword->fn->setFromCStr(lePassword, charPassCode);
//    service_password_LblInputBox->fn->setString(service_password_LblInputBox, (leString*) lePassword);
//}

uint32_t keyVal(uint32_t row, uint32_t col) {
    return (col * 3 + row + 1);
}

int password[11];
int correct_password[11] = {1, 1, 1, 1, 10};
int password_index = 0;

void event_service_password_KeyPad_OnKeyClick(leKeyPadWidget* wgt, leButtonWidget* cell, uint32_t row, uint32_t col) {

    int this_key = keyVal(col, row);
    int statu_code = 0;

    if (password_index > 9) {
        //        printf("this size of the pw is %d\n", password_index);
        password[password_index] = 10;

        switch (this_key) {
            case 10:
            {
                if (password_index != 0)
                    password_index--;
                password[password_index] = 10;
                //                printarr(password, sizeof (password));
                break;
            }

            case 12:
            {
                password[password_index] = 10;
                int j = 0;
                int password_correct = 1;
                //                printarr(password, sizeof (password));
                //            printf("size of the password = %d\n", password_index);

                if (get_array_size(correct_password, 10) != password_index) {
                    password_correct = 0;
                    password_index = 0;
                    statu_code = -1;
                    //                    printf("Fail\n");
                    break;
                }

                while (password[j] != 10) {
                    if (password[j] != correct_password[j]) {
                        password_correct = 0;
                        break;
                    }
                    j++;
                }
                password_index = 0;

                if (password_correct) {
                    statu_code = 1;
                    //                    printf("password correct\n");
                    legato_showScreen(screenID_service_advanced);
                } else {
                    statu_code = -1;
                    //                    printf("failed\n");
                }

                break;
            }

            default:
            {
                break;
            }
        }
        star_update(password_index, statu_code);
        return;
    }

    switch (this_key) {
        case 1 ... 9:
        case 11:
        {
            if (this_key == 11) {
                password[password_index] = 0;
                password_index++;
            } else {
                password[password_index] = this_key;
                password_index++;
            }
            break;
        }

        case 10:
        {
            if (password_index != 0)
                password_index--;
            password[password_index] = 10;
            //            printarr(password, sizeof (password));
            break;
        }

        case 12:
        {
            password[password_index] = 10;
            int j = 0;
            int password_correct = 1;
            //            printarr(password, sizeof (password));
            //            printf("size of the password = %d\n", password_index);

            if (get_array_size(correct_password, 10) != password_index) {
                password_correct = 0;
                password_index = 0;
                statu_code = -1;
                //                printf("Fail\n");
                break;
            }

            while (password[j] != 10) {
                if (password[j] != correct_password[j]) {
                    password_correct = 0;
                    break;
                }
                j++;
            }
            password_index = 0;

            if (password_correct) {
                statu_code = 1;
                //                printf("password correct\n");
                legato_showScreen(screenID_service_advanced);
            } else {
                statu_code = -1;
                //                printf("failed\n");
            }

            break;
        }

        default:
        {
            break;
        }
    }
    star_update(password_index, statu_code);
}

//void event_service_password_KeyPad_OnKeyClick(leKeyPadWidget* wgt, leButtonWidget* cell, uint32_t row, uint32_t col) {
//    if (passVal > 1000000000) return;
//
//    uint32_t this_key = keyVal(row, col);
//
//    switch (this_key) {
//        case 1 ... 9:
//            if (passVal < 1000000000)
//                passVal = (passVal <= 0) ? this_key : (passVal * 10 + this_key);
//            break;
//        case 10:
//            if ((passVal == 0)&&(zeroNo > 0)) {
//                zeroNo--;
//                break;
//            }
//            if ((passVal == 0)&&(zeroNo == 0)) {
//                passVal = -1;
//                break;
//            }
//            passVal = passVal / 10;
//            break;
//        case 11:
//            if (passVal <= 0) {
//                passVal = 0;
//                zeroNo++;
//                break;
//            }
//            if (passVal < 1000000000) passVal = passVal * 10;
//            break;
//        case 12:
//            if (passVal == 1111) {
//                passVal = -1;
//                zeroNo = 0;
//                legato_showScreen(screenID_service_advanced);
//            } else {
//
//                zeroNo = 0;
//                passVal = -2;
//            }
//            break;
//
//        default:
//            break;
//    }
//
//    updatePassCode(passVal);
//}

void event_service_password_BtnHome_OnReleased(leButtonWidget * btn) {

    HOME
}

void event_service_password_BtnExit_OnReleased(leButtonWidget * btn) {

    main_menu_btnNo = -1;
    BACK
}

void service_password_OnShow(void) {
    printf("enter pass\n");
    passVal = -1;
    zeroNo = 0;
    leChar* leCharP = (leChar*) malloc(sizeof (leChar)*20);
    if (leCharP == NULL) {
        printf("no memory for malloc\n");

        return;
    }
    lePassword = leFixedString_New(leCharP, 20);
    lePassword->fn->setFont(lePassword, (leFont *) & Roboto_Regular_16o);
}

void service_password_OnHide(void) {

    delLeStr(lePassword);
    passVal = -1;
    zeroNo = 0;
}

void event_service_password_BtnSensor_OnReleased(leButtonWidget * btn) {
    PUSH_SHOW(screenID_Sensor)
}