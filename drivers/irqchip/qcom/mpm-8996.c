/* Copyright (c) 2018, The Linux Foundation. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#include "mpm.h"

const struct mpm_pin mpm_msm8996_gic_chip_data[] = {
	{2, 216}, /* tsens_upper_lower_int */
	{79, 379},   /* qusb2phy_dmse_hv_prim */
	{80, 384},   /* qusb2phy_dmse_hv_sec */
	{81, 379},   /* qusb2phy_dpse_hv_prim */
	{82, 384},   /* qusb2phy_dpse_hv_sec */
	{52, 275},   /* qmp_usb3_lfps_rxterm_irq */
	{87, 358},   /* ee0_krait_hlos_spmi_periph_irq */
    /* from Open Devices 4.4, msm8996-pm.dtsi */
    {255, 16>}  /* APCj_qgicdrCpu0HwFaultIrptReq */
    {255, 23>}  /* APCj_qgicdrCpu0PerfMonIrptReq */
    {255, 27>}  /* APCj_qgicdrCpu0QTmrVirtIrptReq */
    {255, 32>}  /* APCj_qgicdrL2PerfMonIrptReq */
    {255, 33>}  /* APCC_qgicL2PerfMonIrptReq */
    {255, 34>}  /* APCC_qgicL2ErrorIrptReq */
    {255, 35>}  /* WDT_barkInt */
    {255, 40>}  /* qtimer_phy_irq */
    {255, 41>}  /* APCj_qgicdrL2HwFaultNonFatalIrptReq */
    {255, 42>}  /* APCj_qgicdrL2HwFaultFatalIrptReq */
    {255, 49>}  /* L3UX_qgicL3ErrorIrptReq */
    {255, 54>}  /* M4M_sysErrorInterrupt */
    {255, 55>}  /* M4M_sysDlmInterrupt */
    {255, 57>}  /* mss_to_apps_irq(0) */
    {255, 58>}  /* mss_to_apps_irq(1) */
    {255, 59>}  /* mss_to_apps_irq(2) */
    {255, 60>}  /* mss_to_apps_irq(3) */
    {255, 61>}  /* mss_a2_bam_irq */
    {255, 62>}  /* QTMR_qgicFrm0VirtIrq */
    {255, 63>}  /* QTMR_qgicFrm1PhysIrq */
    {255, 64>}  /* QTMR_qgicFrm2PhysIrq */
    {255, 65>}  /* QTMR_qgicFrm3PhysIrq */
    {255, 66>}  /* QTMR_qgicFrm4PhysIrq */
    {255, 67>}  /* QTMR_qgicFrm5PhysIrq */
    {255, 68>}  /* QTMR_qgicFrm6PhysIrq */
    {255, 69>}  /* QTMR_qgicFrm7PhysIrq */
    {255, 70>}  /* iommu_pmon_nonsecure_irq */
    {255, 74>}  /* osmmu_CIrpt[1] */
    {255, 75>}  /* osmmu_CIrpt[0] */
    {255, 77>}  /* osmmu_CIrpt[0] */
    {255, 78>}  /* osmmu_CIrpt[0] */
    {255, 79>}  /* osmmu_CIrpt[0] */
    {255, 80>}  /* CPR3_irq */
    {255, 94>}  /* osmmu_CIrpt[0] */
    {255, 97>}  /* iommu_nonsecure_irq */
    {255, 99>}  /* msm_iommu_pmon_nonsecure_irq */
    {255, 101}, /* camss_jpeg_mmu_cirpt */
    {255, 102}, /* osmmu_CIrpt[1] */
    {255, 105}, /* iommu_pmon_nonsecure_irq */
    {255, 108}, /* osmmu_PMIrpt */
    {255, 109}, /* ocmem_dm_nonsec_irq */
    {255, 110}, /* csiphy_0_irq */
    {255, 111}, /* csiphy_1_irq */
    {255, 112}, /* csiphy_2_irq */
    {255, 115}, /* mdss_irq */
    {255, 126}, /* bam_irq[0] */
    {255, 127}, /* blsp1_qup_irq(0) */
    {255, 129}, /* hwirq */
    {255, 132}, /* blsp1_qup_irq(5) */
    {255, 133}, /* blsp2_qup_irq(0) */
    {255, 134}, /* blsp2_qup_irq(1) */
    {255, 135}, /* blsp2_qup_irq(2) */
    {255, 137}, /* hwirq */
    {255, 138}, /* blsp2_qup_irq(5) */
    {255, 140}, /* blsp1_uart_irq(1) */
    {255, 146}, /* blsp2_uart_irq(1) */
    {255, 155}, /* sdcc_irq[0] */
    {255, 157}, /* sdc2_irq[0] */
    {255, 163}, /* usb30_ee1_irq */
    {255, 164}, /* usb30_bam_irq(0) */
    {255, 165}, /* usb30_hs_phy_irq */
    {255, 166}, /* sdc1_pwr_cmd_irq */
    {255, 170}, /* sdcc_pwr_cmd_irq */
    {255, 171}, /* usb20_hs_phy_irq */
    {255, 172}, /* usb20_power_event_irq */
    {255, 173}, /* sdc1_irq[0] */
    {255, 174}, /* o_wcss_apss_smd_med */
    {255, 175}, /* o_wcss_apss_smd_low */
    {255, 176}, /* o_wcss_apss_smsm_irq */
    {255, 177}, /* o_wcss_apss_wlan_data_xfer_done */
    {255, 178}, /* o_wcss_apss_wlan_rx_data_avail */
    {255, 179}, /* o_wcss_apss_asic_intr */
    {255, 180}, /* pcie20_2_int_pls_err */
    {255, 181}, /* wcnss watchdog */
    {255, 188}, /* lpass_irq_out_apcs(0) */
    {255, 189}, /* lpass_irq_out_apcs(1) */
    {255, 190}, /* lpass_irq_out_apcs(2) */
    {255, 191}, /* lpass_irq_out_apcs(3) */
    {255, 192}, /* lpass_irq_out_apcs(4) */
    {255, 193}, /* lpass_irq_out_apcs(5) */
    {255, 194}, /* lpass_irq_out_apcs(6) */
    {255, 195}, /* lpass_irq_out_apcs(7) */
    {255, 196}, /* lpass_irq_out_apcs(8) */
    {255, 197}, /* lpass_irq_out_apcs(9) */
    {255, 198}, /* coresight-tmc-etr interrupt */
    {255, 200}, /* rpm_ipc(4) */
    {255, 201}, /* rpm_ipc(5) */
    {255, 202}, /* rpm_ipc(6) */
    {255, 203}, /* rpm_ipc(7) */
    {255, 204}, /* rpm_ipc(24) */
    {255, 205}, /* rpm_ipc(25) */
    {255, 206}, /* rpm_ipc(26) */
    {255, 207}, /* rpm_ipc(27) */
    {255, 208},
    {255, 210},
    {255, 211}, /* usb_dwc3_otg */
    {255, 212}, /* usb30_power_event_irq */
    {255, 215}, /* o_bimc_intr(0) */
    {255, 224}, /* spdm_realtime_irq[1] */
    {255, 238}, /* crypto_bam_irq[0] */
    {255, 240}, /* summary_irq_kpss */
    {255, 253}, /* sdc2_pwr_cmd_irq */
    {255, 258}, /* lpass_irq_out_apcs[21] */
    {255, 268}, /* bam_irq[1] */
    {255, 270}, /* bam_irq[0] */
    {255, 271}, /* bam_irq[0] */
    {255, 276}, /* wlan_pci */
    {255, 283}, /* pcie20_0_int_pls_err */
    {255, 284}, /* pcie20_0_int_aer_legacy */
    {255, 286}, /* pcie20_0_int_pls_link_down */
    {255, 290}, /* ufs_ice_nonsec_level_irq */
    {255, 293}, /* pcie20_2_int_pls_link_down */
    {255, 295}, /* camss_cpp_mmu_cirpt[0] */
    {255, 296}, /* camss_cpp_mmu_pmirpt */
    {255, 297}, /* ufs_intrq */
    {255, 298}, /* camss_cpp_mmu_cirpt */
    {255, 302}, /* qdss_etrbytecnt_irq */
    {255, 310}, /* pcie20_1_int_pls_err */
    {255, 311}, /* pcie20_1_int_aer_legacy */
    {255, 313}, /* pcie20_1_int_pls_link_down */
    {255, 318}, /* venus0_mmu_pmirpt */
    {255, 319}, /* venus0_irq */
    {255, 325}, /* camss_irq18 */
    {255, 326}, /* camss_irq0 */
    {255, 327}, /* camss_irq1 */
    {255, 328}, /* camss_irq2 */
    {255, 329}, /* camss_irq3 */
    {255, 330}, /* camss_irq4 */
    {255, 331}, /* camss_irq5 */
    {255, 332}, /* sps */
    {255, 341}, /* camss_irq6 */
    {255, 346}, /* camss_irq8 */
    {255, 347}, /* camss_irq9 */
    {255, 352}, /* mdss_mmu_cirpt[0] */
    {255, 353}, /* mdss_mmu_cirpt[1] */
    {255, 361}, /* ogpu_mmu_cirpt[0] */
    {255, 362}, /* ogpu_mmu_cirpt[1] */
    {255, 365}, /* ipa_irq[0] */
    {255, 366}, /* ogpu_mmu_pmirpt */
    {255, 367}, /* venus0_mmu_cirpt[0] */
    {255, 368}, /* venus0_mmu_cirpt[1] */
    {255, 369}, /* venus0_mmu_cirpt[2] */
    {255, 370}, /* venus0_mmu_cirpt[3] */
    {255, 375}, /* camss_vfe_mmu_cirpt[0] */
    {255, 376}, /* camss_vfe_mmu_cirpt[1] */
    {255, 380}, /* mdss_dma_mmu_cirpt[0] */
    {255, 381}, /* mdss_dma_mmu_cirpt[1] */
    {255, 385}, /* mdss_dma_mmu_pmirpt */
    {255, 387}, /* osmmu_CIrpt[0] */
    {255, 394}, /* osmmu_PMIrpt */
    {255, 403}, /* osmmu_PMIrpt */
    {255, 405}, /* osmmu_CIrpt[0] */
    {255, 413}, /* osmmu_PMIrpt */
    {255, 422}, /* ssc_irq_out_apcs[5] */
    {255, 424}, /* ipa_irq[2] */
    {255, 425}, /* lpass_irq_out_apcs[22] */
    {255, 426}, /* lpass_irq_out_apcs[23] */
    {255, 427}, /* lpass_irq_out_apcs[24] */
    {255, 428}, /* lpass_irq_out_apcs[25] */
    {255, 429}, /* lpass_irq_out_apcs[26] */
    {255, 430}, /* lpass_irq_out_apcs[27] */
    {255, 431}, /* lpass_irq_out_apcs[28] */
    {255, 432}, /* lpass_irq_out_apcs[29] */
    {255, 436}, /* lpass_irq_out_apcs[37] */
    {255, 437}, /* pcie20_0_int_msi_dev0 */
    {255, 445}, /* pcie20_1_int_msi_dev0 */
    {255, 453}, /* pcie20_2_int_msi_dev0 */
    {255, 461}, /* o_vmem_nonsec_irq */
    {255, 462}, /* tsens1_tsens_critical_int */
    {255, 464}, /* ipa_bam_irq[0] */
    {255, 465}, /* ipa_bam_irq[2] */
    {255, 477}, /* tsens0_tsens_critical_int */
    {255, 480}, /* q6_wdog_expired_irq */
    {255, 481}, /* mss_ipc_out_irq(4) */
    {255, 483}, /* mss_ipc_out_irq(6) */
    {255, 484}, /* mss_ipc_out_irq(7) */
    {255, 487}, /* mss_ipc_out_irq(30) */
    {255, 490}, /* tsens0_tsens_upper_lower_int */
    {255, 493}; /* sdc1_ice_nonsec_level_irq */
	{-1},
};

const struct mpm_pin mpm_msm8996_gpio_chip_data[] = {
	{3, 1},
	{4, 5},
	{5, 9},
	{6, 11},
	{7, 66},
	{8, 22},
	{9, 24},
	{10, 26},
	{11, 34},
	{12, 36},
	{13, 37}, /* PCIe0 */
	{14, 38},
	{15, 40},
	{16, 42},
	{17, 46},
	{18, 50},
	{19, 53},
	{20, 54},
	{21, 56},
	{22, 57},
	{23, 58},
	{24, 59},
	{25, 60},
	{26, 61},
	{27, 62},
	{28, 63},
	{29, 64},
	{30, 71},
	{31, 73},
	{32, 77},
	{33, 78},
	{34, 79},
	{35, 80},
	{36, 82},
	{37, 86},
	{38, 91},
	{39, 92},
	{40, 95},
	{41, 97},
	{42, 101},
	{43, 104},
	{44, 106},
	{45, 108},
	{46, 112},
	{47, 113},
	{48, 110},
	{50, 127},
	{51, 115},
	{54, 116}, /* PCIe2 */
	{55, 117},
	{56, 118},
	{57, 119},
	{58, 120},
	{59, 121},
	{60, 122},
	{61, 123},
	{62, 124},
	{63, 125},
	{64, 126},
	{65, 129},
	{66, 131},
	{67, 132}, /* PCIe1 */
	{68, 133},
	{69, 145},
	{70,  85}, /* hwirq */
	{-1},
};
