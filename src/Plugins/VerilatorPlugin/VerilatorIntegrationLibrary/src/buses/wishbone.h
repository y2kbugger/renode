//
// Copyright (c) 2010-2022 Antmicro
//
// This file is licensed under the MIT License.
// Full license text is available in 'licenses/MIT.txt'.
//
#ifndef Wishbone_H
#define Wishbone_H
#include "bus.h"
#include <src/renode_bus.h>

class WishboneBase
{
public:
    uint8_t  *wb_clk;
    uint8_t  *wb_rst;
    uint64_t *wb_addr;
    uint64_t *wb_rd_dat;
    uint64_t *wb_wr_dat;
    uint8_t  *wb_we;
    uint8_t  *wb_sel;
    uint8_t  *wb_stb;
    uint8_t  *wb_ack;
    uint8_t  *wb_cyc;
    uint8_t  *wb_stall;
    uint8_t   granularity;
    uint8_t   addr_lines;
};

class Wishbone : public WishboneBase, public BaseTargetBus
{
public:
    Wishbone(uint32_t dataWidth, uint32_t addrWidth) : WishboneBase(), BaseTargetBus(dataWidth, addrWidth) {}
    virtual void write(int width, uint64_t addr, uint64_t value);
    virtual uint64_t read(int width, uint64_t addr);
    virtual void onResetAction();

    void prePosedgeTick();
    void posedgeTick();
    void negedgeTick();
    void setClock(uint8_t value);
    void setReset(uint8_t value);
};
#endif
