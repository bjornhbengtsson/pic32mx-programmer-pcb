#ifndef TEST_MOCK_APP_H
#define TEST_MOCK_APP_H

typedef enum
{
    APP_STATE_INIT = 0
} APP_STATES;

typedef struct
{
    APP_STATES state;
} APP_DATA;

void APP_Initialize(void);
void APP_Tasks(void);

#endif
