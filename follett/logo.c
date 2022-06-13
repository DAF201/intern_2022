#include "logo.h"

bool static guardOpenFile(fileDevState_t * dev,
        char* filename,
        SYS_FS_FILE_OPEN_ATTRIBUTES rw) {
    //printf("name: %s\n",dev->deviceType);
    if (dev->Event != SYS_FS_EVENT_MOUNT) {
        //printf("didn't mount,can't open\n"); DBG_P;
        return false;
    }

    if (SYS_FS_CurrentDriveSet(dev->mountType) != SYS_FS_RES_SUCCESS) {
        //printf("current drive didn't set ok\n"); DBG_P;
        return false;
    }

    dev->fileHandle = SYS_FS_FileOpen(filename, rw);
    if (dev->fileHandle == SYS_FS_HANDLE_INVALID) {
        //printf("handle fail\n");DBG_P;
        return false;
    }

    return true;
}

char *dec_to_hex(int dec) {
    char hex[5];
    sprintf(hex, "%x", dec);
    puts(hex);
    return hex;
}

int read_image(fileDevState_t *drv, char *file_name, char **file_data_array) {
    if (file_data_array == NULL) {
        DBG_P;
        return false;
    }
    if (*file_data_array != NULL) {
        printf("file_data_array didn't free");
        DBG_P;
        free(*file_data_array);
        *file_data_array = NULL;
    }

    if (guardOpenFile(drv, file_name, SYS_FS_FILE_OPEN_READ) == false) {
        DBG_P;
        return false;
    }
#define CLOSE_RET(t_f)                     \
    {                                      \
        SYS_FS_FileClose(drv->fileHandle); \
        return (t_f);                      \
    }
    uint32_t fileSize = SYS_FS_FileSize(drv->fileHandle);
    if (-1 == fileSize) {
        DBG_P;
        printf("fileSize error\n");
        CLOSE_RET(false)
    }
    if (0 == fileSize) {
        DBG_P;
        printf("fileSize error\n");
        CLOSE_RET(false)
    }
    file_size = fileSize;
    printf("file size is %lu\n", fileSize);


    *file_data_array = calloc(fileSize, 1);
    if (*file_data_array == NULL)
        CLOSE_RET(false)

        if (-1 == SYS_FS_FileRead(drv->fileHandle, *file_data_array, fileSize)) {
            free(*file_data_array);
            *file_data_array = NULL;
            CLOSE_RET(false)
        }
    CLOSE_RET(fileSize)
#undef CLOSE_RET
}

int check_image() {

    int is_png = 0;
    if (file_data_array == NULL) {
        printf("file data array error\n");
        return is_png;
    }

    if ((file_data_array[1] == 0x89) && (file_data_array[2] == 0x50) && (file_data_array[3] == 0x4e)) {
        is_png = 1;
    }

    return is_png;
}

uint16_t get_width() {
    uint16_t w = (file_data_array[18] << 8) | file_data_array[19];
    return w;
}

uint16_t get_height() {
    uint16_t h = (file_data_array[22] << 8) | file_data_array[23];
    return h;
}

int copy_logo_from_usb_to_flash() {
    //    int a = readJsonFromDrvToMem(&usb, LOGO_FILE, file_data_array);
    int size = copyFile(&sst, &usb, LOGO_FILE);
    if (size) {
        printf("successfully copy the logo from usb to flash\n");
        return 1;
    }
    printf("failed copy the logo from usb\n");

    return 0;
}

int read_logo_from_flash() {

    //    if (readJsonFromDrvToMem(&sst, LOGO_FILE, &temp_file_data_array)) {
    if (read_image(&sst, LOGO_FILE, &file_data_array)) {
        printf("\t");
        for (int i = 0; i < file_size; i++) {
            printf("%x\t", file_data_array[i]);
        }
        printf("successfully read logo from flash\n");
        return 1;
    }
    printf("failed read the logo from usb\n");

    return 0;
}

void logo_process() {
    printf("FILE SIZE : %d\n", file_size);
    printf("width : %d", get_width());
    printf("height : %d", get_height());

    Start_logo.header.address = (void*) file_data_array;
    Start_logo.header.size = file_size;
    Start_logo.format = LE_IMAGE_FORMAT_PNG;
    Start_logo.buffer.size.width = get_width();
    Start_logo.buffer.size.height = get_height();
    Start_logo.buffer.pixel_count = get_width() * get_height();
    Start_logo.buffer.buffer_length = file_size;
    Start_logo.buffer.pixels = (void*) file_data_array;
}
