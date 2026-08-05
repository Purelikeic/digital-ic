VERILATOR ?= verilator

TOP        := sync_fifo
RTL        := sync_fifo.v
SIM_SRC    := sim_main.cpp
BUILD_DIR  := build
OBJ_DIR    := $(BUILD_DIR)/obj_dir
SIM        := $(OBJ_DIR)/V$(TOP)

DATA_WIDTH ?= 8
DATA_DEPTH ?= 128

# 避免全局 ccache 目录不可写时导致构建失败。
export CCACHE_DISABLE := 1

VERILATOR_FLAGS := \
	--cc \
	--exe \
	--build \
	--trace \
	--assert \
	--Wall \
	--top-module $(TOP) \
	--Mdir $(OBJ_DIR) \
	-GDATA_WIDTH=$(DATA_WIDTH) \
	-GDATA_DEPTH=$(DATA_DEPTH) \
	-CFLAGS "-std=c++17 -DFIFO_DATA_WIDTH=$(DATA_WIDTH) -DFIFO_DEPTH=$(DATA_DEPTH)"

.PHONY: all build sim lint wave clean help

all: sim

build:
	@mkdir -p $(BUILD_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) $(RTL) $(SIM_SRC)

sim: build
	$(SIM)

lint:
	$(VERILATOR) --lint-only --Wall \
		-GDATA_WIDTH=$(DATA_WIDTH) -GDATA_DEPTH=$(DATA_DEPTH) $(RTL)

wave: sim
	@echo "波形文件：$(BUILD_DIR)/sync_fifo.vcd"
	@echo "查看命令：gtkwave $(BUILD_DIR)/sync_fifo.vcd"

clean:
	$(RM) -r $(BUILD_DIR)

help:
	@echo "make              编译并运行 C++ 自检仿真"
	@echo "make build        仅编译 Verilator 仿真程序"
	@echo "make lint         运行 Verilator 静态检查"
	@echo "make wave         运行仿真并显示 VCD 文件位置"
	@echo "make clean        删除 build 目录"
	@echo "make DATA_DEPTH=16 DATA_WIDTH=8 sim"
