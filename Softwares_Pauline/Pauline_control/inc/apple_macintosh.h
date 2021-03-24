/*
//
// Copyright (C) 2019-2021 Jean-François DEL NERO
//
// This file is part of the Pauline control software
//
// Pauline control software may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// Pauline control software is free software; you can redistribute it
// and/or modify  it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Pauline control software is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//   See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pauline control software; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
*/

//
// Note:
// Initial descriptions come from the BMOW (Big Mess o' Wires) CPLD project code. (CC BY-NC 3.0 license)
// Some text were modified/completed/added afterwards to add details.
//

/*

Interface pinout :

Pin 2  - PH0     - CA0
Pin 4  - PH1     - CA1
Pin 6  - PH2     - CA2
Pin 8  - PH3     - LSTRB - Write to the reg at rising edge + /ENABLE=0
Pin 10 - /WREQ   - Head write enable
Pin 12 - SEL     - Head selection
Pin 14 - /ENABLE - Drive selection
Pin 16 - RD      - Read flux / register data
Pin 18 - WR      - Write flux
Pin 20 - PWM     - Motor RPM control

*/

/*
Drive registers (write):

      Control lines          Registers
CA2    CA1    CA0    SEL
 D      0      0      0      STEPDIR              Set stepping direction (0 = toward track 79, 1 = toward track 0), SWIM3: SEEK_POSITIVE
 D      0      0      1      CLEAR_DISK_SWITCHED  Reset disk switched flag (writing 1 sets switch flag to 0)
 D      0      1      0      HEADSTEP             Step the drive head one track (setting to 0 performs a step, returns to 1 when step is complete)
 D      1      0      0      MOTORON              Turn drive motor on/off (0 = on, 1 = off)
 D      1      0      0      TWOMEGMEDIA_CHECK    The first time zero is written, changes the behavior when reading SIDES
 D      0      1      1      SET_GCR_MODE         0 = MFM, 1 = GCR
 D      1      1      0      DISK_EJECT           Eject the disk (writing 1 ejects the disk)
 D      1      1      0      INDEX                if writing 0

 Note : D is the data value
*/

#define APPLE_MAC_CMD_WR_STEPDIR              0x0
#define APPLE_MAC_CMD_WR_CLEAR_DISK_SWITCHED  0x1
#define APPLE_MAC_CMD_WR_HEADSTEP             0x2
#define APPLE_MAC_CMD_RD_SET_GCR_MODE         0x3
#define APPLE_MAC_CMD_WR_MOTORON              0x4
#define APPLE_MAC_CMD_WR_DISK_EJECT           0x6

/*
Read output muxer output selection:
  State-control lines        Register
CA2    CA1    CA0    SEL
 0      0      0      0      STEPDIR              Head step direction (0 = toward track 79, 1 = toward track 0)
 0      0      0      1      DISKIN               Disk in place (0 = disk is inserted)
 0      0      1      0      STEPDONE             Drive head stepping (setting to 0 performs a step, returns to 1 when step is complete)
 0      0      1      1      WRTPRT               Disk locked (0 = locked)
 0      1      0      0      MOTORON              Drive motor running (0 = on, 1 = off)
 0      1      0      1      TRK0                 Head at track 0 (0 = at track 0)
 0      1      1      0      DISK_SWITCHED        Disk switched (1 = yes?) SWIM3: relax, also eject in progress
 0      1      1      1      TACHOMETER           GCR: Tachometer (produces 60 pulses for each rotation of the drive motor), MFM: Index pulse
 1      0      0      0      RDDATA0              Read data, lower head, side 0
 1      0      0      1      RDDATA1              Read data, upper head, side 1
 1      0      1      0      SUPERDRIVE           Drive is a Superdrive (0 = no, 1 = yes) SWIM3: two meg drive.
 1      0      1      1      MFM_MODE             SWIM3: MFM_MODE, 1 = yes (opposite of writing?)
 1      1      0      0      DOUBLESIDES          Single- or double-sided drive (0 = single side, 1 = double side), SWIM: 0 = 4MB, 1 = not 4MB
 1      1      0      1      NOTREADY             0 = Ready, SWIM3: SEEK_COMPLETE
 1      1      1      0      NOT_INSTALLED        0 = Drive present, only used by SWIM, not IWM? SWIM3: drive present.
 1      1      1      1      DD_DISK              400K/800K: implements ready handshake if 1, Superdrive: Inserted disk capacity (0 = HD, 1 = DD), SWIM3: 1 = ONE_MEG_MEDIA

 The read data value is at the Pin 16 for all these commands/selections.
*/

#define APPLE_MAC_CMD_RD_STEPDIR              0x0
#define APPLE_MAC_CMD_RD_DISKIN               0x1
#define APPLE_MAC_CMD_RD_STEPDONE             0x2
#define APPLE_MAC_CMD_RD_WRTPRT               0x3
#define APPLE_MAC_CMD_RD_MOTORON              0x4
#define APPLE_MAC_CMD_RD_TRK0                 0x5
#define APPLE_MAC_CMD_RD_DISK_SWITCHED        0x6
#define APPLE_MAC_CMD_RD_TACHMETER            0x7
#define APPLE_MAC_CMD_RD_RDDATAHEAD0          0x8
#define APPLE_MAC_CMD_RD_RDDATAHEAD1          0x9
#define APPLE_MAC_CMD_RD_SUPERDRIVE           0xA
#define APPLE_MAC_CMD_RD_MFM_MODE             0xB
#define APPLE_MAC_CMD_RD_DOUBLESIDES          0xC
#define APPLE_MAC_CMD_RD_NOTREADY             0xD
#define APPLE_MAC_CMD_RD_NOT_INSTALLED        0xE
#define APPLE_MAC_CMD_RD_DD_DISK              0xF
