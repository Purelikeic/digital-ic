#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

#include "Vsync_fifo.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#ifndef FIFO_DEPTH
#define FIFO_DEPTH 128
#endif

#ifndef FIFO_DATA_WIDTH
#define FIFO_DATA_WIDTH 8
#endif

namespace {

constexpr int kFifoDepth = FIFO_DEPTH;
constexpr int kDataWidth = FIFO_DATA_WIDTH;
constexpr vluint64_t kHalfPeriod = 5;

uint32_t data_mask() {
  if (kDataWidth >= 32)
    return UINT32_MAX;
  return (uint32_t{1} << kDataWidth) - 1;
}

uint32_t test_data(int index, int seed) {
  return static_cast<uint32_t>(index * 37 + seed) & data_mask();
}

}  // namespace

int main(int argc, char** argv) {
  static_assert(kFifoDepth >= 2, "FIFO_DEPTH must be at least 2");
  static_assert((kFifoDepth & (kFifoDepth - 1)) == 0,
                "FIFO_DEPTH must be a power of two");
  static_assert(kDataWidth >= 1 && kDataWidth <= 32,
                "This testbench supports DATA_WIDTH from 1 to 32");

  VerilatedContext context;
  context.commandArgs(argc, argv);
  context.traceEverOn(true);

  Vsync_fifo dut{&context};
  VerilatedVcdC trace;
  dut.trace(&trace, 5);
  trace.open("build/sync_fifo.vcd");

  int cycle_count = 0;

  auto evaluate = [&]() {
    dut.eval();
    trace.dump(context.time());
  };

  auto tick = [&]() {
    context.timeInc(kHalfPeriod);
    dut.i_clk = 1;
    evaluate();

    context.timeInc(kHalfPeriod);
    dut.i_clk = 0;
    evaluate();
    ++cycle_count;
  };

  auto drive = [&](bool write_enable, bool read_enable, uint32_t write_data = 0) {
    dut.i_wr_en = write_enable;
    dut.i_rd_en = read_enable;
    dut.i_wr_data = write_data & data_mask();
  };

  auto check = [&](bool condition, const std::string& message) {
    if (!condition)
      throw std::runtime_error("cycle " + std::to_string(cycle_count) +
                               ": " + message);
  };

  int result = 0;

  try {
    dut.i_clk = 0;
    dut.i_rstn = 1;
    drive(false, false);
    evaluate();

    // 产生一次明确的复位下降沿，并保持两个时钟周期。
    context.timeInc(1);
    dut.i_rstn = 0;
    evaluate();
    tick();
    tick();

    context.timeInc(1);
    dut.i_rstn = 1;
    evaluate();

    check(dut.o_empty == 1, "FIFO should be empty after reset");
    check(dut.o_full == 0, "FIFO should not be full after reset");
    check(dut.o_rd_data == 0, "read data should be zero after reset");

    // 写满 FIFO，并检查满标志只在最后一次写入后拉高。
    std::vector<uint32_t> expected;
    expected.reserve(kFifoDepth);

    for (int i = 0; i < kFifoDepth; ++i) {
      const uint32_t value = test_data(i, 13);
      expected.push_back(value);
      drive(true, false, value);
      tick();

      check(dut.o_empty == 0, "FIFO became empty while filling");
      check(dut.o_full == (i == kFifoDepth - 1),
            "full flag changed at the wrong occupancy");
    }

    // 满状态继续写入应被忽略。
    drive(true, false, test_data(0, 91));
    tick();
    check(dut.o_full == 1, "overflow attempt changed the full state");

    // 按写入顺序读空 FIFO，验证数据顺序和空标志。
    drive(false, true);
    for (int i = 0; i < kFifoDepth; ++i) {
      tick();
      check(static_cast<uint32_t>(dut.o_rd_data) == expected[i],
            "FIFO data order mismatch while draining");
      check(dut.o_empty == (i == kFifoDepth - 1),
            "empty flag changed at the wrong occupancy");
    }

    // 空状态继续读取，输出数据和空标志都应保持不变。
    const uint32_t last_read_data = dut.o_rd_data;
    tick();
    check(dut.o_empty == 1, "underflow attempt changed the empty state");
    check(static_cast<uint32_t>(dut.o_rd_data) == last_read_data,
          "underflow attempt changed read data");

    // 空状态同时读写时，只接受写操作。
    const uint32_t empty_boundary_data = test_data(3, 29);
    drive(true, true, empty_boundary_data);
    tick();
    check(dut.o_empty == 0, "write at the empty boundary was not accepted");
    check(static_cast<uint32_t>(dut.o_rd_data) == last_read_data,
          "read at the empty boundary should have been ignored");

    drive(false, true);
    tick();
    check(static_cast<uint32_t>(dut.o_rd_data) == empty_boundary_data,
          "empty-boundary write stored incorrect data");
    check(dut.o_empty == 1, "FIFO should be empty after boundary data is read");

    // 普通状态同时读写时，数据数量保持不变且顺序不能改变。
    const uint32_t first = test_data(1, 41);
    const uint32_t second = test_data(2, 41);
    const uint32_t third = test_data(3, 41);

    drive(true, false, first);
    tick();
    drive(true, false, second);
    tick();

    drive(true, true, third);
    tick();
    check(static_cast<uint32_t>(dut.o_rd_data) == first,
          "simultaneous read returned incorrect data");
    check(dut.o_empty == 0 && dut.o_full == 0,
          "simultaneous read/write changed occupancy flags incorrectly");

    drive(false, true);
    tick();
    check(static_cast<uint32_t>(dut.o_rd_data) == second,
          "second queued value was corrupted");
    tick();
    check(static_cast<uint32_t>(dut.o_rd_data) == third,
          "simultaneously written value was corrupted");
    check(dut.o_empty == 1, "FIFO should be empty after simultaneous test");

    // 再次写满，用于检查指针回绕和满边界同时读写。
    expected.clear();
    for (int i = 0; i < kFifoDepth; ++i) {
      const uint32_t value = test_data(i, 73);
      expected.push_back(value);
      drive(true, false, value);
      tick();
    }
    check(dut.o_full == 1, "FIFO did not become full in wraparound test");

    // 满状态同时读写时，只接受读操作，新的写数据应被丢弃。
    drive(true, true, test_data(0, 127));
    tick();
    check(static_cast<uint32_t>(dut.o_rd_data) == expected[0],
          "read at the full boundary returned incorrect data");
    check(dut.o_full == 0, "read at the full boundary did not clear full");

    drive(false, true);
    for (int i = 1; i < kFifoDepth; ++i) {
      tick();
      check(static_cast<uint32_t>(dut.o_rd_data) == expected[i],
            "FIFO data was corrupted after pointer wraparound");
    }
    check(dut.o_empty == 1, "FIFO should be empty at the end of the test");

    drive(false, false);
    tick();
    std::cout << "PASS: synchronous FIFO behavior verified (depth="
              << kFifoDepth << ", width=" << kDataWidth << ")\n";
  } catch (const std::exception& error) {
    std::cerr << "FAIL: " << error.what() << '\n';
    result = 1;
  }

  dut.final();
  trace.close();
  return result;
}
