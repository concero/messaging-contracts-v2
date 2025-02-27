const MASKS = {
	UINT24: 0xffffffn, // Mask for uint24 (24 bits)
	UINT16: 0xffffn, // Mask for uint16 (16 bits)
	UINT8: 0xffn, // Mask for uint8 (8 bits)
	BOOL: 0x1n, // Mask for 1 bit (bool)
	UPPER_BYTE: 0xff00,
	LOWER_BYTE: 0xff,
	UPPER_BYTE_SHIFT: 8,
};

export { MASKS };
