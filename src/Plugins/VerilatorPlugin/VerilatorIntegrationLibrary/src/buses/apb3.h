//
// Copyright (c) 2010-2022 Antmicro
//
// This file is licensed under the MIT License.
// Full license text is available in 'licenses/MIT.txt'.
//
#ifndef APB3_H
#define APB3_H
#include "bus.h"
#include <src/renode_bus.h>

struct APB3 : public BaseTargetBus
{
    virtual void write(int width, uint64_t addr, uint64_t value);
    virtual uint64_t read(int width, uint64_t addr);
    virtual void onResetAction();

    void prePosedgeTick();
    void posedgeTick();
    void negedgeTick();
    void setClock(uint8_t value);
    void setReset(uint8_t value);

    uint8_t  *pclk;
    uint8_t  *prst;
    uint8_t *paddr;        // IN
    uint8_t  *psel;         // IN
    uint8_t  *penable;      // IN
    uint8_t  *pwrite;       // IN
    uint32_t  *pwdata;      // IN
    uint8_t  *pready;       // OUT
    uint32_t  *prdata;      // OUT
    uint8_t  *pslverr;
};
#endif
