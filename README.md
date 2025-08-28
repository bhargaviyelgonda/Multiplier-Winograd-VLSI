# Multiplier Design with Winograd Optimization

This project implements **Booth**, **Baugh-Wooley**, and **Vedic** multipliers in Verilog HDL, enhanced with the **Winograd convolution algorithm** to improve performance in terms of **speed, power consumption, and efficiency**.

## Project Overview
- Implements Booth, Baugh-Wooley, and Vedic multipliers in Verilog.
- Enhances them with Winograd convolution for reduced multiplication count.
- Synthesized and simulated in Xilinx Vivado.

## Files
- `booth_winograd_multiplier.v`
- `baugh_wooley_winograd_16bit.v`
- `vedic_winograd_multiplier_16bit.v`
- `Final Report.pdf` (project report with results and analysis)

## Results (Power Analysis)
| Multiplier | Without Winograd | With Winograd |
|------------|------------------|----------------|
| Vedic      | 49.88 W → 7.65 W | ✅ Best Result |
| Baugh-Wooley | 63.97 W → 53.55 W | Some improvement |
| Booth      | 51.32 W → 5.82 W | Efficient but output issues |

✅ **Vedic-Winograd Multiplier** achieved the best trade-off between speed, accuracy, and power.

## Author
Bhargavi Y – B.Tech ECE Final Year Project
