*** Variables ***
${URI}                                   @https://dl.antmicro.com/projects/renode
${PROMPT}                                zynq>
${UART}                                  sysbus.uart0
${PLATFORM}                              @platforms/boards/mars_zx3.repl
${FPGA_ISP_NATIVE_LINUX}                 @https://dl.antmicro.com/projects/renode/zynq-verilated-fpga-isp--libVfpga_isp-Linux-x86_64-2761546208.so-s_2469096-d8cc8cf568b66378feb8be1728b48dfc715bf38e
${FPGA_ISP_NATIVE_WINDOWS}               @https://dl.antmicro.com/projects/renode/zynq-verilated-fpga-isp--libVfpga_isp-Windows-x86_64-2761546208.dll-s_3486606-c3c342394dabb4d4bb3a6ae9c7773765f1a9d30a
${FPGA_ISP_NATIVE_MACOS}                 @https://dl.antmicro.com/projects/renode/zynq-verilated-fpga-isp--libVfpga_isp-macOS-x86_64-2761546208.dylib-s_461448-e6e5a34d7850adba9c3d365a768151256096edad
${BIN_VM}                                @https://dl.antmicro.com/projects/renode/zynq-verilated-fpga-isp--vmlinux-s_13735336-6a3e10bd5b6d301cc8846490cad6de9ec541e067
${ROOTFS}                                @https://dl.antmicro.com/projects/renode/zynq-verilated-fpga-isp--rootfs.ext2-s_33554432-cc9664564461b5be36a4d1841e50a760dc7f5ad1
${DTB}                                   @https://dl.antmicro.com/projects/renode/zynq-verilated-fpga-isp--video-board.dtb-s_13451-bdb696327471e2247f811b03f37be84df994379a
${VIRTIO}                                @https://dl.antmicro.com/projects/renode/empty-ext4-filesystem.img-s_33554432-1eb65a808612389cc35a69b81178fbad5708a863
${FASTVDMA_DRIVER}                       /lib/modules/5.15.0-xilinx/kernel/drivers/dma/fastvdma/fastvdma.ko
${DEMOSAICER_DRIVER}                     /lib/modules/5.15.0-xilinx/kernel/drivers/media/platform/demosaicer/zynq_demosaicer.ko

*** Keywords ***
Create Machine
    Execute Command                      mach create
    Execute Command                      using sysbus
    Execute Command                      machine LoadPlatformDescription ${PLATFORM}
    Execute Command                      machine LoadPlatformDescriptionFromString 'virtio: Storage.VirtIOBlockDevice @ sysbus 0x400d0000 { IRQ->gic@32 }'
    Execute Command                      machine LoadPlatformDescriptionFromString 'isp: Verilated.BaseDoubleWordVerilatedPeripheral @ sysbus <0x43c00000, +0x20000> { frequency: 100000; limitBuffer: 1000000; timeout: 10000; 0->gic@29; 1->gic@31; numberOfInterrupts: 2 }'
    Execute Command                      sysbus Redirect 0xC0000000 0x0 0x10000000
    Execute Command                      ttc0 Frequency 33333333
    Execute Command                      ttc1 Frequency 33333333
    Execute Command                      cpu SetRegisterUnsafe 0 0x000
    Execute Command                      cpu SetRegisterUnsafe 1 0xD32
    Execute Command                      cpu SetRegisterUnsafe 2 0x100
    Execute Command                      sysbus LoadELF ${BIN_VM}
    Execute Command                      sysbus LoadFdt ${DTB} 0x100 "console=ttyPS0,115200 root=/dev/ram0 rw earlyprintk initrd=0x1a000000,32M" false
    Execute Command                      sysbus ZeroRange 0x1a000000 0x800000
    Execute Command                      sysbus LoadBinary ${ROOTFS} 0x1a000000
    Execute Command                      isp SimulationFilePathLinux ${FPGA_ISP_NATIVE_LINUX}
    Execute Command                      isp SimulationFilePathWindows ${FPGA_ISP_NATIVE_WINDOWS}
    Execute Command                      isp SimulationFilePathMacOS ${FPGA_ISP_NATIVE_MACOS}
    Execute Command                      virtio LoadImage ${VIRTIO} true
    Create Terminal Tester               ${UART}

Should Load Drivers
    [Documentation]                      Loads fastvdma.ko and zynq_demosaicer.ko drivers.

    # Suppress messages from kernel space so it doesn't affect dd and cmp outputs
    Write Line To Uart                   echo 0 > /proc/sys/kernel/printk

    # It seems like the simulated shell splits long lines what messes with `waitForEcho` in the terminal tester
    Write Line To Uart                   insmod ${FASTVDMA_DRIVER}  waitForEcho=false
    Wait For Prompt On Uart              ${PROMPT}

    Write Line To Uart                   insmod ${DEMOSAICER_DRIVER}  waitForEcho=false
    Wait For Prompt On Uart              ${PROMPT}

    Write Line To Uart                   lsmod
    Wait For Line On Uart                Module
    Wait For Line On Uart                zynq_demosaicer
    Wait For Line On Uart                fastvdma

Should Run v4l2-ctl and Debayer Images
    [Documentation]                      Sets image to FPGA ISP input, runs v4l2-ctl and transfers said image through FPGA ISP which debayers it and saves the output.

    Write Line To Uart                   ./write_image
    Wait For Prompt On Uart              ${PROMPT}

    Write Line To Uart                   v4l2-ctl -d0 --set-fmt-video=width=600,height=398,pixelformat=RGB4 --stream-mmap --stream-count=1 --stream-to=out0.rgb  waitForEcho=false
    Wait For Line On Uart                <  timeout=300
    Wait For Prompt On Uart              ${PROMPT}  timeout=100

    Write Line To Uart                   v4l2-ctl -d0 --set-fmt-video=width=600,height=398,pixelformat=RGB4 --stream-mmap --stream-count=1 --stream-to=out1.rgb  waitForEcho=false
    Wait For Line On Uart                <  timeout=300
    Wait For Prompt On Uart              ${PROMPT}  timeout=100

Verify Images
    [Documentation]                      Verifies whether the image has been transferred correctly.

    # Verify if the images were debayered correctly
    Write Line To Uart                   cmp -s out0.rgb out1.rgb && echo "CMP success" || echo "CMP failure"  waitForEcho=false
    Wait For Line On Uart                CMP success

*** Test Cases ***

FPGA ISP Debayer On Native Communication
    [Documentation]                      Test FPGA ISP debayering.

    Create Machine
    Start Emulation
    Wait For Prompt On Uart              ${PROMPT}  timeout=300
    Should Load Drivers
    Should Run v4l2-ctl and Debayer Images
    Verify Images
