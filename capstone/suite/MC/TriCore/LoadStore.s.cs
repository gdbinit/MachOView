# CS_ARCH_TRICORE, CS_MODE_TRICORE_162, None
0x09,0xff,0x08,0x29 = ld.w	%d15, [%a15]136
0x89,0xff,0x08,0x29 = st.w	[%a15]136, %d15
0x09,0xf0,0x0c,0x29 = ld.w	%d0, [%a15]140
0x89,0xf0,0x0c,0x29 = st.w	[%a15]140, %d0
0x09,0xff,0x00,0x29 = ld.w	%d15, [%a15]128
0x89,0xff,0x00,0x29 = st.w	[%a15]128, %d15
0x09,0xff,0x40,0x28 = ld.bu	%d15, [%a15]128
0x09,0xff,0x41,0x28 = ld.bu	%d15, [%a15]129
0x54,0xff           = ld.w	%d15, [%a15]
0x4c,0x41           = ld.w	%d15, [%a4]4
0x6c,0x41           = st.w	[%a4]4, %d15
0x09,0xff,0x43,0x28 = ld.bu	%d15, [%a15]131
0x89,0xff,0x03,0x28 = st.b	[%a15]131, %d15
0x39,0x2f,0x43,0x20 = ld.bu	%d15, [%a2]1155
0xc8,0x52           = ld.a	%a2, [%a15]20
0xd4,0x2d           = ld.a	%a13, [%a2]
0x09,0x2e,0x84,0x09 = ld.a	%a14, [%a2]4
0x89,0xc2,0x84,0x09 = st.a	[%a12]4, %a2
0x09,0xc2,0x84,0x09 = ld.a	%a2, [%a12]4
0x09,0x29,0x48,0x08 = ld.bu	%d9, [%a2]8
0x09,0xfa,0x0c,0x08 = ld.b	%d10, [%a15]12
0x08,0xe0           = ld.bu	%d0, [%a15]14
0x09,0x41,0x41,0x68 = ld.bu	%d1, [%a4]385
0x89,0x20,0x01,0x68 = st.b	[%a2]385, %d0
0x08,0xf0           = ld.bu	%d0, [%a15]15
0x09,0x4f,0x42,0x68 = ld.bu	%d15, [%a4]386
0x89,0x2f,0x02,0x68 = st.b	[%a2]386, %d15
0x09,0xf0,0x50,0x08 = ld.bu	%d0, [%a15]16
0x09,0x4f,0x40,0x68 = ld.bu	%d15, [%a4]384
0x89,0x2f,0x00,0x68 = st.b	[%a2]384, %d15
0x09,0xf0,0x51,0x08 = ld.bu	%d0, [%a15]17
0x08,0x10           = ld.bu	%d0, [%a15]1
0x09,0x4f,0x41,0x68 = ld.bu	%d15, [%a4]385
0x89,0x2f,0x01,0x68 = st.b	[%a2]385, %d15
0x08,0xd0           = ld.bu	%d0, [%a15]13
0x09,0xf0,0x53,0x08 = ld.bu	%d0, [%a15]19
0x08,0x30           = ld.bu	%d0, [%a15]3
0x14,0xf0           = ld.bu	%d0, [%a15]
0x09,0xf0,0x52,0x08 = ld.bu	%d0, [%a15]18
0x08,0x2f           = ld.bu	%d15, [%a15]2
0x4c,0xe2           = ld.w	%d15, [%a14]8
0x6c,0xe2           = st.w	[%a14]8, %d15
0x08,0xb0           = ld.bu	%d0, [%a15]11
0x09,0xc2,0x00,0x08 = ld.b	%d2, [%a12]0
0x09,0xe1,0x20,0x49 = ld.w	%d1, [%a14]288
0x89,0xe1,0x20,0x49 = st.w	[%a14]288, %d1
0x09,0xef,0x20,0x49 = ld.w	%d15, [%a14]288
0x89,0xef,0x20,0x49 = st.w	[%a14]288, %d15
0x09,0xff,0xc6,0x08 = ld.hu	%d15, [%a15]6
0x08,0xb5           = ld.bu	%d5, [%a15]11
0x09,0xf0,0x0c,0x08 = ld.b	%d0, [%a15]12
0x89,0xef,0x10,0x49 = st.w	[%a14]272, %d15
0x08,0x90           = ld.bu	%d0, [%a15]9
0x14,0x21           = ld.bu	%d1, [%a2]
0x34,0x2f           = st.b	[%a2], %d15
0x0c,0x21           = ld.bu	%d15, [%a2]1
0x2c,0x21           = st.b	[%a2]1, %d15
0x0c,0x23           = ld.bu	%d15, [%a2]3
0x2c,0x23           = st.b	[%a2]3, %d15
0x08,0xff           = ld.bu	%d15, [%a15]15
0x08,0xa0           = ld.bu	%d0, [%a15]10
0x08,0xf1           = ld.bu	%d1, [%a15]15
0x09,0xe2,0x30,0x49 = ld.w	%d2, [%a14]304
0x89,0xe2,0x30,0x49 = st.w	[%a14]304, %d2
0x09,0xef,0x30,0x49 = ld.w	%d15, [%a14]304
0x89,0xef,0x30,0x49 = st.w	[%a14]304, %d15
0x09,0xe2,0x34,0x49 = ld.w	%d2, [%a14]308
0x89,0xe2,0x34,0x49 = st.w	[%a14]308, %d2
0x09,0xef,0x34,0x49 = ld.w	%d15, [%a14]308
0x89,0xef,0x34,0x49 = st.w	[%a14]308, %d15
0x09,0xff,0xc4,0x08 = ld.hu	%d15, [%a15]4
0x08,0xa5           = ld.bu	%d5, [%a15]10
0x39,0x5f,0x03,0x80 = ld.bu	%d15, [%a5]515
0xe9,0x4f,0x03,0x80 = st.b	[%a4]515, %d15
0x89,0xef,0x14,0x49 = st.w	[%a14]276, %d15
0x08,0x80           = ld.bu	%d0, [%a15]8
0x2c,0xc1           = st.b	[%a12]1, %d15
0x09,0xff,0x0c,0x08 = ld.b	%d15, [%a15]12
0x34,0xcf           = st.b	[%a12], %d15
0x44,0xff           = ld.w	%d15, [%a15+]
0x64,0x2f           = st.w	[%a2+], %d15
0x89,0x45,0x94,0x09 = st.a	[%a4]20, %a5
0xd4,0xf2           = ld.a	%a2, [%a15]
0xd4,0x2c           = ld.a	%a12, [%a2]
0x08,0x4f           = ld.bu	%d15, [%a15]4
0x89,0x4d,0x84,0x09 = st.a	[%a4]4, %a13
0xd4,0x22           = ld.a	%a2, [%a2]
0xf4,0x42           = st.a	[%a4], %a2
0x08,0x49           = ld.bu	%d9, [%a15]4
0x89,0x49,0x08,0x08 = st.b	[%a4]8, %d9
0x09,0xff,0x6f,0x08 = ld.bu	%d15, [%a15]47
0x09,0xf5,0x62,0x08 = ld.bu	%d5, [%a15]34
0x09,0xf6,0x63,0x08 = ld.bu	%d6, [%a15]35
0x09,0xff,0x70,0x08 = ld.bu	%d15, [%a15]48
0x09,0xf5,0x5a,0x08 = ld.bu	%d5, [%a15]26
0x09,0xf6,0x5b,0x08 = ld.bu	%d6, [%a15]27
0x09,0xff,0x71,0x08 = ld.bu	%d15, [%a15]49
0x09,0xf5,0x6a,0x08 = ld.bu	%d5, [%a15]42
0x09,0xf6,0x6b,0x08 = ld.bu	%d6, [%a15]43
0x08,0x5f           = ld.bu	%d15, [%a15]5
0x14,0x20           = ld.bu	%d0, [%a2]
0x09,0xdf,0x40,0x18 = ld.bu	%d15, [%a13]64
0x89,0xdf,0x00,0x18 = st.b	[%a13]64, %d15
0x09,0xd1,0x00,0x19 = ld.w	%d1, [%a13]64
0x89,0xd1,0x00,0x19 = st.w	[%a13]64, %d1
0x14,0xd0           = ld.bu	%d0, [%a13]
0x34,0xdf           = st.b	[%a13], %d15
0x09,0xff,0x6e,0x08 = ld.bu	%d15, [%a15]46
0x09,0xff,0x61,0x08 = ld.bu	%d15, [%a15]33
0x09,0xdf,0x44,0x28 = ld.bu	%d15, [%a13]132
0x89,0xdf,0x04,0x28 = st.b	[%a13]132, %d15
0x09,0xf0,0x5f,0x08 = ld.bu	%d0, [%a15]31
0x09,0xd1,0x00,0x29 = ld.w	%d1, [%a13]128
0x89,0xd1,0x00,0x29 = st.w	[%a13]128, %d1
0x09,0xff,0x5e,0x08 = ld.bu	%d15, [%a15]30
0x09,0xf0,0x60,0x08 = ld.bu	%d0, [%a15]32
0x14,0x2f           = ld.bu	%d15, [%a2]
0x09,0xd0,0x45,0x28 = ld.bu	%d0, [%a13]133
0x89,0xdf,0x05,0x28 = st.b	[%a13]133, %d15
0x09,0xff,0x59,0x08 = ld.bu	%d15, [%a15]25
0x09,0xdf,0x64,0x28 = ld.bu	%d15, [%a13]164
0x89,0xdf,0x24,0x28 = st.b	[%a13]164, %d15
0x09,0xf0,0x57,0x08 = ld.bu	%d0, [%a15]23
0x09,0xd1,0x20,0x29 = ld.w	%d1, [%a13]160
0x89,0xd1,0x20,0x29 = st.w	[%a13]160, %d1
0x09,0xff,0x56,0x08 = ld.bu	%d15, [%a15]22
0x09,0xf0,0x58,0x08 = ld.bu	%d0, [%a15]24
0x09,0xd0,0x64,0x28 = ld.bu	%d0, [%a13]164
0x09,0xff,0x69,0x08 = ld.bu	%d15, [%a15]41
0x39,0xcf,0x04,0x80 = ld.bu	%d15, [%a12]516
0xe9,0xcf,0x04,0x80 = st.b	[%a12]516, %d15
0x09,0xf0,0x67,0x08 = ld.bu	%d0, [%a15]39
0x19,0xc1,0x00,0x80 = ld.w	%d1, [%a12]512
0x59,0xc1,0x00,0x80 = st.w	[%a12]512, %d1
0x09,0xff,0x66,0x08 = ld.bu	%d15, [%a15]38
0x09,0xf0,0x68,0x08 = ld.bu	%d0, [%a15]40
0x39,0xc0,0x04,0x80 = ld.bu	%d0, [%a12]516
0x09,0xf5,0x6c,0x08 = ld.bu	%d5, [%a15]44
0x09,0x20,0x4a,0x08 = ld.bu	%d0, [%a2]10
0x09,0x4f,0x61,0x08 = ld.bu	%d15, [%a4]33
0x89,0x2f,0x21,0x08 = st.b	[%a2]33, %d15
0x09,0x2f,0x06,0x09 = ld.w	%d15, [%a2]6
0x09,0x4f,0x60,0x08 = ld.bu	%d15, [%a4]32
0x89,0x2f,0x20,0x08 = st.b	[%a2]32, %d15
0x2c,0x44           = st.b	[%a4]4, %d15
0xf4,0x45           = st.a	[%a4], %a5
0x0c,0x44           = ld.bu	%d15, [%a4]4
0x2c,0x45           = st.b	[%a4]5, %d15
0x89,0x4f,0x2c,0x08 = st.b	[%a4]44, %d15
0xd4,0xcd           = ld.a	%a13, [%a12]
0xf4,0x4d           = st.a	[%a4], %a13
0x74,0xd0           = st.w	[%a13], %d0
0x09,0xc4,0x5d,0x08 = ld.bu	%d4, [%a12]29
0x4c,0xc5           = ld.w	%d15, [%a12]20
0x4c,0xc4           = ld.w	%d15, [%a12]16
0x09,0xff,0x61,0x28 = ld.bu	%d15, [%a15]161
0x89,0x2f,0x21,0x28 = st.b	[%a2]161, %d15
0x48,0x1f           = ld.w	%d15, [%a15]4
0x09,0x2f,0x60,0x28 = ld.bu	%d15, [%a2]160
0x89,0xff,0x20,0x28 = st.b	[%a15]160, %d15
0x09,0xcf,0x5c,0x08 = ld.bu	%d15, [%a12]28
0x34,0xff           = st.b	[%a15], %d15
0xf4,0xf5           = st.a	[%a15], %a5
0x6c,0xf5           = st.w	[%a15]20, %d15
0x68,0x42           = st.w	[%a15]16, %d2
0x68,0x62           = st.w	[%a15]24, %d2
0x2c,0xf8           = st.b	[%a15]8, %d15
0x6c,0xf1           = st.w	[%a15]4, %d15
0x2c,0xfe           = st.b	[%a15]14, %d15
0x89,0xff,0x0a,0x09 = st.w	[%a15]10, %d15
0x89,0xff,0x1c,0x08 = st.b	[%a15]28, %d15
0x89,0xff,0x1d,0x08 = st.b	[%a15]29, %d15
0x39,0xff,0x37,0x06 = ld.bu	%d15, [%a15]24631
0x09,0xff,0x54,0x08 = ld.bu	%d15, [%a15]20
0x09,0xff,0x5c,0x08 = ld.bu	%d15, [%a15]28
0x09,0xff,0x5b,0x08 = ld.bu	%d15, [%a15]27
0x39,0xff,0x33,0x06 = ld.bu	%d15, [%a15]24627
0x39,0xff,0x31,0x06 = ld.bu	%d15, [%a15]24625
0x39,0xff,0x32,0x06 = ld.bu	%d15, [%a15]24626
0x09,0xff,0x10,0x19 = ld.w	%d15, [%a15]80
0x74,0x2f           = st.w	[%a2], %d15
0x39,0x2f,0x30,0x46 = ld.bu	%d15, [%a2]24880
0xe9,0x2f,0x30,0x46 = st.b	[%a2]24880, %d15
0x39,0x2f,0x33,0x06 = ld.bu	%d15, [%a2]24627
0xe9,0x2f,0x33,0x06 = st.b	[%a2]24627, %d15
0x39,0x2f,0x18,0x06 = ld.bu	%d15, [%a2]24600
0xe9,0x2f,0x18,0x06 = st.b	[%a2]24600, %d15
0x39,0x2f,0x37,0x06 = ld.bu	%d15, [%a2]24631
0xe9,0x2f,0x37,0x06 = st.b	[%a2]24631, %d15
0x39,0x2f,0x14,0x06 = ld.bu	%d15, [%a2]24596
0x39,0x20,0x1c,0x06 = ld.bu	%d0, [%a2]24604
0x08,0xaf           = ld.bu	%d15, [%a15]10
0xe9,0x2f,0x1c,0x06 = st.b	[%a2]24604, %d15
0x39,0x20,0x1b,0x06 = ld.bu	%d0, [%a2]24603
0x08,0x8f           = ld.bu	%d15, [%a15]8
0xe9,0x2f,0x1b,0x06 = st.b	[%a2]24603, %d15
0x39,0x20,0x19,0x06 = ld.bu	%d0, [%a2]24601
0x08,0x9f           = ld.bu	%d15, [%a15]9
0xe9,0x2f,0x19,0x06 = st.b	[%a2]24601, %d15
0x39,0x2f,0x1a,0x06 = ld.bu	%d15, [%a2]24602
0xe9,0x2f,0x1a,0x06 = st.b	[%a2]24602, %d15
0x48,0x34           = ld.w	%d4, [%a15]12
0x19,0x20,0x30,0x06 = ld.w	%d0, [%a2]24624
0x48,0x5f           = ld.w	%d15, [%a15]20
0x48,0x41           = ld.w	%d1, [%a15]16
0x74,0x20           = st.w	[%a2], %d0
0x19,0x20,0x34,0x06 = ld.w	%d0, [%a2]24628
0x48,0x7f           = ld.w	%d15, [%a15]28
0x48,0x61           = ld.w	%d1, [%a15]24
0x39,0x2f,0x03,0x16 = ld.bu	%d15, [%a2]24643
0x19,0x20,0x00,0x16 = ld.w	%d0, [%a2]24640
0x48,0x9f           = ld.w	%d15, [%a15]36
0x48,0x81           = ld.w	%d1, [%a15]32
0x39,0x2f,0x0f,0x16 = ld.bu	%d15, [%a2]24655
0x19,0x20,0x0c,0x16 = ld.w	%d0, [%a2]24652
0x48,0xbf           = ld.w	%d15, [%a15]44
0x48,0xa1           = ld.w	%d1, [%a15]40
0x19,0x20,0x00,0x26 = ld.w	%d0, [%a2]24704
0x48,0xdf           = ld.w	%d15, [%a15]52
0x48,0xc1           = ld.w	%d1, [%a15]48
0x19,0x20,0x04,0x26 = ld.w	%d0, [%a2]24708
0x48,0xff           = ld.w	%d15, [%a15]60
0x48,0xe1           = ld.w	%d1, [%a15]56
0x19,0x2f,0x08,0x26 = ld.w	%d15, [%a2]24712
0x09,0xf0,0x04,0x19 = ld.w	%d0, [%a15]68
0x09,0xf1,0x00,0x19 = ld.w	%d1, [%a15]64
0x19,0x2f,0x14,0x02 = ld.w	%d15, [%a2]8212
0x09,0xf0,0x0c,0x19 = ld.w	%d0, [%a15]76
0x09,0xf1,0x08,0x19 = ld.w	%d1, [%a15]72
0xc8,0x12           = ld.a	%a2, [%a15]4
0x4c,0x22           = ld.w	%d15, [%a2]8
0x09,0x22,0x88,0x09 = ld.a	%a2, [%a2]8
0x09,0x24,0x02,0x09 = ld.w	%d4, [%a2]2
0x14,0xff           = ld.bu	%d15, [%a15]
0x39,0xff,0x18,0x06 = ld.bu	%d15, [%a15]24600
0xe9,0xff,0x18,0x06 = st.b	[%a15]24600, %d15
0x39,0xff,0x2c,0x46 = ld.bu	%d15, [%a15]24876
0xe9,0xff,0x2c,0x46 = st.b	[%a15]24876, %d15
0x39,0xff,0x30,0x46 = ld.bu	%d15, [%a15]24880
0xe9,0xff,0x30,0x46 = st.b	[%a15]24880, %d15
0x39,0xf0,0x10,0x06 = ld.bu	%d0, [%a15]24592
0xe9,0xf0,0x10,0x06 = st.b	[%a15]24592, %d0
0x39,0xf0,0x12,0x06 = ld.bu	%d0, [%a15]24594
0x54,0xf1           = ld.w	%d1, [%a15]
0xe9,0xff,0x12,0x06 = st.b	[%a15]24594, %d15
0x39,0xff,0x10,0x06 = ld.bu	%d15, [%a15]24592
0xe9,0xff,0x10,0x06 = st.b	[%a15]24592, %d15
0x39,0xff,0x11,0x06 = ld.bu	%d15, [%a15]24593
0x39,0xff,0x35,0x06 = ld.bu	%d15, [%a15]24629
0x85,0xf1,0x10,0x00 = ld.w	%d1, 0xf0000010
0x85,0xf0,0x10,0x00 = ld.w	%d0, 0xf0000010
0x54,0xf0           = ld.w	%d0, [%a15]
0x74,0xff           = st.w	[%a15], %d15
0x19,0xff,0x30,0x36 = ld.w	%d15, [%a15]24816
0x19,0xf0,0x30,0x36 = ld.w	%d0, [%a15]24816
0x59,0xff,0x30,0x36 = st.w	[%a15]24816, %d15
0x2c,0xf4           = st.b	[%a15]4, %d15
0x39,0xff,0x34,0x36 = ld.bu	%d15, [%a15]24820
0xe9,0xff,0x34,0x36 = st.b	[%a15]24820, %d15
0x89,0xa2,0x40,0x09 = st.d	[%sp]0, %e2
0x09,0xa0,0x40,0x09 = ld.d	%e0, [%sp]0
0x54,0x31           = ld.w	%d1, [%a3]
0x08,0x1f           = ld.bu	%d15, [%a15]1
0xd4,0xff           = ld.a	%a15, [%a15]
0x54,0x3f           = ld.w	%d15, [%a3]
0x74,0x3f           = st.w	[%a3], %d15
0x39,0x2f,0x35,0x06 = ld.bu	%d15, [%a2]24629
0x85,0xff,0x10,0x00 = ld.w	%d15, 0xf0000010
0x49,0x40,0x40,0x08 = ldmst	[%a4]0, %e0
0x74,0xf0           = st.w	[%a15], %d0
0x74,0x41           = st.w	[%a4], %d1
0x74,0x4f           = st.w	[%a4], %d15
0x15,0xd0,0xc0,0xe3 = stlcx	0xd0003f80
0x15,0xd0,0xc0,0xf7 = stucx	0xd0003fc0
0x85,0xdf,0xc4,0xf3 = ld.w	%d15, 0xd0003fc4
0x15,0xd0,0xc0,0xff = lducx	0xd0003fc0
0x15,0xd0,0xc0,0xeb = ldlcx	0xd0003f80
0x39,0xff,0x05,0x80 = ld.bu	%d15, [%a15]517
0xe9,0xff,0x05,0x80 = st.b	[%a15]517, %d15
0x2c,0xa4           = st.b	[%sp]4, %d15
0x2c,0xa5           = st.b	[%sp]5, %d15
0x89,0xaf,0x31,0x08 = st.b	[%sp]49, %d15
0x89,0xaf,0x24,0x08 = st.b	[%sp]36, %d15
0x89,0xaf,0x28,0x08 = st.b	[%sp]40, %d15
0x09,0x2f,0x00,0x08 = ld.b	%d15, [%a2]0
0x2c,0xfc           = st.b	[%a15]12, %d15
0x28,0xf8           = st.b	[%a15]15, %d8
0x2c,0xf2           = st.b	[%a15]2, %d15
0x08,0x81           = ld.bu	%d1, [%a15]8
0x09,0xff,0x00,0x69 = ld.w	%d15, [%a15]384
0x89,0xf0,0x00,0x69 = st.w	[%a15]384, %d0
0x09,0x22,0x84,0x09 = ld.a	%a2, [%a2]4
0x19,0xff,0x00,0xa0 = ld.w	%d15, [%a15]640
0xb4,0xaf           = st.h	[%sp], %d15
0xac,0xa1           = st.h	[%sp]2, %d15
0xac,0xa2           = st.h	[%sp]4, %d15
0xac,0xa3           = st.h	[%sp]6, %d15
0xb4,0xa2           = st.h	[%sp], %d2
0x89,0xa2,0x82,0x08 = st.h	[%sp]2, %d2
0x89,0xa2,0x84,0x08 = st.h	[%sp]4, %d2
0x89,0xa2,0x86,0x08 = st.h	[%sp]6, %d2
0x54,0x2f           = ld.w	%d15, [%a2]
0x09,0x51,0x01,0x00 = ld.b	%d1, [%a5+]1
0x54,0x22           = ld.w	%d2, [%a2]
0x74,0x22           = st.w	[%a2], %d2
0xc8,0x1c           = ld.a	%a12, [%a15]4
0xc8,0x2d           = ld.a	%a13, [%a15]8
0x48,0x3c           = ld.w	%d12, [%a15]12
0x09,0xff,0x10,0x01 = ld.w	%d15, [%a15+]16
0x04,0xdf           = ld.bu	%d15, [%a13+]
0x24,0xcf           = st.b	[%a12+], %d15
0x44,0x21           = ld.w	%d1, [%a2+]
0x64,0xc1           = st.w	[%a12+], %d1
0x24,0xc9           = st.b	[%a12+], %d9
0x64,0xca           = st.w	[%a12+], %d10
0x24,0xcb           = st.b	[%a12+], %d11
0x64,0xc8           = st.w	[%a12+], %d8
