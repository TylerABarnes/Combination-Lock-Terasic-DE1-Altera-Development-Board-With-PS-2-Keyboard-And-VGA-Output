#include <iostream>
#include <cmath>
#include <fstream>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

int main() {
    const int resolution = 4096; // 16-bit resolution
    std::ofstream outFile("output.txt");

    outFile << "type SIN_LUT_TYPE is array (0 to " << resolution - 1 << ") of STD_LOGIC_VECTOR(15 downto 0);\n";
    outFile << "constant SIN_LUT : SIN_LUT_TYPE := (\n";

    for (int i = 0; i < resolution; i++) {
        double value = std::sin(2.0 * M_PI * i / resolution);
        int sine_val = static_cast<int>((value + 1.0) * (resolution - 1) / 2.0);

        // Convert sine_val to 16-bit binary
        std::string binary_val = "";
        for (int j = 11; j >= 0; j--) {
            binary_val += ((sine_val >> j) & 1) ? "1" : "0";
        }

        outFile << "\"" << binary_val << "\"";
        if (i < resolution - 1) outFile << ",";
        if (i % 8 == 7) outFile << "\n";
    }
    outFile << ");\n";

    return 0;
}
